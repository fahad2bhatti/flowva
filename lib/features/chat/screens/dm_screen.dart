import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flowva/core/constants/app_colors.dart';
import 'package:flowva/data/repositories/dm_repository.dart';
import 'package:flowva/data/models/dm_model.dart';

/// DM Screen — Personal Direct Message conversation
/// Usage: DMScreen(otherUserId: uid, otherUserName: name)

class DMScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String otherUserPhoto;

  const DMScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto = '',
  });

  @override
  State<DMScreen> createState() => _DMScreenState();
}

class _DMScreenState extends State<DMScreen> {
  final _repo           = DmRepository.instance;
  final _auth           = FirebaseAuth.instance;
  final _msgController  = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode      = FocusNode();

  String? _dmId;
  bool _isLoading = true;
  bool _isSending = false;
  DmMessageModel? _replyTo;

  String get _myUid => _auth.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _initDm();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initDm() async {
    final dmId = await _repo.getOrCreateDm(widget.otherUserId);
    await _repo.markAsRead(dmId);
    if (mounted) setState(() { _dmId = dmId; _isLoading = false; });
  }

  Future<void> _sendMessage() async {
    final content = _msgController.text.trim();
    if (content.isEmpty || _dmId == null || _isSending) return;

    setState(() => _isSending = true);
    _msgController.clear();

    await _repo.sendMessage(
      dmId          : _dmId!,
      content       : content,
      otherUid      : widget.otherUserId,
      replyToId     : _replyTo?.id,
      replyToContent: _replyTo?.content,
    );

    setState(() { _isSending = false; _replyTo = null; });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _setReply(DmMessageModel msg) {
    setState(() => _replyTo = msg);
    _focusNode.requestFocus();
  }

  void _clearReply() => setState(() => _replyTo = null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : Column(
        children: [
          Expanded(child: _buildMessagesList()),
          if (_replyTo != null) _buildReplyBanner(),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    final initial = widget.otherUserName.isNotEmpty
        ? widget.otherUserName[0].toUpperCase()
        : 'U';

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
        onPressed: () => context.canPop() ? context.pop() : null,
      ),
      title: Row(
        children: [
          // Avatar
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            alignment: Alignment.center,
            child: widget.otherUserPhoto.isNotEmpty
                ? ClipOval(
              child: Image.network(
                widget.otherUserPhoto,
                width: 36, height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Text(initial,
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
            )
                : Text(initial,
                style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.otherUserName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
              const Text(
                'Direct Message',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
          onPressed: _showOptions,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  // ── Messages List ────────────────────────────────────────────────────────
  Widget _buildMessagesList() {
    if (_dmId == null) return const SizedBox.shrink();

    return StreamBuilder<List<DmMessageModel>>(
      stream: _repo.getMessages(_dmId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.accent));
        }

        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          itemCount: messages.length,
          itemBuilder: (ctx, i) {
            final msg    = messages[i];
            final isMe   = msg.senderId == _myUid;
            final showDate = i == messages.length - 1 ||
                !_isSameDay(messages[i].createdAt, messages[i + 1].createdAt);

            return Column(
              children: [
                if (showDate) _buildDateSeparator(msg.createdAt),
                _buildMessageBubble(msg, isMe),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final initial = widget.otherUserName.isNotEmpty
        ? widget.otherUserName[0].toUpperCase()
        : 'U';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
            ),
            alignment: Alignment.center,
            child: Text(initial,
                style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Text(
            widget.otherUserName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Send a message to start the conversation',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Message Bubble ────────────────────────────────────────────────────────
  Widget _buildMessageBubble(DmMessageModel msg, bool isMe) {
    final isDeleted = msg.content == 'This message was deleted';

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.lightImpact();
        if (!isDeleted) _showMessageOptions(msg, isMe);
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.72,
          ),
          child: Column(
            crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Reply preview
              if (msg.replyToContent != null && !isDeleted)
                _buildReplyPreview(msg.replyToContent!, isMe),

              // Bubble
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe
                      ? AppColors.accent
                      : AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft    : const Radius.circular(16),
                    topRight   : const Radius.circular(16),
                    bottomLeft : isMe
                        ? const Radius.circular(16)
                        : const Radius.circular(4),
                    bottomRight: isMe
                        ? const Radius.circular(4)
                        : const Radius.circular(16),
                  ),
                  border: isMe
                      ? null
                      : Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.content,
                      style: TextStyle(
                        color: isDeleted
                            ? AppColors.textMuted
                            : isMe ? Colors.white : AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.4,
                        fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(msg.createdAt),
                          style: TextStyle(
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.65)
                                : AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            msg.isRead
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                            size: 12,
                            color: msg.isRead
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview(String content, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withValues(alpha: 0.15)
            : AppColors.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white : AppColors.accent,
            width: 3,
          ),
        ),
      ),
      child: Text(
        content.length > 60 ? '${content.substring(0, 60)}...' : content,
        style: TextStyle(
          color: isMe ? Colors.white70 : AppColors.textSecondary,
          fontSize: 11,
          fontFamily: 'Inter',
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDateSeparator(Timestamp ts) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _formatDate(ts),
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontFamily: 'Inter'),
            ),
          ),
          Expanded(child: Divider(color: AppColors.border)),
        ],
      ),
    );
  }

  // ── Reply Banner ─────────────────────────────────────────────────────────
  Widget _buildReplyBanner() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Replying to',
                    style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                Text(
                  _replyTo!.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                color: AppColors.textMuted, size: 18),
            onPressed: _clearReply,
          ),
        ],
      ),
    );
  }

  // ── Input Bar ─────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Text field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller  : _msgController,
                  focusNode   : _focusNode,
                  maxLines    : 4,
                  minLines    : 1,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontFamily: 'Inter'),
                  decoration: const InputDecoration(
                    hintText : 'Message...',
                    hintStyle: TextStyle(
                        color: AppColors.textMuted, fontSize: 14),
                    border          : InputBorder.none,
                    contentPadding  : EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            GestureDetector(
              onTap: _sendMessage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _isSending
                      ? AppColors.accent.withValues(alpha: 0.5)
                      : AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: _isSending
                    ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Options ───────────────────────────────────────────────────────────────
  void _showMessageOptions(DmMessageModel msg, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.reply_rounded, color: AppColors.accent),
              title: const Text('Reply',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () { Navigator.pop(ctx); _setReply(msg); },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: AppColors.textSecondary),
              title: const Text('Copy',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: msg.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error),
                title: const Text('Delete',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _repo.deleteMessage(_dmId!, msg.id);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.mark_chat_read_outlined,
                  color: AppColors.accent),
              title: const Text('Mark all as read',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                if (_dmId != null) _repo.markAsRead(_dmId!);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Utils ─────────────────────────────────────────────────────────────────
  bool _isSameDay(Timestamp a, Timestamp b) {
    final da = a.toDate();
    final db = b.toDate();
    return da.year == db.year && da.month == db.month && da.day == db.day;
  }

  String _formatTime(Timestamp ts) {
    final d = ts.toDate();
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDate(Timestamp ts) {
    final d   = ts.toDate();
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (d.year == yesterday.year &&
        d.month == yesterday.month &&
        d.day == yesterday.day) {
      return 'Yesterday';
    }
    return '${d.day}/${d.month}/${d.year}';
  }
}