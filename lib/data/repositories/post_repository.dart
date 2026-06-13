import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';

class PostRepository {
  static final PostRepository instance = PostRepository._internal();
  PostRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // ─────────────────────────────────────────────
  // Create Post
  // ─────────────────────────────────────────────

  Future<bool> createPost({
    required String groupId,
    required String content,
    List<String> attachments = const [],
  }) async {
    try {
      final user = _auth.currentUser;
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('posts')
          .add({
        'authorId': _uid,
        'authorName': user?.displayName ?? 'User',
        'content': content,
        'attachments': attachments,
        'likes': [],
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Get Posts Stream
  // ─────────────────────────────────────────────

  Stream<List<PostModel>> getPosts(String groupId,
      {DocumentSnapshot? lastDoc}) {
    var query = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(20);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    return query.snapshots().map((snap) =>
        snap.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }

  // ─────────────────────────────────────────────
  // Toggle Like
  // ─────────────────────────────────────────────

  Future<bool> toggleLike(String groupId, String postId) async {
    try {
      final ref = _firestore
          .collection('groups')
          .doc(groupId)
          .collection('posts')
          .doc(postId);

      final doc = await ref.get();
      final likes = List<String>.from(doc.data()?['likes'] ?? []);

      if (likes.contains(_uid)) {
        await ref.update({'likes': FieldValue.arrayRemove([_uid])});
      } else {
        await ref.update({'likes': FieldValue.arrayUnion([_uid])});
      }
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
      final user = _auth.currentUser;
      final batch = _firestore.batch();

      final commentRef = _firestore
          .collection('groups')
          .doc(groupId)
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc();

      batch.set(commentRef, {
        'authorId': _uid,
        'authorName': user?.displayName ?? 'User',
        'content': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.update(
        _firestore
            .collection('groups')
            .doc(groupId)
            .collection('posts')
            .doc(postId),
        {'commentCount': FieldValue.increment(1)},
      );

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
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('posts')
          .doc(postId)
          .delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}