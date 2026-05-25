import 'package:flutter/material.dart';
import 'package:flowva/core/constants/app_colors.dart';
import 'package:flowva/data/models/post_model.dart';
import 'package:flowva/features/feed/controllers/feed_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final String groupId;

  const PostCard({super.key, required this.post, required this.groupId});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final timeAgo = _timeAgo(post.createdAt.toDate());
    final initials = post.authorName.isNotEmpty
        ? post.authorName[0].toUpperCase()
        : '?';

    final reactionsList = [
      {'label': '✅ Done', 'key': 'done'},
      {'label': '⚠️ Important', 'key': 'important'},
      {'label': '👀 Reviewing', 'key': 'reviewing'},
      {'label': '🎉 Great', 'key': 'great'},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentTeal.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Author Row ──
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.accentTeal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            post.authorRole,
                            style: const TextStyle(
                              color: AppColors.accentTeal,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeAgo,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Content ──
          Text(
            post.content,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 12),

          // ── Reactions ──
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: reactionsList.map((r) {
              final key = r['key']!;
              final users = post.reactions[key] ?? [];
              final isReacted = users.contains(currentUid);

              return GestureDetector(
                onTap: () => FeedController.instance.addReaction(
                  groupId,
                  post.id,
                  key,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isReacted
                        ? AppColors.accentTeal.withValues(alpha: 0.15)
                        : AppColors.primaryBackground.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isReacted
                          ? AppColors.accentTeal.withValues(alpha: 0.4)
                          : AppColors.textMuted.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        r['label']!,
                        style: TextStyle(
                          color: isReacted
                              ? AppColors.accentTeal
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: isReacted
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (users.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${users.length}',
                          style: TextStyle(
                            color: isReacted
                                ? AppColors.accentTeal
                                : AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 10),

          // ── Comments ──
          Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.textMuted,
                size: 15,
              ),
              const SizedBox(width: 4),
              Text(
                '${post.commentCount} comment${post.commentCount == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}