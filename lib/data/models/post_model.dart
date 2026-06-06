import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String groupId;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String content;
  final List<String> fileUrls;
  final Map<String, List<String>> reactions;
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

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawReactions = data['reactions'] as Map<String, dynamic>? ?? {};
    final reactions = rawReactions.map(
          (key, value) => MapEntry(
        key,
        List<String>.from(value as List? ?? []),
      ),
    );

    return PostModel(
      id: doc.id,
      groupId: data['groupId'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Unknown',
      authorRole: data['authorRole'] as String? ?? 'member',
      content: data['content'] as String? ?? '',
      fileUrls: List<String>.from(data['fileUrls'] as List? ?? []),
      reactions: reactions,
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'content': content,
      'fileUrls': fileUrls,
      'reactions': reactions,
      'commentCount': commentCount,
      'createdAt': createdAt,
    };
  }
}

