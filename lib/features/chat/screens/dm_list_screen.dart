import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';

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
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.surface, height: 1),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('dm_conversations')
            .where('participants', arrayContains: currentUid)
            .orderBy('lastTimestamp', descending: true)
            .limit(30)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const _EmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final participants =
              List<String>.from(data['participants'] ?? []);
              final otherUid = participants.firstWhere(
                    (uid) => uid != currentUid,
                orElse: () => '',
              );

              final participantNames =
                  data['participantNames'] as Map<String, dynamic>? ?? {};
              final otherName =
                  participantNames[otherUid] as String? ?? 'User';

              final lastMessage = data['lastMessage'] as String? ?? '';
              final lastTimestamp =
              (data['lastTimestamp'] as Timestamp?)?.toDate();
              final lastSenderId = data['lastSenderId'] as String? ?? '';
              final isMe = lastSenderId == currentUid;

              return _ConversationTile(
                otherUid: otherUid,
                otherName: otherName,
                lastMessage: lastMessage,
                lastTimestamp: lastTimestamp,
                isMe: isMe,
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
        children: const [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 64, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          SizedBox(height: 6),
          Text(
            'Go to Members and tap a user to DM them',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Conversation Tile ─────────────────────────────────────────────────────────
class _ConversationTile extends StatelessWidget {
  final String otherUid;
  final String otherName;
  final String lastMessage;
  final DateTime? lastTimestamp;
  final bool isMe;

  const _ConversationTile({
    required this.otherUid,
    required this.otherName,
    required this.lastMessage,
    required this.lastTimestamp,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(otherUid)
          .get(),
      builder: (ctx, snap) {
        final userData =
        snap.hasData ? snap.data!.data() as Map<String, dynamic>? : null;
        final photoURL = userData?['photoURL'] as String?;
        final displayName =
            userData?['displayName'] as String? ?? otherName;

        return GestureDetector(
          onTap: () => context.push(
            '/dm/$otherUid',
            extra: {
              'otherUserName': displayName,
              'otherUserPhoto': photoURL,
            },
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.accent,
                  backgroundImage: photoURL != null && photoURL.isNotEmpty
                      ? NetworkImage(photoURL)
                      : null,
                  child: photoURL == null || photoURL.isEmpty
                      ? Text(
                    displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 12),

                // Name + last message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
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
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Timestamp
                if (lastTimestamp != null)
                  Text(
                    _formatTime(lastTimestamp!),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    if (diff == 0) return '$h:$m';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (diff < 7) return days[dt.weekday - 1];
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }
}