import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Background message handler — top level (FCM requirement)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle silently — Firebase already initialized via main()
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth     _auth      = FirebaseAuth.instance;

  /// ✅ FIX: GoRouter navigatorKey inject karo — navigation ab kaam karega
  /// Usage: NotificationService.instance.setNavigatorKey(navigatorKey);
  /// Call this in main.dart after GoRouter setup.
  GlobalKey<NavigatorState>? _navigatorKey;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  // ─────────────────────────────────────────────
  // Initialize
  // ─────────────────────────────────────────────

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await _saveToken();
      _listenTokenRefresh();
      _handleForegroundMessages();
      _handleMessageOpenedApp();

      // ✅ App terminated state — notification tap se app open hoi
      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        // Slight delay — router initialize hone ka wait
        await Future.delayed(const Duration(milliseconds: 500));
        _handleNotificationNavigation(initial.data);
      }
    }
  }

  // ─────────────────────────────────────────────
  // Save FCM Token
  // ─────────────────────────────────────────────

  Future<void> _saveToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final token = await _messaging.getToken();
    if (token == null) return;
    await _firestore.collection('users').doc(uid).update({
      'fcmToken': token,
    });
  }

  Future<void> saveFcmToken(String uid) async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await _firestore.collection('users').doc(uid).update({
      'fcmToken': token,
    });
  }

  // ─────────────────────────────────────────────
  // Token Refresh
  // ─────────────────────────────────────────────

  void _listenTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) async {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      await _firestore.collection('users').doc(uid).update({
        'fcmToken': newToken,
      });
    });
  }

  // ─────────────────────────────────────────────
  // Foreground Messages
  // ─────────────────────────────────────────────

  void _handleForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // App open hai — in-app notification show karo
      _showInAppBanner(message);
    });
  }

  void _showInAppBanner(RemoteMessage message) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    final notification = message.notification;
    if (notification == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              notification.title ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (notification.body != null)
              Text(
                notification.body!,
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _handleNotificationNavigation(message.data),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // App Opened From Notification
  // ─────────────────────────────────────────────

  void _handleMessageOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationNavigation(message.data);
    });
  }

  // ✅ FIX: GoRouter navigation fully implemented
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    final type    = data['type']    as String?;
    final groupId = data['groupId'] as String?;
    final taskId  = data['taskId']  as String?;
    final postId  = data['postId']  as String?;

    switch (type) {
      case 'new_message':
        if (groupId != null) {
          context.push('/chat/$groupId/general');
        }
        break;

      case 'task_assigned':
        if (groupId != null && taskId != null) {
          context.push('/groups/$groupId/tasks/$taskId');
        } else if (groupId != null) {
          context.push('/groups/$groupId');
        }
        break;

      case 'mention':
        if (groupId != null && postId != null) {
          context.push('/groups/$groupId/feed/$postId');
        } else if (groupId != null) {
          context.push('/groups/$groupId/feed');
        }
        break;

      case 'group_invite':
        if (groupId != null) {
          context.push('/groups/$groupId');
        }
        break;

      case 'post_reaction':
      case 'post_comment':
        if (groupId != null && postId != null) {
          context.push('/groups/$groupId/feed/$postId');
        }
        break;

      default:
      // Unknown type — home pe jao
        context.go('/home');
    }
  }

  // ─────────────────────────────────────────────
  // Group Topic Subscribe/Unsubscribe
  // ─────────────────────────────────────────────

  Future<void> subscribeToGroup(String groupId) async {
    await _messaging.subscribeToTopic('group_$groupId');
  }

  Future<void> unsubscribeFromGroup(String groupId) async {
    await _messaging.unsubscribeFromTopic('group_$groupId');
  }

  // ─────────────────────────────────────────────
  // Create Notification in Firestore
  // ─────────────────────────────────────────────

  /// ✅ FIX: senderId + senderName added — NotificationModel expects these
  Future<void> createNotification({
    required String recipientUid,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? actionData,
    String? senderId,    // ✅ added
    String? senderName,  // ✅ added
  }) async {
    // Auto-fill sender from current user if not passed
    final currentUser = _auth.currentUser;
    final resolvedSenderId   = senderId   ?? currentUser?.uid   ?? '';
    final resolvedSenderName = senderName ?? currentUser?.displayName ?? 'Someone';

    await _firestore
        .collection('notifications')
        .doc(recipientUid)
        .collection('items')
        .add({
      'type'      : type,
      'title'     : title,
      'body'      : body,
      'isRead'    : false,
      'actionData': actionData ?? {},
      'senderId'  : resolvedSenderId,    // ✅ added
      'senderName': resolvedSenderName,  // ✅ added
      'timestamp' : FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────
  // Mark Notification Read
  // ─────────────────────────────────────────────

  Future<void> markAsRead(String notificationId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllRead() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final snap = await _firestore
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ─────────────────────────────────────────────
  // Get Notifications Stream
  // ─────────────────────────────────────────────

  Stream<QuerySnapshot> getNotificationsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .orderBy('timestamp', descending: true)
        .limit(30)
        .snapshots();
  }

  // Unread count stream — badge ke liye
  Stream<int> getUnreadCount() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.size);
  }
}