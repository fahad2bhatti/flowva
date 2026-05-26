import 'package:flutter/material.dart';
import 'package:flowva/core/constants/app_colors.dart';
import 'package:flowva/data/models/group_model.dart';
import 'package:flowva/features/feed/controllers/feed_controller.dart';
import 'package:flowva/features/feed/widgets/post_card.dart';
//

class GroupFeedScreen extends StatefulWidget {
  final GroupModel group;

  const GroupFeedScreen({super.key, required this.group});

  @override
  State<GroupFeedScreen> createState() => _GroupFeedScreenState();
}

class _GroupFeedScreenState extends State<GroupFeedScreen> {
  final _postController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  // ── Parse color ──────────────────────────────────────────────────────────────
  Color _groupColor() {
    try {
      final hex = widget.group.color.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.accentTeal;
    }
  }
  List<Widget> _buildStoryAvatars() {
    final colors = [
      AppColors.accentTeal,
      AppColors.accentElectricBlue,
      AppColors.aiAccent,
      AppColors.success,
      AppColors.warning,
    ];
    final names = ['You', 'M1', 'M2', 'M3', 'M4'];

    return List.generate(5, (i) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colors[i % colors.length],
                    colors[i % colors.length].withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: colors[i % colors.length].withValues(alpha: 0.5),
                  width: 2.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                names[i][0],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              names[i],
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Create post ──────────────────────────────────────────────────────────────
  void _showComposeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: const BoxDecoration(
            color: Color(0xFF141A3A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Color(0x1A00D4AA)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Text(
                'New Post',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.elevatedSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accentTeal.withValues(alpha: 0.2),
                  ),
                ),
                child: TextField(
                  controller: _postController,
                  maxLines: 4,
                  autofocus: true,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Share an update with your team...',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentTeal.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _isPosting
                          ? null
                          : () async {
                        final content = _postController.text.trim();
                        if (content.isEmpty) return;
                        setState(() => _isPosting = true);
                        try {
                          await FeedController.instance.createPost(
                            widget.group.id,
                            content,
                          );
                          _postController.clear();
                          if (mounted) Navigator.pop(ctx);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e
                                    .toString()
                                    .replaceAll('Exception: ', '')),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isPosting = false);
                        }
                      },
                      child: Center(
                        child: _isPosting
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          'Post',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupColor = _groupColor();

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.elevatedSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.text,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Group color dot
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: groupColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: groupColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.group_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.group.name,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${widget.group.memberCount} member${widget.group.memberCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Members icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.elevatedSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.people_outline_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // ── AI Banner ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.aiAccent.withValues(alpha: 0.15),
                      AppColors.accentElectricBlue.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.aiAccent.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.aiAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'AI Summary — Coming soon',
                        style: TextStyle(
                          color: AppColors.aiAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Stories Row ──────────────────────────────────────────
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.accentTeal,
                              width: 2,
                            ),
                            color: AppColors.elevatedSurface,
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: AppColors.accentTeal,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Add Story',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._buildStoryAvatars(),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Posts Feed ───────────────────────────────────────────
            Expanded(
              child: StreamBuilder(
                stream: FeedController.instance.getPosts(widget.group.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentTeal,
                        strokeWidth: 2,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        snapshot.error.toString(),
                        style: const TextStyle(color: AppColors.error),
                      ),
                    );
                  }

                  final posts = snapshot.data ?? [];

                  if (posts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.accentTeal.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: AppColors.accentTeal,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No posts yet',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Be the first to share an update!',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: posts.length,
                    itemBuilder: (ctx, i) => PostCard(
                      post: posts[i],
                      groupId: widget.group.id,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ── FAB (Compose) ────────────────────────────────────────────────────────
      floatingActionButton: GestureDetector(
        onTap: _showComposeSheet,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accentTeal.withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.edit_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}