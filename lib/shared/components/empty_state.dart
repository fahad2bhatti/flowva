import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_button.dart';

enum EmptyStateType {
  noGroups,
  noMessages,
  noTasks,
  noNotifications,
  noResults,
}

class FlowvaEmptyState extends StatelessWidget {
  final EmptyStateType type;
  final VoidCallback? onAction;

  const FlowvaEmptyState({
    super.key,
    required this.type,
    this.onAction,
  });

  _EmptyStateData get _data => switch (type) {
    EmptyStateType.noGroups => _EmptyStateData(
      icon: Icons.group_outlined,
      title: 'No groups yet',
      subtitle: 'Create or join a group to start collaborating',
      actionLabel: 'Create Group',
    ),
    EmptyStateType.noMessages => _EmptyStateData(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'No messages yet',
      subtitle: 'Be the first to say something!',
      actionLabel: null,
    ),
    EmptyStateType.noTasks => _EmptyStateData(
      icon: Icons.task_alt_rounded,
      title: 'No tasks yet',
      subtitle: 'Create a task to get your team started',
      actionLabel: 'Create Task',
    ),
    EmptyStateType.noNotifications => _EmptyStateData(
      icon: Icons.notifications_none_rounded,
      title: 'All caught up!',
      subtitle: 'No new notifications',
      actionLabel: null,
    ),
    EmptyStateType.noResults => _EmptyStateData(
      icon: Icons.search_off_rounded,
      title: 'No results found',
      subtitle: 'Try a different search term',
      actionLabel: null,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final data = _data;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              child: Icon(
                data.icon,
                size: 36,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              data.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              data.subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (data.actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FlowvaButton(
                label: data.actionLabel!,
                onPressed: onAction,
                variant: ButtonVariant.primary,
                size: ButtonSize.medium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyStateData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;

  const _EmptyStateData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
  });
}