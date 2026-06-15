import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  newMessage,
  taskAssigned,
  mention,
  groupInvite,
  taskCompleted,
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String senderId;
  final String senderName;
  final String? senderPhoto;
  final bool isRead;
  final Timestamp timestamp;
  final Map<String, dynamic> actionData;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.senderId,
    required this.senderName,
    this.senderPhoto,
    required this.isRead,
    required this.timestamp,
    required this.actionData,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      type: _typeFromString(map['type'] ?? ''),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Unknown',
      senderPhoto: map['senderPhoto'],
      isRead: map['isRead'] ?? false,
      timestamp: map['timestamp'] as Timestamp? ?? Timestamp.now(),
      actionData: Map<String, dynamic>.from(map['actionData'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': _typeToString(type),
      'title': title,
      'body': body,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhoto': senderPhoto,
      'isRead': isRead,
      'timestamp': timestamp,
      'actionData': actionData,
    };
  }

  static NotificationType _typeFromString(String type) {
    return switch (type) {
      'new_message'    => NotificationType.newMessage,
      'task_assigned'  => NotificationType.taskAssigned,
      'mention'        => NotificationType.mention,
      'group_invite'   => NotificationType.groupInvite,
      'task_completed' => NotificationType.taskCompleted,
      _                => NotificationType.newMessage,
    };
  }

  static String _typeToString(NotificationType type) {
    return switch (type) {
      NotificationType.newMessage    => 'new_message',
      NotificationType.taskAssigned  => 'task_assigned',
      NotificationType.mention       => 'mention',
      NotificationType.groupInvite   => 'group_invite',
      NotificationType.taskCompleted => 'task_completed',
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(timestamp.toDate());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.toDate().day}/${timestamp.toDate().month}';
  }
}