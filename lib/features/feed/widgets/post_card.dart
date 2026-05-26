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

    final likeUsers = post.reactions['like'] ?? [];
    final isLiked = likeUsers.contains(currentUid);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentTeal.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accentTeal.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
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
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.aiAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              post.authorRole,
                              style: const TextStyle(
                                color: AppColors.aiAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
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
                Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.textMuted,
                  size: 22,
                ),
              ],
            ),
          ),

          // ── Content ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Text(
              post.content,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),

          // ── Image (if any) ──
          if (post.fileUrls.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: Image.network(
                post.fileUrls.first,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(),
              ),
            ),

          // ── Reactions count row ──
          if (_totalReactions(post) > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  _reactionBubble('👍', post.reactions['like']?.length ?? 0),
                  _reactionBubble('❤️', post.reactions['love']?.length ?? 0),
                  _reactionBubble('🎉', post.reactions['great']?.length ?? 0),
                  const Spacer(),
                  Text(
                    '${post.commentCount} comment${post.commentCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // ── Divider ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Divider(
              color: AppColors.textMuted.withValues(alpha: 0.15),
              height: 1,
            ),
          ),

          // ── Action Buttons ──
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ActionButton(
                  icon: isLiked
                      ? Icons.thumb_up_rounded
                      : Icons.thumb_up_outlined,
                  label: 'Like',
                  color: isLiked ? AppColors.accentTeal : AppColors.textMuted,
                  onTap: () => FeedController.instance
                      .addReaction(groupId, post.id, 'like'),
                ),
                _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Comment',
                  color: AppColors.textMuted,
                  onTap: () {},
                ),
                _ActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  color: AppColors.textMuted,
                  onTap: () {},
                ),
              ],
            ),
          ),

          // ── Emoji Reactions Row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                _EmojiReaction(
                  emoji: '👍',
                  reactionKey: 'like',
                  post: post,
                  groupId: groupId,
                  currentUid: currentUid,
                ),
                const SizedBox(width: 8),
                _EmojiReaction(
                  emoji: '❤️',
                  reactionKey: 'love',
                  post: post,
                  groupId: groupId,
                  currentUid: currentUid,
                ),
                const SizedBox(width: 8),
                _EmojiReaction(
                  emoji: '🎉',
                  reactionKey: 'great',
                  post: post,
                  groupId: groupId,
                  currentUid: currentUid,
                ),
                const SizedBox(width: 8),
                _EmojiReaction(
                  emoji: '👀',
                  reactionKey: 'reviewing',
                  post: post,
                  groupId: groupId,
                  currentUid: currentUid,
                ),
                const SizedBox(width: 8),
                _EmojiReaction(
                  emoji: '⚠️',
                  reactionKey: 'important',
                  post: post,
                  groupId: groupId,
                  currentUid: currentUid,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _totalReactions(PostModel post) {
    int total = 0;
    post.reactions.forEach((_, users) => total += users.length);
    return total;
  }

  Widget _reactionBubble(String emoji, int count) {
    if (count == 0) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text('$emoji $count',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    );
  }
}

// ── Action Button ──────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Emoji Reaction ─────────────────────────────────────────────────────────────

class _EmojiReaction extends StatelessWidget {
  final String emoji;
  final String reactionKey;
  final PostModel post;
  final String groupId;
  final String currentUid;

  const _EmojiReaction({
    required this.emoji,
    required this.reactionKey,
    required this.post,
    required this.groupId,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context) {
    final users = post.reactions[reactionKey] ?? [];
    final isReacted = users.contains(currentUid);

    return GestureDetector(
      onTap: () =>
          FeedController.instance.addReaction(groupId, post.id, reactionKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isReacted
              ? AppColors.accentTeal.withValues(alpha: 0.15)
              : AppColors.primaryBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isReacted
                ? AppColors.accentTeal.withValues(alpha: 0.4)
                : AppColors.textMuted.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            if (users.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                '${users.length}',
                style: TextStyle(
                  color: isReacted
                      ? AppColors.accentTeal
                      : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}