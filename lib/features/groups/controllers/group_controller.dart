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

  // ─── Helpers ────────────────────────────────────────────────────────────────

  User get _currentUser {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated.');
    return user;
  }

  /// Generate a random 6-character alphanumeric invite code (uppercase).
  String generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  // ─── Create Group ────────────────────────────────────────────────────────────

  /// Creates a new group document and adds the creator as an owner member.
  /// Returns the newly created [GroupModel].
  Future<GroupModel> createGroup({
    required String name,
    required String description,
    required String color,
  }) async {
    final user = _currentUser;
    final inviteCode = generateInviteCode();
    final now = Timestamp.now();

    // Build the group document data
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

    // Create the group document
    final docRef = await _firestore.collection('groups').add(groupData);

    // Add creator as owner in the members subcollection
    await docRef.collection('members').doc(user.uid).set({
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

  /// Joins an existing group by [inviteCode].
  /// Returns the [GroupModel] for the joined group.
  Future<GroupModel> joinGroup(String inviteCode) async {
    final user = _currentUser;
    final code = inviteCode.trim().toUpperCase();

    // Find the group with this invite code
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

    // Check if already a member
    final memberDoc = await groupDoc.reference
        .collection('members')
        .doc(user.uid)
        .get();

    if (memberDoc.exists) {
      throw Exception('You are already a member of this group.');
    }

    final now = Timestamp.now();

    // Add user as member
    await groupDoc.reference.collection('members').doc(user.uid).set({
      'role': 'member',
      'joinedAt': now,
      'displayName': user.displayName ?? 'Unknown',
      'photoUrl': user.photoURL ?? '',
    });

    // Increment member count
    await groupDoc.reference.update({
      'memberCount': FieldValue.increment(1),
      'lastActive': now,
    });

    return group;
  }

  // ─── Get User Groups (Stream) ─────────────────────────────────────────────

  /// Returns a real-time stream of all groups the current user belongs to.
  Stream<List<GroupModel>> getUserGroups() {
    final user = _currentUser;

    // We fetch all groups and filter by membership via collectionGroup.
    // For simplicity, we query groups where ownerId == user OR memberCount > 0
    // and cross-check. Best approach: maintain a "groupIds" array on user doc
    // OR use a collectionGroup query on "members".
    return _firestore
        .collectionGroup('members')
        .where(FieldPath.documentId, isEqualTo: user.uid)
        .snapshots()
        .asyncMap((memberSnap) async {
      if (memberSnap.docs.isEmpty) return <GroupModel>[];

      final groupFutures = memberSnap.docs.map((memberDoc) async {
        // Parent path of the member doc is the group doc
        final groupRef = memberDoc.reference.parent.parent;
        if (groupRef == null) return null;
        final groupDoc = await groupRef.get();
        if (!groupDoc.exists) return null;
        return GroupModel.fromFirestore(groupDoc);
      });

      final results = await Future.wait(groupFutures);
      return results.whereType<GroupModel>().toList()
        ..sort((a, b) => b.lastActive.compareTo(a.lastActive));
    });
  }

  // ─── Delete Group ─────────────────────────────────────────────────────────

  /// Deletes a group. Only the owner can delete.
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
