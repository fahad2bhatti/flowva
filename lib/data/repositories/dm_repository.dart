import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flowva/data/models/dm_model.dart';

/// DM Repository — all direct message operations
/// SKILL rules:
/// ✅ FieldValue.serverTimestamp() — no DateTime.now()
/// ✅ Paginated queries with .limit(30)
/// ✅ Batch writes for atomic operations
/// ✅ Denormalized sender info in messages

class DmRepository {
  static final DmRepository instance = DmRepository._internal();
  DmRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth     _auth      = FirebaseAuth.instance;

  String get _myUid => _auth.currentUser!.uid;

  // ── DM ID — alphabetical sort ensures same ID for both users ─────────────
  String _dmId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  CollectionReference<Map<String, dynamic>> get _dmsRef =>
      _firestore.collection('dms');

  CollectionReference<Map<String, dynamic>> _messagesRef(String dmId) =>
      _dmsRef.doc(dmId).collection('messages');

  // ─────────────────────────────────────────────
  // Get or Create DM conversation
  // ─────────────────────────────────────────────

  Future<String> getOrCreateDm(String otherUid) async {
    final dmId  = _dmId(_myUid, otherUid);
    final dmDoc = await _dmsRef.doc(dmId).get();

    if (!dmDoc.exists) {
      final myDoc    = await _firestore.collection('users').doc(_myUid).get();
      final otherDoc = await _firestore.collection('users').doc(otherUid).get();

      final myName     = myDoc.data()?['name']?.toString()      ?? 'User';
      final otherName  = otherDoc.data()?['name']?.toString()   ?? 'User';
      final myPhoto    = myDoc.data()?['photoUrl']?.toString()  ?? '';
      final otherPhoto = otherDoc.data()?['photoUrl']?.toString() ?? '';

      await _dmsRef.doc(dmId).set({
        'members'            : [_myUid, otherUid],
        'memberNames'        : {_myUid: myName, otherUid: otherName},
        'memberPhotos'       : {_myUid: myPhoto, otherUid: otherPhoto},
        'lastMessage'        : '',
        'lastMessageSenderId': '',
        'lastMessageAt'      : FieldValue.serverTimestamp(),
        'unreadCount'        : {_myUid: 0, otherUid: 0},
        'createdAt'          : FieldValue.serverTimestamp(),
      });
    }
    return dmId;
  }

  // ─────────────────────────────────────────────
  // Send Message
  // ─────────────────────────────────────────────

  Future<void> sendMessage({
    required String dmId,
    required String content,
    required String otherUid,
    String  type           = 'text',
    String? replyToId,
    String? replyToContent,
  }) async {
    final myDoc  = await _firestore.collection('users').doc(_myUid).get();
    final myName = myDoc.data()?['name']?.toString() ?? 'User';

    final batch  = _firestore.batch();

    final msgRef = _messagesRef(dmId).doc();
    batch.set(msgRef, {
      'senderId'      : _myUid,
      'senderName'    : myName,
      'content'       : content,
      'type'          : type,
      'isRead'        : false,
      'replyToId'     : replyToId,
      'replyToContent': replyToContent,
      'createdAt'     : FieldValue.serverTimestamp(),
    });

    batch.update(_dmsRef.doc(dmId), {
      'lastMessage'           : content,
      'lastMessageSenderId'   : _myUid,
      'lastMessageAt'         : FieldValue.serverTimestamp(),
      'unreadCount.$otherUid' : FieldValue.increment(1),
    });

    await batch.commit();
  }

  // ─────────────────────────────────────────────
  // Get Messages Stream
  // ─────────────────────────────────────────────

  Stream<List<DmMessageModel>> getMessages(String dmId) {
    return _messagesRef(dmId)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => DmMessageModel.fromFirestore(d)).toList());
  }

  // ─────────────────────────────────────────────
  // Get All DM Conversations
  // ─────────────────────────────────────────────

  Stream<List<DmModel>> getMyDms() {
    return _dmsRef
        .where('members', arrayContains: _myUid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => DmModel.fromFirestore(d)).toList());
  }

  // ─────────────────────────────────────────────
  // Mark Messages as Read
  // ─────────────────────────────────────────────

  Future<void> markAsRead(String dmId) async {
    final batch = _firestore.batch();

    batch.update(_dmsRef.doc(dmId), {
      'unreadCount.$_myUid': 0,
    });

    final unread = await _messagesRef(dmId)
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: _myUid)
        .limit(30)
        .get();

    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // ─────────────────────────────────────────────
  // Delete Message (soft)
  // ─────────────────────────────────────────────

  Future<void> deleteMessage(String dmId, String messageId) async {
    await _messagesRef(dmId).doc(messageId).update({
      'content': 'This message was deleted',
      'deleted': true,
    });
  }

  // ─────────────────────────────────────────────
  // Total Unread Count Stream — badge ke liye
  // ─────────────────────────────────────────────

  Stream<int> getTotalUnreadCount() {
    return _dmsRef
        .where('members', arrayContains: _myUid)
        .snapshots()
        .map((snap) {
      int total = 0;
      for (final doc in snap.docs) {
        final counts = doc.data()['unreadCount'] as Map<String, dynamic>? ?? {};
        total += (counts[_myUid] as num?)?.toInt() ?? 0;
      }
      return total;
    });
  }
}