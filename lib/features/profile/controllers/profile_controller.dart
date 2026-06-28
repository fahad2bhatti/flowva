import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/user_model.dart';

class ProfileController {
  static final ProfileController _instance = ProfileController._internal();
  static ProfileController get instance => _instance;
  ProfileController._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // ─────────────────────────────────────────────
  // Get Current User Profile (Stream)
  // ─────────────────────────────────────────────

  Stream<UserModel?> getCurrentUserStream() {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) =>
    doc.exists ? UserModel.fromMap(doc.data()!, doc.id) : null);
  }

  // ─────────────────────────────────────────────
  // Get Any User Profile
  // ─────────────────────────────────────────────

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Stream<UserModel?> getUserStreamById(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) =>
    doc.exists ? UserModel.fromMap(doc.data()!, doc.id) : null);
  }

  // ─────────────────────────────────────────────
  // Update Profile
  // ─────────────────────────────────────────────

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not logged in');

    final existing = await getUserById(uid);
    if (existing != null) {
      final updated = existing.copyWith(
        name           : data['name']            ?? existing.name,
        username       : data['username']         ?? existing.username,
        bio            : data['bio']              ?? existing.bio,
        jobRole        : data['jobRole']          ?? existing.jobRole,
        experienceLevel: data['experienceLevel']  ?? existing.experienceLevel,
        skills         : data['skills'] != null
            ? List<String>.from(data['skills'])
            : existing.skills,
        interests      : data['interests'] != null
            ? List<String>.from(data['interests'])
            : existing.interests,
        currentStatus  : data['currentStatus']   ?? existing.currentStatus,
        photoUrl       : data['photoUrl']         ?? existing.photoUrl,
        coverPhotoUrl  : data['coverPhotoUrl']    ?? existing.coverPhotoUrl,
      );
      data['profileCompletion'] = updated.calculateCompletion();
    }

    data['updatedAt']  = FieldValue.serverTimestamp();
    data['lastActive'] = FieldValue.serverTimestamp();

    await _firestore.collection('users').doc(uid).update(data);
  }

  // ─────────────────────────────────────────────
  // Follow / Unfollow  ✅ Fixed: counts bhi update
  // ─────────────────────────────────────────────

  Future<void> toggleFollow(String targetUid) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not logged in');
    if (uid == targetUid) return;

    final myRef     = _firestore.collection('users').doc(uid);
    final targetRef = _firestore.collection('users').doc(targetUid);

    final myDoc     = await myRef.get();
    final following = List<String>.from(myDoc.data()?['following'] ?? []);
    final isFollowing = following.contains(targetUid);

    final batch = _firestore.batch();

    if (isFollowing) {
      batch.update(myRef, {
        'following'      : FieldValue.arrayRemove([targetUid]),
        'followingCount' : FieldValue.increment(-1),        // ✅ fix
      });
      batch.update(targetRef, {
        'followers'     : FieldValue.arrayRemove([uid]),
        'followerCount' : FieldValue.increment(-1),         // ✅ fix
      });
    } else {
      batch.update(myRef, {
        'following'      : FieldValue.arrayUnion([targetUid]),
        'followingCount' : FieldValue.increment(1),         // ✅ fix
      });
      batch.update(targetRef, {
        'followers'     : FieldValue.arrayUnion([uid]),
        'followerCount' : FieldValue.increment(1),          // ✅ fix
      });
    }

    await batch.commit();
  }

  // ─────────────────────────────────────────────
  // Update Online Status
  // ─────────────────────────────────────────────

  Future<void> setOnline(bool isOnline) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({
      'isOnline'   : isOnline,
      'lastActive' : FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────
  // Check Username Availability  ✅ Self-aware
  // ─────────────────────────────────────────────

  Future<bool> isUsernameAvailable(String username) async {
    final uid   = currentUserId;
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase().trim())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return true;
    return query.docs.first.id == uid; // own username = still available
  }
}