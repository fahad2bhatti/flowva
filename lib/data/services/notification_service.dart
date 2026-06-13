import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Background message handler — top level function (required by FCM)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message silently
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─────────────────────────────────────────────
  // Initialize
  // ─────────────────────────────────────────────

  Future<void> initialize() async {
    // Set background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission
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
      // App is open — handle notification display here
      // Can integrate flutter_local_notifications if needed
    });
  }

  // ─────────────────────────────────────────────
  // App Opened From Notification
  // ─────────────────────────────────────────────

  void _handleMessageOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationNavigation(message.data);
    });
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    // Navigation logic based on notification type
    // Will be connected to GoRouter in a later phase
    final type = data['type'] as String?;
    switch (type) {
      case 'new_message':
      // Navigate to chat
        break;
      case 'task_assigned':
      // Navigate to task
        break;
      case 'mention':
      // Navigate to feed
        break;
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

  Future<void> createNotification({
    required String recipientUid,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? actionData,
  }) async {
    await _firestore
        .collection('notifications')
        .doc(recipientUid)
        .collection('items')
        .add({
      'type': type,
      'title': title,
      'body': body,
      'isRead': false,
      'actionData': actionData ?? {},
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}