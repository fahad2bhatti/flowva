import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';

/// PostRepository — all post CRUD operations.
///
/// ✅ FIX (Manus Report #3):
///   - createPost now writes 'fileUrls' (not 'attachments')
///   - createPost now writes 'reactions: {}' map (not 'likes: []' array)
///   - createPost now writes 'authorRole' and 'groupId'
///   - toggleLike updated to work with reactions map
///   - All writes consistent with PostModel.fromFirestore

class PostRepository {
  static final PostRepository instance = PostRepository._internal();
  PostRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth     _auth      = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> _postsRef(String groupId) =>
      _firestore.collection('groups').doc(groupId).collection('posts');

  // ─────────────────────────────────────────────
  // Create Post
  // ─────────────────────────────────────────────

  Future<bool> createPost({
    required String groupId,
    required String content,
    List<String> fileUrls = const [],   // ✅ was 'attachments'
    String authorRole = 'member',
  }) async {
    try {
      final user = _auth.currentUser;

      // Fetch authorRole from Firestore if not passed
      String role = authorRole;
      if (role == 'member') {
        final userDoc = await _firestore.collection('users').doc(_uid).get();
        role = userDoc.data()?['role']?.toString() ?? 'member';
      }

      await _postsRef(groupId).add({
        'groupId'     : groupId,            // ✅ added — was missing
        'authorId'    : _uid,
        'authorName'  : user?.displayName ?? 'User',
        'authorRole'  : role,               // ✅ added — was missing
        'content'     : content,
        'fileUrls'    : fileUrls,           // ✅ was 'attachments'
        'reactions'   : <String, dynamic>{}, // ✅ was 'likes': []
        'commentCount': 0,
        'createdAt'   : FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Get Posts Stream — paginated
  // ─────────────────────────────────────────────

  Stream<List<PostModel>> getPosts(String groupId,
      {DocumentSnapshot? lastDoc}) {
    var query = _postsRef(groupId)
        .orderBy('createdAt', descending: true)
        .limit(20);

    if (lastDoc != null) query = query.startAfterDocument(lastDoc);

    return query.snapshots().map(
            (snap) => snap.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }

  // ─────────────────────────────────────────────
  // Toggle Reaction (like)
  // ─────────────────────────────────────────────

  Future<bool> toggleLike(String groupId, String postId) async {
    try {
      final ref = _postsRef(groupId).doc(postId);

      await _firestore.runTransaction((txn) async {
        final doc  = await txn.get(ref);
        if (!doc.exists) return;

        // ✅ FIX: reactions map — not likes array
        final raw      = doc.data()?['reactions'] as Map<String, dynamic>? ?? {};
        final likers   = List<String>.from(raw['like'] as List? ?? []);
        final hasLiked = likers.contains(_uid);

        txn.update(ref, {
          'reactions.like': hasLiked
              ? FieldValue.arrayRemove([_uid])
              : FieldValue.arrayUnion([_uid]),
        });
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Toggle Any Reaction (emoji support)
  // ─────────────────────────────────────────────

  Future<bool> toggleReaction(
      String groupId, String postId, String emoji) async {
    try {
      final ref = _postsRef(groupId).doc(postId);

      await _firestore.runTransaction((txn) async {
        final doc    = await txn.get(ref);
        if (!doc.exists) return;

        final raw    = doc.data()?['reactions'] as Map<String, dynamic>? ?? {};
        final users  = List<String>.from(raw[emoji] as List? ?? []);
        final hasIt  = users.contains(_uid);

        txn.update(ref, {
          'reactions.$emoji': hasIt
              ? FieldValue.arrayRemove([_uid])
              : FieldValue.arrayUnion([_uid]),
        });
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Add Comment
  // ─────────────────────────────────────────────

  Future<bool> addComment(
      String groupId, String postId, String comment) async {
    try {
      final user  = _auth.currentUser;
      final batch = _firestore.batch();

      final commentRef = _postsRef(groupId)
          .doc(postId)
          .collection('comments')
          .doc();

      batch.set(commentRef, {
        'authorId'  : _uid,
        'authorName': user?.displayName ?? 'User',
        'content'   : comment,
        'createdAt' : FieldValue.serverTimestamp(),
      });

      batch.update(_postsRef(groupId).doc(postId), {
        'commentCount': FieldValue.increment(1),
      });

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Delete Post
  // ─────────────────────────────────────────────

  Future<bool> deletePost(String groupId, String postId) async {
    try {
      await _postsRef(groupId).doc(postId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}