import 'package:flutter/material.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';
import '../widgets/notification_tile.dart';
import '../../../shared/components/empty_state.dart';
import '../../../core/constants/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationRepository _repo = NotificationRepository.instance;
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All', 'Messages', 'Tasks', 'Mentions'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(child: _buildNotificationsList()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      title: const Text(
        'Notifications',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      actions: [
        TextButton(
          onPressed: _markAllRead,
          child: const Text(
            'Mark all read',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 13,
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.border,
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _repo.getNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmer();
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Error loading notifications',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        final rawList = snapshot.data ?? [];

        // Convert to NotificationModel
        final notifications = rawList.map((map) {
          final id = map['id'] as String;
          final rest = Map<String, dynamic>.from(map)..remove('id');
          return NotificationModel.fromMap(rest, id);
        }).toList();

        // Filter
        final filtered = _filterNotifications(notifications);

        if (filtered.isEmpty) {
          return FlowvaEmptyState(
            type: EmptyStateType.noNotifications,
          );
        }

        // Group by date
        final today = <NotificationModel>[];
        final yesterday = <NotificationModel>[];
        final older = <NotificationModel>[];

        final now = DateTime.now();
        for (final n in filtered) {
          final date = n.timestamp.toDate();
          final diff = now.difference(date);
          if (diff.inDays == 0) {
            today.add(n);
          } else if (diff.inDays == 1) {
            yesterday.add(n);
          } else {
            older.add(n);
          }
        }

        return ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
          children: [
            if (today.isNotEmpty) ...[
              _buildDateHeader('Today'),
              ...today.map((n) => _buildTile(n)),
            ],
            if (yesterday.isNotEmpty) ...[
              _buildDateHeader('Yesterday'),
              ...yesterday.map((n) => _buildTile(n)),
            ],
            if (older.isNotEmpty) ...[
              _buildDateHeader('Earlier'),
              ...older.map((n) => _buildTile(n)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTile(NotificationModel n) {
    return NotificationTile(
      notification: n,
      onTap: () => _handleTap(n),
      onDismiss: () => _handleDismiss(n),
    );
  }

  List<NotificationModel> _filterNotifications(
      List<NotificationModel> list) {
    return switch (_selectedFilter) {
      'Messages' => list
          .where((n) => n.type == NotificationType.newMessage)
          .toList(),
      'Tasks' => list
          .where((n) =>
      n.type == NotificationType.taskAssigned ||
          n.type == NotificationType.taskCompleted)
          .toList(),
      'Mentions' => list
          .where((n) => n.type == NotificationType.mention)
          .toList(),
      _ => list,
    };
  }

  Future<void> _handleTap(NotificationModel n) async {
    await _repo.markAsRead(n.id);
    // Navigation baad mein GoRouter se add karein
  }

  Future<void> _handleDismiss(NotificationModel n) async {
    await _repo.deleteNotification(n.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notification removed'),
        backgroundColor: AppColors.surface,
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.accent,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _markAllRead() async {
    await _repo.markAllAsRead();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8),
      itemCount: 6,
      itemBuilder: (_, _) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}