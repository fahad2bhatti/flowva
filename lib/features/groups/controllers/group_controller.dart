import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../data/models/group_model.dart';

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

    return group;
  }

  // ─── Get User Groups (Stream) ─────────────────────────────────────────────

  Stream<List<GroupModel>> getUserGroups() {
    final user = _currentUser;

    // ✅ Simple approach: ownerId se query — no index required
    return _firestore
        .collection('groups')
        .where('ownerId', isEqualTo: user.uid)
        .snapshots()
        .asyncMap((snap) async {
      final results = snap.docs
          .map((doc) => GroupModel.fromFirestore(doc))
          .toList();
      results.sort((a, b) => b.lastActive.compareTo(a.lastActive));
      return results;
    });
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