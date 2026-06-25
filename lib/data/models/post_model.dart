import 'package:cloud_firestore/cloud_firestore.dart';

/// PostModel — single source of truth for post data schema.
///
/// ✅ FIX (Manus Report #3):
///   - 'fileUrls' field consistent (was 'attachments' in repository)
///   - 'reactions' map consistent (was 'likes' array in repository)
///   - 'authorRole' included
///   - 'groupId' included
///   - copyWith added for optimistic UI updates

class PostModel {
  final String id;
  final String groupId;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String content;
  final List<String> fileUrls;           // ✅ was 'attachments'
  final Map<String, List<String>> reactions; // ✅ was 'likes' List
  final int commentCount;
  final Timestamp createdAt;

  const PostModel({
    required this.id,
    required this.groupId,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.content,
    required this.fileUrls,
    required this.reactions,
    required this.commentCount,
    required this.createdAt,
  });

  // ── Deserialize ─────────────────────────────────────────────────────────
  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // ✅ reactions map — support both old 'likes' array and new 'reactions' map
    Map<String, List<String>> reactions;
    if (data['reactions'] is Map) {
      final raw = data['reactions'] as Map<String, dynamic>;
      reactions = raw.map(
            (key, value) => MapEntry(key, List<String>.from(value as List? ?? [])),
      );
    } else if (data['likes'] is List) {
      // ✅ backward compat: old posts had 'likes' array → convert to reactions map
      reactions = {'like': List<String>.from(data['likes'] as List)};
    } else {
      reactions = {};
    }

    return PostModel(
      id          : doc.id,
      groupId     : data['groupId']     as String?    ?? '',
      authorId    : data['authorId']    as String?    ?? '',
      authorName  : data['authorName']  as String?    ?? 'Unknown',
      authorRole  : data['authorRole']  as String?    ?? 'member',
      content     : data['content']     as String?    ?? '',
      // ✅ support both 'fileUrls' (new) and 'attachments' (old) field names
      fileUrls    : List<String>.from(
          data['fileUrls'] as List? ?? data['attachments'] as List? ?? []),
      reactions   : reactions,
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
      createdAt   : data['createdAt']   as Timestamp? ?? Timestamp.now(),
    );
  }

  // ── Serialize ────────────────────────────────────────────────────────────
  Map<String, dynamic> toFirestore() {
    return {
      'groupId'     : groupId,
      'authorId'    : authorId,
      'authorName'  : authorName,
      'authorRole'  : authorRole,
      'content'     : content,
      'fileUrls'    : fileUrls,      // ✅ consistent field name
      'reactions'   : reactions,     // ✅ consistent field name
      'commentCount': commentCount,
      'createdAt'   : createdAt,
    };
  }

  // ── copyWith — optimistic UI updates ke liye ─────────────────────────────
  PostModel copyWith({
    String? id,
    String? groupId,
    String? authorId,
    String? authorName,
    String? authorRole,
    String? content,
    List<String>? fileUrls,
    Map<String, List<String>>? reactions,
    int? commentCount,
    Timestamp? createdAt,
  }) {
    return PostModel(
      id          : id           ?? this.id,
      groupId     : groupId      ?? this.groupId,
      authorId    : authorId     ?? this.authorId,
      authorName  : authorName   ?? this.authorName,
      authorRole  : authorRole   ?? this.authorRole,
      content     : content      ?? this.content,
      fileUrls    : fileUrls     ?? this.fileUrls,
      reactions   : reactions    ?? this.reactions,
      commentCount: commentCount ?? this.commentCount,
      createdAt   : createdAt    ?? this.createdAt,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  List<String> get likers => reactions['like'] ?? [];
  int get likeCount       => likers.length;
  bool isLikedBy(String uid) => likers.contains(uid);
}