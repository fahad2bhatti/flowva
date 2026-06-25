import 'package:cloud_firestore/cloud_firestore.dart';

/// DM Conversation Model
/// Firestore path: dms/{dmId}
/// dmId = sorted UIDs joined: "uid1_uid2" (alphabetical order)
class DmModel {
  final String id;
  final List<String> members;         // [uid1, uid2]
  final Map<String, String> memberNames;  // {uid: displayName}
  final Map<String, String> memberPhotos; // {uid: photoUrl}
  final String lastMessage;
  final String lastMessageSenderId;
  final Timestamp lastMessageAt;
  final Map<String, int> unreadCount;     // {uid: count}

  const DmModel({
    required this.id,
    required this.members,
    required this.memberNames,
    required this.memberPhotos,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory DmModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DmModel(
      id                  : doc.id,
      members             : List<String>.from(data['members'] ?? []),
      memberNames         : Map<String, String>.from(data['memberNames'] ?? {}),
      memberPhotos        : Map<String, String>.from(data['memberPhotos'] ?? {}),
      lastMessage         : data['lastMessage']         as String? ?? '',
      lastMessageSenderId : data['lastMessageSenderId'] as String? ?? '',
      lastMessageAt       : data['lastMessageAt']       as Timestamp? ?? Timestamp.now(),
      unreadCount         : Map<String, int>.from(
        (data['unreadCount'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
      ),
    );
  }

  // Get other user's name
  String otherUserName(String myUid) {
    final otherId = members.firstWhere((m) => m != myUid, orElse: () => '');
    return memberNames[otherId] ?? 'Unknown';
  }

  // Get other user's photo
  String otherUserPhoto(String myUid) {
    final otherId = members.firstWhere((m) => m != myUid, orElse: () => '');
    return memberPhotos[otherId] ?? '';
  }

  // Get other user's UID
  String otherUserId(String myUid) {
    return members.firstWhere((m) => m != myUid, orElse: () => '');
  }

  int myUnreadCount(String myUid) => unreadCount[myUid] ?? 0;
}

/// DM Message Model
/// Firestore path: dms/{dmId}/messages/{messageId}
class DmMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final String type;        // 'text' | 'image'
  final bool isRead;
  final Timestamp createdAt;
  final String? replyToId;
  final String? replyToContent;

  const DmMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.replyToId,
    this.replyToContent,
  });

  factory DmMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DmMessageModel(
      id             : doc.id,
      senderId       : data['senderId']       as String? ?? '',
      senderName     : data['senderName']     as String? ?? '',
      content        : data['content']        as String? ?? '',
      type           : data['type']           as String? ?? 'text',
      isRead         : data['isRead']         as bool?   ?? false,
      createdAt      : data['createdAt']      as Timestamp? ?? Timestamp.now(),
      replyToId      : data['replyToId']      as String?,
      replyToContent : data['replyToContent'] as String?,
    );
  }

  bool get isMine => false; // override in UI with current uid check
}