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

  // Reply state
  Map<String, dynamic>? _replyingTo;

  // Typing state
  Timer? _typingTimer;
  StreamSubscription? _typingSubscription;
  List<String> _typingNames = [];

  // Members for @mention
  List<Map<String, dynamic>> _groupMembers = [];
  List<Map<String, dynamic>> _mentionSuggestions = [];
  bool _showMentions = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserRole();
    _fetchGroupMembers();
    _listenTyping();
    _controller.addListener(_onTextChanged);
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
  // Init helpers
  // ─────────────────────────────────────────────

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

  Future<void> _fetchGroupMembers() async {
    final snap = await _firestore
        .collection('groups')
        .doc(widget.groupId)
        .collection('members')
        .get();

    final members = <Map<String, dynamic>>[];
    for (final doc in snap.docs) {
      final userDoc =
      await _firestore.collection('users').doc(doc.id).get();
      if (userDoc.exists) {
        members.add({
          'uid': doc.id,
          'name': userDoc.data()?['name'] ?? 'User',
          'username': userDoc.data()?['username'] ?? '',
        });
      }
    }
    if (mounted) setState(() => _groupMembers = members);
  }

  // ─────────────────────────────────────────────
  // Typing indicator
  // ─────────────────────────────────────────────

  void _listenTyping() {
    _typingSubscription = _firestore
        .collection('groups')
        .doc(widget.groupId)
        .collection('typing')
        .snapshots()
        .listen((snap) {
      final uid = _auth.currentUser?.uid;
      final now = DateTime.now();
      final names = snap.docs
          .where((d) => d.id != uid)
          .where((d) {
        final ts = d.data()['timestamp'] as int? ?? 0;
        return now.millisecondsSinceEpoch - ts < 4000;
      })
          .map((d) => d.data()['name'] as String? ?? 'Someone')
          .toList();
      if (mounted) setState(() => _typingNames = names);
    });
  }

  void _updateTyping() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _firestore
        .collection('groups')
        .doc(widget.groupId)
        .collection('typing')
        .doc(uid)
        .set({
      'name': _auth.currentUser?.displayName ?? 'User',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), _clearTyping);
  }

  void _clearTyping() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _firestore
        .collection('groups')
        .doc(widget.groupId)
        .collection('typing')
        .doc(uid)
        .delete();
  }

  // ─────────────────────────────────────────────
  // @mention
  // ─────────────────────────────────────────────

  void _onTextChanged() {
    final text = _controller.text;
    _updateTyping();

    final atIndex = text.lastIndexOf('@');
    if (atIndex != -1) {
      final query = text.substring(atIndex + 1).toLowerCase();
      final suggestions = _groupMembers
          .where((m) =>
      (m['name'] as String).toLowerCase().contains(query) ||
          (m['username'] as String).toLowerCase().contains(query))
          .toList();
      setState(() {
        _mentionSuggestions = suggestions;
        _showMentions = suggestions.isNotEmpty;
      });
    } else {
      setState(() => _showMentions = false);
    }
  }

  void _insertMention(Map<String, dynamic> member) {
    final text = _controller.text;
    final atIndex = text.lastIndexOf('@');
    if (atIndex == -1) return;
    final newText =
        '${text.substring(0, atIndex)}@${member['name']} ';
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    setState(() => _showMentions = false);
  }

  // ─────────────────────────────────────────────
  // Send message
  // ─────────────────────────────────────────────

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = _auth.currentUser;
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();

    final messageData = <String, dynamic>{
      'id': tempId,
      'senderId': user?.uid,
      'senderName': user?.displayName ?? 'User',
      'senderRole': _currentUserRole,
      'text': text,
      'isPending': true,
    };

    if (_replyingTo != null) {
      messageData['replyTo'] = _replyingTo;
    }

    setState(() {
      _optimisticMessages.add(messageData);
      _replyingTo = null;
    });

    _controller.clear();
    _clearTyping();
    _scrollToBottom();

    try {
      final firestoreData = {
        'senderId': user?.uid,
        'senderName': user?.displayName ?? 'User',
        'senderRole': _currentUserRole,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'reactions': {},
        if (_replyingTo != null) 'replyTo': _replyingTo,
      };

      await _firestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('channels')
          .doc('general')
          .collection('messages')
          .add(firestoreData);

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

  // ─────────────────────────────────────────────
  // Reactions
  // ─────────────────────────────────────────────

  void _showReactionPicker(String messageId) {
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '🔥'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: emojis
              .map((emoji) => GestureDetector(
            onTap: () {
              Navigator.pop(context);
              _toggleReaction(messageId, emoji);
            },
            child: Text(emoji,
                style: const TextStyle(fontSize: 32)),
          ))
              .toList(),
        ),
      ),
    );
  }

  Future<void> _toggleReaction(String messageId, String emoji) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final ref = _firestore
        .collection('groups')
        .doc(widget.groupId)
        .collection('channels')
        .doc('general')
        .collection('messages')
        .doc(messageId);

    final doc = await ref.get();
    final reactions =
    Map<String, dynamic>.from(doc.data()?['reactions'] ?? {});
    final users = List<String>.from(reactions[emoji] ?? []);

    if (users.contains(uid)) {
      users.remove(uid);
    } else {
      users.add(uid);
    }

    if (users.isEmpty) {
      reactions.remove(emoji);
    } else {
      reactions[emoji] = users;
    }

    await ref.update({'reactions': reactions});
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

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

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

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
                style:
                const TextStyle(color: Colors.white, fontSize: 16)),
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
            // Messages list
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
                            'No messages yet\nSay hello! 👋',
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
                    itemCount:
                    docs.length + _optimisticMessages.length,
                    itemBuilder: (context, index) {
                      if (index >= docs.length) {
                        final msg = _optimisticMessages[
                        index - docs.length];
                        return _buildMessageBubble(
                          messageId: msg['id'],
                          isMe: true,
                          senderName: msg['senderName'],
                          senderRole: msg['senderRole'],
                          messageText: msg['text'],
                          isPending: true,
                          reactions: {},
                          replyTo: msg['replyTo'],
                          currentUid: currentUid,
                        );
                      }

                      final doc = docs[index];
                      final data =
                      doc.data() as Map<String, dynamic>;
                      final isMe = data['senderId'] == currentUid;

                      return _buildMessageBubble(
                        messageId: doc.id,
                        isMe: isMe,
                        senderName: data['senderName'] ?? 'User',
                        senderRole: data['senderRole'] ?? 'member',
                        messageText: data['text'] ?? '',
                        isPending: false,
                        reactions: Map<String, dynamic>.from(
                            data['reactions'] ?? {}),
                        replyTo: data['replyTo'],
                        currentUid: currentUid,
                      );
                    },
                  );
                },
              ),
            ),

            // Typing indicator
            if (_typingNames.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _TypingDots(),
                    const SizedBox(width: 8),
                    Text(
                      _typingNames.length == 1
                          ? '${_typingNames[0]} is typing...'
                          : '${_typingNames.take(2).join(' and ')} are typing...',
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),

            // @mention suggestions
            if (_showMentions)
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                      top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08))),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _mentionSuggestions.length,
                  itemBuilder: (_, i) {
                    final m = _mentionSuggestions[i];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.accent,
                        child: Text(
                          (m['name'] as String)[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                      title: Text(m['name'] as String,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13)),
                      subtitle: Text('@${m['username']}',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11)),
                      onTap: () => _insertMention(m),
                    );
                  },
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
                        color: AppColors.accent.withValues(alpha: 0.3)),
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
                          color:
                          Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText:
                          'Message #${widget.channelName}',
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

  // ─────────────────────────────────────────────
  // Message Bubble
  // ─────────────────────────────────────────────

  Widget _buildMessageBubble({
    required String messageId,
    required bool isMe,
    required String senderName,
    required String senderRole,
    required String messageText,
    required bool isPending,
    required Map<String, dynamic> reactions,
    required String? currentUid,
    Map<String, dynamic>? replyTo,
  }) {
    final roleColor = _getRoleColor(senderRole);

    return GestureDetector(
      onLongPress: isPending
          ? null
          : () => _showReactionPicker(messageId),
      child: Dismissible(
        key: Key('$messageId-dismiss'),
        direction: isMe
            ? DismissDirection.endToStart
            : DismissDirection.startToEnd,
        confirmDismiss: (_) async {
          setState(() => _replyingTo = {
            'messageId': messageId,
            'senderName': senderName,
            'text': messageText,
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
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
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
                    // Name + role badge
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 4, bottom: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(senderName,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight:
                                    FontWeight.w600)),
                            const SizedBox(width: 6),
                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2),
                              decoration: BoxDecoration(
                                color: roleColor.withValues(
                                    alpha: 0.15),
                                borderRadius:
                                BorderRadius.circular(6),
                                border: Border.all(
                                  color: roleColor.withValues(
                                      alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Text(senderRole,
                                  style: TextStyle(
                                      color: roleColor,
                                      fontSize: 10,
                                      fontWeight:
                                      FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),

                    // Reply preview inside bubble
                    if (replyTo != null)
                      Container(
                        margin:
                        const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black
                              .withValues(alpha: 0.2),
                          borderRadius:
                          BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                                color: AppColors.accent,
                                width: 2),
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
                            topLeft:
                            const Radius.circular(16),
                            topRight:
                            const Radius.circular(16),
                            bottomLeft:
                            Radius.circular(isMe ? 16 : 4),
                            bottomRight:
                            Radius.circular(isMe ? 4 : 16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: _buildMessageText(
                                  messageText),
                            ),
                            if (isPending) ...[
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 10,
                                height: 10,
                                child:
                                CircularProgressIndicator(
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

                    // Reactions
                    if (reactions.isNotEmpty)
                      Padding(
                        padding:
                        const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          children: reactions.entries
                              .where((e) =>
                          (e.value as List).isNotEmpty)
                              .map((e) {
                            final emoji = e.key;
                            final users =
                            List<String>.from(e.value);
                            final iReacted = currentUid != null
                                ? users.contains(currentUid)
                                : false;
                            return GestureDetector(
                              onTap: () => _toggleReaction(
                                  messageId, emoji),
                              child: AnimatedContainer(
                                duration: const Duration(
                                    milliseconds: 200),
                                padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3),
                                decoration: BoxDecoration(
                                  color: iReacted
                                      ? AppColors.accent
                                      .withValues(alpha: 0.2)
                                      : AppColors.surface,
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  border: Border.all(
                                    color: iReacted
                                        ? AppColors.accent
                                        : AppColors.border,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '$emoji ${users.length}',
                                  style: const TextStyle(
                                      fontSize: 12),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              if (isMe) const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  // @mention highlight
  Widget _buildMessageText(String text) {
    final spans = <TextSpan>[];
    final parts = text.split(RegExp(r'(@\w+)'));
    for (final part in parts) {
      if (part.startsWith('@')) {
        spans.add(TextSpan(
          text: part,
          style: TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: part,
          style:
          const TextStyle(color: Colors.white, fontSize: 14),
        ));
      }
    }
    return RichText(text: TextSpan(children: spans));
  }
}

// ─────────────────────────────────────────────
// Typing dots animation
// ─────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Row(
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
      ),
    );
  }
}