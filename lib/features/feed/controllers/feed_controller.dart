import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/post_model.dart';

class FeedController {
  static final FeedController instance = FeedController._internal();
  FeedController._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User get _currentUser {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated.');
    return user;
  }

  // ── Get Posts Stream ────────────────────────────────────────────────────────
  Stream<List<PostModel>> getPosts(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => PostModel.fromFirestore(doc))
        .toList());
  }

  // ── Create Post ─────────────────────────────────────────────────────────────
  Future<void> createPost(String groupId, String content, {List<String>? fileUrls}) async {
    final user = _currentUser;
    final now = Timestamp.now();

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('posts')
        .add({
      'authorId': user.uid,
      'authorName': user.displayName ?? 'Unknown',
      'authorRole': 'member',
      'content': content,
      'fileUrls': fileUrls ?? [],
      'reactions': {},
      'commentCount': 0,
      'createdAt': now,
    });
  }

  // ── Add Reaction ────────────────────────────────────────────────────────────
  Future<void> addReaction(String groupId, String postId, String reaction) async {
    final user = _currentUser;
    final postRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('posts')
        .doc(postId);

    final doc = await postRef.get();
    if (!doc.exists) return;

    final reactions = Map<String, dynamic>.from(
        (doc.data()?['reactions'] as Map?) ?? {});
    final List<dynamic> users = reactions[reaction] ?? [];

    if (users.contains(user.uid)) {
      users.remove(user.uid);
    } else {
      users.add(user.uid);
    }

    reactions[reaction] = users;
    await postRef.update({'reactions': reactions});
  }
}