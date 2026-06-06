import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../data/models/group_model.dart';
import '../../../../data/models/user_model.dart';

class GroupController {
  // Singleton
  static final GroupController instance = GroupController._internal();
  GroupController._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User get _currentUser {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated.');
    return user;
  }

  String generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  // ─── Create Group ────────────────────────────────────────────────────────────

  Future<GroupModel> createGroup({
    required String name,
    required String description,
    required String color,
  }) async {
    final user = _currentUser;
    final inviteCode = generateInviteCode();
    final now = Timestamp.now();

    final groupData = {
      'name': name.trim(),
      'description': description.trim(),
      'color': color,
      'ownerId': user.uid,
      'inviteCode': inviteCode,
      'memberCount': 1,
      'createdAt': now,
      'lastActive': now,
    };

    final docRef = await _firestore.collection('groups').add(groupData);

    await docRef.collection('members').doc(user.uid).set({
      'uid': user.uid,
      'role': 'owner',
      'joinedAt': now,
      'displayName': user.displayName ?? 'Unknown',
      'photoUrl': user.photoURL ?? '',
    });

    await _firestore.collection('users').doc(user.uid).set({
      'groupIds': FieldValue.arrayUnion([docRef.id]),
    }, SetOptions(merge: true));

    return GroupModel(
      id: docRef.id,
      name: name.trim(),
      description: description.trim(),
      color: color,
      ownerId: user.uid,
      inviteCode: inviteCode,
      memberCount: 1,
      createdAt: now,
      lastActive: now,
    );
  }

  // ─── Join Group ───────────────────────────────────────────────────────────

  Future<GroupModel> joinGroup(String inviteCode) async {
    final user = _currentUser;
    final code = inviteCode.trim().toUpperCase();

    final query = await _firestore
        .collection('groups')
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Invalid invite code. No group found.');
    }

    final groupDoc = query.docs.first;
    final group = GroupModel.fromFirestore(groupDoc);

    final memberDoc = await groupDoc.reference
        .collection('members')
        .doc(user.uid)
        .get();

    if (memberDoc.exists) {
      throw Exception('You are already a member of this group.');
    }

    final now = Timestamp.now();

    await groupDoc.reference.collection('members').doc(user.uid).set({
      'uid': user.uid,
      'role': 'member',
      'joinedAt': now,
      'displayName': user.displayName ?? 'Unknown',
      'photoUrl': user.photoURL ?? '',
    });

    await groupDoc.reference.update({
      'memberCount': FieldValue.increment(1),
      'lastActive': now,
    });
    await _firestore.collection('users').doc(user.uid).set({
      'groupIds': FieldValue.arrayUnion([groupDoc.id]),
    }, SetOptions(merge: true));

    return group;
  }

  // ─── Get User Groups (Stream) ─────────────────────────────────────────────

  Stream<List<GroupModel>> getUserGroups() {
    final user = _currentUser;

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .asyncMap((userDoc) async {
      // Owner groups
      final ownerSnap = await _firestore
          .collection('groups')
          .where('ownerId', isEqualTo: user.uid)
          .get();

      // Joined groups
      final groupIds = List<String>.from(
        userDoc.data()?['groupIds'] ?? [],
      );

      final joinedFutures = groupIds.map((id) async {
        final doc = await _firestore.collection('groups').doc(id).get();
        if (!doc.exists) return null;
        return GroupModel.fromFirestore(doc);
      });

      final joinedResults = await Future.wait(joinedFutures);

      // Combine aur duplicates hata do
      final allGroups = <String, GroupModel>{};
      for (final g in ownerSnap.docs) {
        allGroups[g.id] = GroupModel.fromFirestore(g);
      }
      for (final g in joinedResults.whereType<GroupModel>()) {
        allGroups[g.id] = g;
      }

      return allGroups.values.toList()
        ..sort((a, b) => b.lastActive.compareTo(a.lastActive));
    });
  }

  // ─── Get Group Members ────────────────────────────────────────────────────
  // 🆕 NAYA METHOD ADDED

  Future<List<UserModel>> getGroupMembers(String groupId) async {
    final membersSnapshot = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .get();

    List<UserModel> members = [];

    for (var doc in membersSnapshot.docs) {
      final userId = doc.id;
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        members.add(UserModel(
          id: userId,
          name: userData['name'] ?? doc.data()['displayName'] ?? 'Unknown',
          email: userData['email'] ?? '',
          photoUrl: userData['photoUrl'] ?? doc.data()['photoUrl'] ?? '',
          role: doc.data()['role'] ?? 'member',
          joinedAt: doc.data()['joinedAt'] ?? Timestamp.now(),
          lastActive: userData['lastActive'] ?? Timestamp.now(), // ← add karo
          createdAt: userData['createdAt'] ?? Timestamp.now(),   // ← add karo
        ));
      }
    }

    return members;
  }

  // ─── Delete Group ─────────────────────────────────────────────────────────

  Future<void> deleteGroup(String groupId) async {
    final user = _currentUser;
    final groupDoc = await _firestore.collection('groups').doc(groupId).get();

    if (!groupDoc.exists) throw Exception('Group not found.');
    final data = groupDoc.data()!;
    if (data['ownerId'] != user.uid) {
      throw Exception('Only the group owner can delete this group.');
    }

    await _firestore.collection('groups').doc(groupId).delete();
  }
}

