import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flowva/core/constants/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final String groupId;
  final String channelName;

  const ChatScreen({
    super.key,
    required this.groupId,
    required this.channelName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _currentUserRole = 'member';
  final List<Map<String, dynamic>> _optimisticMessages = [];

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserRole();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentUserRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && mounted) {
      setState(() {
        _currentUserRole = doc.data()?['role'] ?? 'member';
      });
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = _auth.currentUser;
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();

    // Optimistic UI — instantly show message
    setState(() {
      _optimisticMessages.add({
        'id': tempId,
        'senderId': user?.uid,
        'senderName': user?.displayName ?? 'User',
        'senderRole': _currentUserRole,
        'text': text,
        'isPending': true,
      });
    });

    _controller.clear();
    _scrollToBottom();

    try {
      await _firestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('channels')
          .doc('general')
          .collection('messages')
          .add({
        'senderId': user?.uid,
        'senderName': user?.displayName ?? 'User',
        'senderRole': _currentUserRole,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Remove from optimistic list after Firestore confirms
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
            content: Text('Message send nahi hua, dobara try karo'),
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

  Color _getRoleColor(String role) {
    return switch (role) {
      'owner'   => const Color(0xFFFF6B6B),
      'manager' => const Color(0xFFFFB347),
      'member'  => AppColors.primary,
      _         => Colors.blueGrey,
    };
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            Text('# ',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text(widget.channelName,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.surface, height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('groups')
                    .doc(widget.groupId)
                    .collection('channels')
                    .doc('general')
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
                          Icon(Icons.chat_bubble_outline,
                              color: Colors.grey[700], size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Koi message nahi abhi\nSalam karo! 👋',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: docs.length + _optimisticMessages.length,
                    itemBuilder: (context, index) {
                      // Optimistic messages at end
                      if (index >= docs.length) {
                        final msg = _optimisticMessages[index - docs.length];
                        return _buildMessageBubble(
                          isMe: true,
                          senderName: msg['senderName'],
                          senderRole: msg['senderRole'],
                          messageText: msg['text'],
                          isPending: true,
                        );
                      }

                      final data =
                      docs[index].data() as Map<String, dynamic>;
                      final isMe = data['senderId'] == currentUid;

                      return _buildMessageBubble(
                        isMe: isMe,
                        senderName: data['senderName'] ?? 'User',
                        senderRole: data['senderRole'] ?? 'member',
                        messageText: data['text'] ?? '',
                        isPending: false,
                      );
                    },
                  );
                },
              ),
            ),

            // Input Bar
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08), width: 1),
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
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Message #${widget.channelName}',
                          hintStyle: TextStyle(
                              color: Colors.grey[600], fontSize: 14),
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

  Widget _buildMessageBubble({
    required bool isMe,
    required String senderName,
    required String senderRole,
    required String messageText,
    required bool isPending,
  }) {
    final roleColor = _getRoleColor(senderRole);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar — doosron ke liye
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surface,
              child: Text(
                senderName.isNotEmpty
                    ? senderName[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
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
                // Name + Role badge
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          senderName,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: roleColor.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            senderRole,
                            style: TextStyle(
                              color: roleColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
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
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
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
                            messageText,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ),
                        if (isPending) ...[
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}