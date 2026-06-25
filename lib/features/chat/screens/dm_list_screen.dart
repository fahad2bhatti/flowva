import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/dm_model.dart';
import '../../../data/repositories/dm_repository.dart';

class DmListScreen extends StatelessWidget {
  const DmListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Direct Messages',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      // ✅ FIX: DmRepository.getMyDms() use karo
      // collection: 'dms' (not 'dm_conversations')
      body: StreamBuilder<List<DmModel>>(
        stream: DmRepository.instance.getMyDms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString().replaceAll('Exception: ', ''),
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }

          final dms = snapshot.data ?? [];

          if (dms.isEmpty) {
            return const _EmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: dms.length,
            itemBuilder: (ctx, i) {
              final dm = dms[i];
              // ✅ FIX: DmModel helpers use karo — otherUserName, otherUserPhoto
              final otherUid   = dm.otherUserId(currentUid);
              final otherName  = dm.otherUserName(currentUid);
              final otherPhoto = dm.otherUserPhoto(currentUid);
              final unread     = dm.myUnreadCount(currentUid);
              final isMe       = dm.lastMessageSenderId == currentUid;

              return _ConversationTile(
                otherUid      : otherUid,
                otherName     : otherName,
                otherPhoto    : otherPhoto,
                lastMessage   : dm.lastMessage,
                lastMessageAt : dm.lastMessageAt.toDate(),
                isMe          : isMe,
                unreadCount   : unread,
              );
            },
          );
        },
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 36,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No conversations yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Go to Members and tap a user to message them',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Conversation Tile ─────────────────────────────────────────────────────────
class _ConversationTile extends StatelessWidget {
  final String    otherUid;
  final String    otherName;
  final String    otherPhoto;
  final String    lastMessage;
  final DateTime  lastMessageAt;
  final bool      isMe;
  final int       unreadCount;

  const _ConversationTile({
    required this.otherUid,
    required this.otherName,
    required this.otherPhoto,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.isMe,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    final initial = otherName.isNotEmpty ? otherName[0].toUpperCase() : '?';
    final hasUnread = unreadCount > 0;

    return GestureDetector(
      onTap: () => context.push(
        '/dm/$otherUid',
        extra: {
          'otherUserName' : otherName,
          'otherUserPhoto': otherPhoto,
        },
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          // ✅ Unread conversations slightly highlighted
          color: hasUnread
              ? AppColors.accent.withValues(alpha: 0.05)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasUnread
                ? AppColors.accent.withValues(alpha: 0.2)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                  backgroundImage: otherPhoto.isNotEmpty
                      ? NetworkImage(otherPhoto)
                      : null,
                  child: otherPhoto.isEmpty
                      ? Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )
                      : null,
                ),
                // ✅ Unread dot
                if (hasUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Name + last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherName,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: hasUnread
                          ? FontWeight.w700
                          : FontWeight.w600,
                      fontSize: 15,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lastMessage.isEmpty
                        ? 'No messages yet'
                        : isMe
                        ? 'You: $lastMessage'
                        : lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasUnread
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: hasUnread
                          ? FontWeight.w500
                          : FontWeight.normal,
                      fontSize: 13,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),

            // Timestamp
            Text(
              _formatTime(lastMessageAt),
              style: TextStyle(
                color: hasUnread ? AppColors.accent : AppColors.textMuted,
                fontSize: 11,
                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt).inDays;
    final h    = dt.hour.toString().padLeft(2, '0');
    final m    = dt.minute.toString().padLeft(2, '0');
    if (diff == 0) return '$h:$m';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (diff < 7) return days[dt.weekday - 1];
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }
}