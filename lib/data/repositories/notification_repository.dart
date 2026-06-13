import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationRepository {
  static final NotificationRepository instance =
  NotificationRepository._internal();
  NotificationRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // ─────────────────────────────────────────────
  // Get Notifications Stream
  // ─────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getNotifications() {
    return _firestore
        .collection('notifications')
        .doc(_uid)
        .collection('items')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList());
  }

  // ─────────────────────────────────────────────
  // Mark As Read
  // ─────────────────────────────────────────────

  Future<void> markAsRead(String notifId) async {
    await _firestore
        .collection('notifications')
        .doc(_uid)
        .collection('items')
        .doc(notifId)
        .update({'isRead': true});
  }

  // ─────────────────────────────────────────────
  // Mark All As Read
  // ─────────────────────────────────────────────

  Future<void> markAllAsRead() async {
    final batch = _firestore.batch();
    final unread = await _firestore
        .collection('notifications')
        .doc(_uid)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ─────────────────────────────────────────────
  // Delete Notification
  // ─────────────────────────────────────────────

  Future<void> deleteNotification(String notifId) async {
    await _firestore
        .collection('notifications')
        .doc(_uid)
        .collection('items')
        .doc(notifId)
        .delete();
  }

  // ─────────────────────────────────────────────
  // Unread Count Stream
  // ─────────────────────────────────────────────

  Stream<int> getUnreadCount() {
    return _firestore
        .collection('notifications')
        .doc(_uid)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}