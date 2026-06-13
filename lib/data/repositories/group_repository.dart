import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';

class GroupRepository {
  static final GroupRepository instance = GroupRepository._internal();
  GroupRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // ─────────────────────────────────────────────
  // Create Group
  // ─────────────────────────────────────────────

  Future<String?> createGroup({
    required String name,
    required String description,
    required String color,
  }) async {
    try {
      final inviteCode = _generateInviteCode();
      final groupRef = _firestore.collection('groups').doc();

      final batch = _firestore.batch();

      batch.set(groupRef, {
        'name': name,
        'description': description,
        'color': color,
        'ownerId': _uid,
        'inviteCode': inviteCode,
        'memberCount': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      });

      batch.set(
        groupRef.collection('members').doc(_uid),
        {
          'role': 'owner',
          'joinedAt': FieldValue.serverTimestamp(),
        },
      );

      await _firestore.collection('users').doc(_uid).update({
        'groupIds': FieldValue.arrayUnion([groupRef.id]),
      });

      await batch.commit();
      return groupRef.id;
    } catch (e) {
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // Join Group
  // ─────────────────────────────────────────────

  Future<bool> joinGroup(String inviteCode) async {
    try {
      final query = await _firestore
          .collection('groups')
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return false;

      final groupDoc = query.docs.first;
      final groupId = groupDoc.id;

      final batch = _firestore.batch();

      batch.set(
        groupDoc.reference.collection('members').doc(_uid),
        {
          'role': 'member',
          'joinedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.update(groupDoc.reference, {
        'memberCount': FieldValue.increment(1),
        'lastActive': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('users').doc(_uid).update({
        'groupIds': FieldValue.arrayUnion([groupId]),
      });

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Leave Group
  // ─────────────────────────────────────────────

  Future<bool> leaveGroup(String groupId) async {
    try {
      final batch = _firestore.batch();

      batch.delete(
        _firestore
            .collection('groups')
            .doc(groupId)
            .collection('members')
            .doc(_uid),
      );

      batch.update(_firestore.collection('groups').doc(groupId), {
        'memberCount': FieldValue.increment(-1),
      });

      await _firestore.collection('users').doc(_uid).update({
        'groupIds': FieldValue.arrayRemove([groupId]),
      });

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Get My Groups
  // ─────────────────────────────────────────────

  Stream<List<GroupModel>> getMyGroups() {
    return _firestore
        .collection('users')
        .doc(_uid)
        .snapshots()
        .asyncMap((userDoc) async {
      final groupIds =
      List<String>.from(userDoc.data()?['groupIds'] ?? []);
      if (groupIds.isEmpty) return [];

      final groups = await Future.wait(
        groupIds.map((id) =>
            _firestore.collection('groups').doc(id).get()),
      );

      return groups
          .where((doc) => doc.exists)
          .map((doc) => GroupModel.fromFirestore(doc))
          .toList();
    });
  }

  // ─────────────────────────────────────────────
  // Get Group Members
  // ─────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getGroupMembers(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .snapshots()
        .asyncMap((snapshot) async {
      final members = await Future.wait(
        snapshot.docs.map((doc) async {
          final userDoc = await _firestore
              .collection('users')
              .doc(doc.id)
              .get();
          if (!userDoc.exists) return null;
          final user = UserModel.fromMap(userDoc.data()!, userDoc.id);
          return {
            'user': user,
            'role': doc.data()['role'] ?? 'member',
          };
        }),
      );
      return members.whereType<Map<String, dynamic>>().toList();
    });
  }

  // ─────────────────────────────────────────────
  // Update Member Role
  // ─────────────────────────────────────────────

  Future<bool> updateMemberRole(
      String groupId, String memberId, String newRole) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .doc(memberId)
          .update({'role': newRole});
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Remove Member
  // ─────────────────────────────────────────────

  Future<bool> removeMember(String groupId, String memberId) async {
    try {
      final batch = _firestore.batch();

      batch.delete(
        _firestore
            .collection('groups')
            .doc(groupId)
            .collection('members')
            .doc(memberId),
      );

      batch.update(_firestore.collection('groups').doc(groupId), {
        'memberCount': FieldValue.increment(-1),
      });

      await _firestore.collection('users').doc(memberId).update({
        'groupIds': FieldValue.arrayRemove([groupId]),
      });

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Update Group
  // ─────────────────────────────────────────────

  Future<bool> updateGroup(GroupModel group) async {
    try {
      await _firestore
          .collection('groups')
          .doc(group.id)
          .update(group.toFirestore());
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Delete Group
  // ─────────────────────────────────────────────

  Future<bool> deleteGroup(String groupId) async {
    try {
      final group = await _firestore
          .collection('groups')
          .doc(groupId)
          .get();

      if (group.data()?['ownerId'] != _uid) return false;

      await _firestore.collection('groups').doc(groupId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Helper
  // ─────────────────────────────────────────────

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = List.generate(6,
            (i) => chars[(DateTime.now().microsecondsSinceEpoch + i) % chars.length]);
    return random.join();
  }
}