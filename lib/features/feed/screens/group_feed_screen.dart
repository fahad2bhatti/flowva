import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flowva/core/constants/app_colors.dart';
import 'package:flowva/data/models/group_model.dart';
import 'package:flowva/features/feed/controllers/feed_controller.dart';
import 'package:flowva/features/feed/widgets/post_card.dart';
import 'package:flowva/data/models/post_model.dart';
import 'package:flowva/features/tasks/controllers/task_controller.dart';
import 'package:flowva/features/tasks/screens/create_task_screen.dart';
import 'package:flowva/features/tasks/screens/task_detail_screen.dart';
import 'package:flowva/shared/widgets/skeleton_widgets.dart';

class GroupFeedScreen extends StatefulWidget {
  final GroupModel group;
  const GroupFeedScreen({super.key, required this.group});

  @override
  State<GroupFeedScreen> createState() => _GroupFeedScreenState();
}

class _GroupFeedScreenState extends State<GroupFeedScreen> {
  // ─────────────────────────────────────────────
  // Controllers & State
  // ─────────────────────────────────────────────

  final TextEditingController _postController = TextEditingController();
  bool _isPosting = false;
  bool _isRefreshing = false;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Helper Methods
  // ─────────────────────────────────────────────

  Color get groupColor => AppColors.accent;

  /// Safely parse priority from Firestore (handles int, String, numeric String)
  String getPriority(dynamic value) {
    if (value == null) return 'medium';

    if (value is int) {
      if (value == 0) return 'low';
      if (value == 1) return 'medium';
      if (value == 2) return 'high';
      return 'medium';
    }

    if (value is String) {
      final str = value.toLowerCase().trim();
      if (str == 'low' || str == '0') return 'low';
      if (str == 'medium' || str == '1') return 'medium';
      if (str == 'high' || str == '2') return 'high';
    }

    return 'medium';
  }

  Color priorityColor(String p) {
    switch (p) {
      case 'high':
        return AppColors.error;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.warning;
    }
  }

  String priorityLabel(String p) {
    switch (p) {
      case 'high':
        return 'High Priority';
      case 'low':
        return 'Low Priority';
      default:
        return 'Medium Priority';
    }
  }

