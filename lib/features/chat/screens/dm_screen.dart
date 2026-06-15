import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flowva/core/constants/app_colors.dart';

class DMScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;

  const DMScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
  });

  @override
  State<DMScreen> createState() => _DMScreenState();
}

class _DMScreenState extends State<DMScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> _optimisticMessages = [];

  // Reply state
  Map<String, dynamic>? _replyingTo;

  // Typing state
  Timer? _typingTimer;
  StreamSubscription? _typingSubscription;
  bool _otherIsTyping = false;

  // DM conversation ID — always sorted so both users get same doc
  late String _conversationId;

  @override
  void initState() {
    super.initState();
    _conversationId = _getConversationId();
    _listenTyping();
    _controller.addListener(_onTextChanged);
    _markMessagesRead();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _typingSubscription?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    _clearTyping();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Conversation ID
  // ─────────────────────────────────────────────

  String _getConversationId() {
    final myUid = _auth.currentUser!.uid;
    final ids = [myUid, widget.otherUserId]..sort();
    return ids.join('_');
  }

  // ─────────────────────────────────────────────
  // Typing
  // ─────────────────────────────────────────────

  void _onTextChanged() {
    _updateTyping();
  }

  void _updateTyping() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _firestore
        .collection('dm_conversations')
        .doc(_conversationId)
        .collection('typing')
        .doc(uid)
        .set({'timestamp': DateTime.now().millisecondsSinceEpoch});
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), _clearTyping);
  }

  void _clearTyping() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _firestore
        .collection('dm_conversations')
        .doc(_conversationId)
        .collection('typing')
        .doc(uid)
        .delete();
  }

  void _listenTyping() {
    _typingSubscription = _firestore
        .collection('dm_conversations')
        .doc(_conversationId)
        .collection('typing')
        .doc(widget.otherUserId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) {
        if (mounted) setState(() => _otherIsTyping = false);
        return;
      }
      final ts = doc.data()?['timestamp'] as int? ?? 0;
      final isTyping =
          DateTime.now().millisecondsSinceEpoch - ts < 4000;
      if (mounted) setState(() => _otherIsTyping = isTyping);
    });
  }

  // ─────────────────────────────────────────────
  // Mark messages read
  // ─────────────────────────────────────────────

  Future<void> _markMessagesRead() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final unread = await _firestore
        .collection('dm_conversations')
        .doc(_conversationId)
        .collection('messages')
        .where('receiverId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ─────────────────────────────────────────────
  // Send message
  // ─────────────────────────────────────────────

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = _auth.currentUser;
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();

    final optimistic = <String, dynamic>{
      'id': tempId,
      'senderId': user?.uid,
      'senderName': user?.displayName ?? 'User',
      'text': text,
      'isPending': true,
      if (_replyingTo != null) 'replyTo': _replyingTo,
    };

    setState(() {
      _optimisticMessages.add(optimistic);
      _replyingTo = null;
    });

    _controller.clear();
    _clearTyping();
    _scrollToBottom();

    try {
      // Save message
      await _firestore
          .collection('dm_conversations')
          .doc(_conversationId)
          .collection('messages')
          .add({
        'senderId': user?.uid,
        'senderName': user?.displayName ?? 'User',
        'receiverId': widget.otherUserId,
        'text': text,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        if (_replyingTo != null) 'replyTo': _replyingTo,
      });

      // Update conversation metadata for inbox
      await _firestore
          .collection('dm_conversations')
          .doc(_conversationId)
          .set({
        'participants': [user?.uid, widget.otherUserId],
        'lastMessage': text,
        'lastSenderId': user?.uid,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'participantNames': {
          user?.uid: user?.displayName ?? 'User',
          widget.otherUserId: widget.otherUserName,
        },
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _optimisticMessages.removeWhere((m) => m['id'] == tempId);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _optimisticMessages.removeWhere((m) => m['id'] == tempId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message send failed. Try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentUid = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Messages
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('dm_conversations')
                    .doc(_conversationId)
                    .collection('messages')
                    .orderBy('timestamp', descending: false)
                    .limit(50)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty && _optimisticMessages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline_rounded,
                              color: Colors.grey[700], size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Start a private conversation\nwith ${widget.otherUserName}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount:
                    docs.length + _optimisticMessages.length,
                    itemBuilder: (context, index) {
                      if (index >= docs.length) {
                        final msg = _optimisticMessages[
                        index - docs.length];
                        return _buildBubble(
                          messageId: msg['id'],
                          isMe: true,
                          senderName: msg['senderName'],
                          text: msg['text'],
                          isPending: true,
                          isRead: false,
                          replyTo: msg['replyTo'],
                        );
                      }

                      final doc = docs[index];
                      final data =
                      doc.data() as Map<String, dynamic>;
                      final isMe = data['senderId'] == currentUid;

                      return _buildBubble(
                        messageId: doc.id,
                        isMe: isMe,
                        senderName: data['senderName'] ?? 'User',
                        text: data['text'] ?? '',
                        isPending: false,
                        isRead: data['isRead'] ?? false,
                        replyTo: data['replyTo'],
                      );
                    },
                  );
                },
              ),
            ),

            // Typing indicator
            if (_otherIsTyping)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildTypingDots(),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.otherUserName} is typing...',
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),

            // Reply preview
            if (_replyingTo != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(
                        color:
                        AppColors.accent.withValues(alpha: 0.3)),
                    left: BorderSide(
                        color: AppColors.accent, width: 3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Replying to ${_replyingTo!['senderName']}',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _replyingTo!['text'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _replyingTo = null),
                      child: const Icon(Icons.close_rounded,
                          color: AppColors.textMuted, size: 18),
                    ),
                  ],
                ),
              ),

            // Input bar
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white
                              .withValues(alpha: 0.08),
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText:
                          'Message ${widget.otherUserName}...',
                          hintStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.accent,
            backgroundImage: widget.otherUserPhoto != null &&
                widget.otherUserPhoto!.isNotEmpty
                ? NetworkImage(widget.otherUserPhoto!)
                : null,
            child: widget.otherUserPhoto == null ||
                widget.otherUserPhoto!.isEmpty
                ? Text(
              widget.otherUserName[0].toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            )
                : null,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.otherUserName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
              ),
              if (_otherIsTyping)
                Text(
                  'typing...',
                  style: TextStyle(
                      color: AppColors.accent, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.surface, height: 1),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Message Bubble
  // ─────────────────────────────────────────────

  Widget _buildBubble({
    required String messageId,
    required bool isMe,
    required String senderName,
    required String text,
    required bool isPending,
    required bool isRead,
    Map<String, dynamic>? replyTo,
  }) {
    return Dismissible(
      key: Key('dm-$messageId'),
      direction: isMe
          ? DismissDirection.endToStart
          : DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        setState(() => _replyingTo = {
          'messageId': messageId,
          'senderName': senderName,
          'text': text,
        });
        return false;
      },
      background: Container(
        alignment:
        isMe ? Alignment.centerRight : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.reply_rounded,
            color: AppColors.accent, size: 24),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment:
          isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Other user avatar
            if (!isMe) ...[
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.accent,
                child: Text(
                  senderName[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
            ],

            Flexible(
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Reply preview
                  if (replyTo != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                              color: AppColors.accent, width: 2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            replyTo['senderName'] ?? '',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            replyTo['text'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Bubble
                  Opacity(
                    opacity: isPending ? 0.6 : 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft:
                          Radius.circular(isMe ? 16 : 4),
                          bottomRight:
                          Radius.circular(isMe ? 4 : 16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                            Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              text,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14),
                            ),
                          ),
                          if (isPending) ...[
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Colors.white
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Read receipt
                  if (isMe && !isPending) ...[
                    const SizedBox(height: 2),
                    Icon(
                      isRead
                          ? Icons.done_all_rounded
                          : Icons.done_rounded,
                      size: 12,
                      color: isRead
                          ? AppColors.accent
                          : AppColors.textMuted,
                    ),
                  ],
                ],
              ),
            ),

            if (isMe) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingDots() {
    return Row(
      children: List.generate(
        3,
            (i) => Container(
          margin: const EdgeInsets.only(right: 3),
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.textSecondary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}