  String formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.day == now.day && d.month == now.month && d.year == now.year) {
      return 'Today';
    }
    if (d.difference(now).inDays == 1) return 'Tomorrow';
    return '${d.day}/${d.month}';
  }

  DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  // ─────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────

  void _openCreatePost() {
    _postController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CreatePostSheet(
        controller: _postController,
        isPosting: _isPosting,
        onPost: () => _submitPost(ctx),
      ),
    );
  }

  Future<void> _submitPost(BuildContext sheetCtx) async {
    final content = _postController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isPosting = true);
    try {
      await FeedController.instance.createPost(widget.group.id, content);
      _postController.clear();
      if (mounted) Navigator.pop(sheetCtx);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  void _openCreateTask() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTaskScreen(groupId: widget.group.id),
      ),
    );
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _isRefreshing = false);
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.accent,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildTopBar(),
              _buildStoryRow(),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              _buildAiStandupCard(),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              _buildPinnedCard(),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              _buildTaskList(),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              _buildPostList(),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ─────────────────────────────────────────────
  // Sliver Sections
  // ─────────────────────────────────────────────

  SliverToBoxAdapter _buildTopBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textSecondary, size: 20),
              ),
            ),
            const SizedBox(width: 12),

            // Group avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: groupColor, shape: BoxShape.circle),
              child: const Icon(Icons.group_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),

            // Group name & member count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.group.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${widget.group.memberCount} members',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),

            // Members icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.people_outline_rounded,
                  color: AppColors.textSecondary, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildStoryRow() {
    final names = ['You', 'Ali', 'Sara', 'Ahmed', 'Fatima'];
    final colors = [
      AppColors.accent,
      AppColors.textSecondary,
      AppColors.textMuted,
      AppColors.accent,
      AppColors.textSecondary,
    ];

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 90,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            // Add Story button
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent, width: 2),
                      color: AppColors.surface,
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: AppColors.accent, size: 24),
                  ),
                  const SizedBox(height: 6),
                  const Text('Add Story',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 10)),
                ],
              ),
            ),

            // Member story avatars
            ...List.generate(names.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors[i],
                        border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        names[i][0],
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      names[i],
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 10),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildAiStandupCard() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppColors.accent.withValues(alpha: 0.12),
              AppColors.surface,
            ]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✨ AI Daily Standup',
                      style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '5 tasks completed • 2 in progress',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
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

  SliverToBoxAdapter _buildPinnedCard() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.push_pin_rounded, color: AppColors.accent, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📌 PINNED',
                      style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'New project guidelines updated',
                      style: TextStyle(
                          color: AppColors.textPrimary, fontSize: 13),
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

  Widget _buildTaskList() {
    return StreamBuilder(
      stream: TaskController.instance.getGroupTasks(widget.group.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SkeletonPostCard(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SliverToBoxAdapter(child: SizedBox());
        }

        final pending = (snapshot.data as List)
            .where((t) => t['status'] != 'done')
            .toList();

        if (pending.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

        final count = pending.length > 3 ? 3 : pending.length;
        return SliverList(
          delegate: SliverChildBuilderDelegate(
                (ctx, i) => _TaskCard(
              task: pending[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TaskDetailScreen(taskId: pending[i]['id']),
                ),
              ),
              getPriority: getPriority,
              priorityColor: priorityColor,
              priorityLabel: priorityLabel,
              formatDate: formatDate,
              parseDate: parseDate,
            ),
            childCount: count,
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // Unified Feed (Posts + Task Events merged)
  // ─────────────────────────────────────────────

  Widget _buildPostList() {
    return _UnifiedFeedList(group: widget.group, isRefreshing: _isRefreshing);
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Post input
          Expanded(
            child: GestureDetector(
              onTap: _openCreatePost,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.edit_rounded,
                        color: AppColors.textMuted, size: 18),
                    SizedBox(width: 8),
                    Text('Write a post...',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Attach button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.attach_file,
                color: AppColors.textMuted, size: 20),
          ),
          const SizedBox(width: 8),

          // Create task button
          GestureDetector(
            onTap: _openCreateTask,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.add_task_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Extracted Widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Task card widget — extracted for cleanliness
class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback onTap;
  final String Function(dynamic) getPriority;
  final Color Function(String) priorityColor;
  final String Function(String) priorityLabel;
  final String Function(DateTime) formatDate;
  final DateTime? Function(dynamic) parseDate;

  const _TaskCard({
    required this.task,
    required this.onTap,
    required this.getPriority,
    required this.priorityColor,
    required this.priorityLabel,
    required this.formatDate,
    required this.parseDate,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime? due = parseDate(task['dueDate']);
    // assignedBy is a UID String in Firestore, not a Map
    final dynamic assignedByRaw = task['assignedBy'];
    final String assigner = (assignedByRaw is Map)
        ? assignedByRaw['name']?.toString() ?? 'Someone'
        : 'Someone';
    final String priority = getPriority(task['priority']);
    final String title = task['title']?.toString() ?? 'Untitled';
    final String status = task['status']?.toString() ?? 'todo';
    final Color pColor = priorityColor(priority);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Priority icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: pColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.flag_rounded, color: pColor, size: 22),
              ),
              const SizedBox(width: 12),

              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$assigner assigned a task',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (due != null) ...[
                          const Icon(Icons.calendar_today_rounded,
                              size: 10, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            formatDate(due),
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textMuted),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: pColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            priorityLabel(priority),
                            style: TextStyle(fontSize: 9, color: pColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status badge
              if (status == 'done')
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 16),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Create post bottom sheet — extracted for cleanliness
class _CreatePostSheet extends StatelessWidget {
  final TextEditingController controller;
  final bool isPosting;
  final VoidCallback onPost;

  const _CreatePostSheet({
    required this.controller,
    required this.isPosting,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            const Text(
              'Create Post',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Text field
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: controller,
                maxLines: 5,
                autofocus: true,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Share an update...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Actions row
            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.image_outlined,
                      color: AppColors.textSecondary, size: 24),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.attach_file,
                      color: AppColors.textSecondary, size: 24),
                ),
                const Spacer(),
                SizedBox(
                  width: 80,
                  height: 38,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: isPosting ? null : onPost,
                    child: isPosting
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : const Text('Post'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FeedItem — wrapper for type-safe merging of posts and task events
// ─────────────────────────────────────────────────────────────────────────────

class _FeedItem {
  final PostModel? post;
  final Map<String, dynamic>? taskData;
  final DateTime createdAt;

  _FeedItem.post(PostModel p)
      : post = p,
        taskData = null,
        createdAt = p.createdAt.toDate();

  _FeedItem.task(Map<String, dynamic> t)
      : post = null,
        taskData = t,
        createdAt = t['createdAt'] is Timestamp
            ? (t['createdAt'] as Timestamp).toDate()
            : DateTime(2000);

  bool get isTask => taskData != null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Unified Feed List — Posts + Task Events merged & sorted by createdAt
// ─────────────────────────────────────────────────────────────────────────────

class _UnifiedFeedList extends StatelessWidget {
  final GroupModel group;
  final bool isRefreshing;

  const _UnifiedFeedList({required this.group, required this.isRefreshing});

  DateTime _getTime(dynamic val) {
    if (val == null) return DateTime(2000);
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    return DateTime(2000);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PostModel>>(
      stream: FeedController.instance.getPosts(group.id),
      builder: (context, postSnap) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: TaskController.instance.getGroupFeed(group.id),
          builder: (context, taskSnap) {
            // Loading state
            if ((postSnap.connectionState == ConnectionState.waiting ||
                taskSnap.connectionState == ConnectionState.waiting) &&
                !isRefreshing) {
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (ctx, i) => const SkeletonPostCard(),
                  childCount: 3,
                ),
              );
            }

            final List<PostModel> posts = postSnap.data ?? [];
            final List<Map<String, dynamic>> taskEvents = taskSnap.data ?? [];

            // Unified list — wrapper class use karo type safety ke liye
            final List<_FeedItem> all = [
              ...posts.map((p) => _FeedItem.post(p)),
              ...taskEvents.map((t) => _FeedItem.task(t)),
            ];

            // createdAt se sort — latest pehle
            all.sort((a, b) => _getTime(b.createdAt).compareTo(_getTime(a.createdAt)));

            if (all.isEmpty) {
              return SliverToBoxAdapter(child: _buildEmptyFeed());
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                  final item = all[i];
                  if (item.isTask) {
                    return _FeedTaskCard(event: item.taskData!);
                  }
                  return PostCard(post: item.post!, groupId: group.id);
                },
                childCount: all.length,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyFeed() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: AppColors.accent, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'No activity yet',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Posts and tasks will appear here',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feed Task Event Card — "Fahad ne Ali ko task assign kiya"
// ─────────────────────────────────────────────────────────────────────────────

class _FeedTaskCard extends StatelessWidget {
  final Map<String, dynamic> event;

  const _FeedTaskCard({required this.event});

  Color _priorityColor(String p) {
    if (p == 'high') return AppColors.error;
    if (p == 'low') return AppColors.success;
    return AppColors.warning;
  }

  String _priorityLabel(String p) {
    if (p == 'high') return 'High';
    if (p == 'low') return 'Low';
    return 'Medium';
  }

  String _formatDate(dynamic val) {
    DateTime? d;
    if (val is Timestamp) d = val.toDate();
    if (val is DateTime) d = val;
    if (d == null) return '';
    final now = DateTime.now();
    if (d.day == now.day && d.month == now.month) return 'Today';
    if (d.difference(now).inDays == 1) return 'Tomorrow';
    return '${d.day}/${d.month}';
  }

  @override
  Widget build(BuildContext context) {
    final String assignerName = event['assignedByName']?.toString() ?? 'Someone';
    final String assigneeName = event['assignedToName']?.toString() ?? 'a member';
    final String taskTitle = event['taskTitle']?.toString() ?? 'Untitled Task';
    final String priority = event['priority']?.toString() ?? 'medium';
    final Color pColor = _priorityColor(priority);
    final String due = _formatDate(event['dueDate']);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: pColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.add_task_rounded, color: pColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Who assigned to whom
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      children: [
                        TextSpan(
                          text: assignerName,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(text: ' assigned a task to '),
                        TextSpan(
                          text: assigneeName,
                          style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Task title
                  Text(
                    taskTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),

                  // Priority + Due date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: pColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _priorityLabel(priority),
                          style: TextStyle(
                              fontSize: 10,
                              color: pColor,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (due.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.calendar_today_rounded,
                            size: 10, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          due,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
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
    );
  }
}