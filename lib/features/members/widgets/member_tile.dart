import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../../../core/constants/app_colors.dart';

class MemberTile extends StatelessWidget {
  final UserModel user;
  final String role;
  final bool isCurrentUser;
  final bool canManage;
  final void Function(String newRole)? onRoleChange;
  final VoidCallback? onRemove;

  const MemberTile({
    super.key,
    required this.user,
    required this.role,
    this.isCurrentUser = false,
    this.canManage = false,
    this.onRoleChange,
    this.onRemove,
  });

  Color _getRoleColor(String role) {
    return switch (role) {
      'owner'  => const Color(0xFFFF6B6B),
      'admin'  => const Color(0xFFFFB347),
      'member' => AppColors.accent,
      _        => AppColors.textMuted,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: canManage ? () => _showManageSheet(context) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            // Avatar
            FlowvaAvatar(
              imageUrl: user.photoUrl.isNotEmpty ? user.photoUrl : null,
              name: user.name,
              size: AvatarSize.md,
              isOnline: user.isOnline,
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.name + (isCurrentUser ? ' (You)' : ''),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: AppColors.accent,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.jobRole.isNotEmpty
                        ? user.jobRole
                        : '@${user.username}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (user.skills.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: user.skills
                          .take(2)
                          .map((skill) => Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          skill,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleColor(role).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getRoleColor(role).withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Text(
                role[0].toUpperCase() + role.substring(1),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _getRoleColor(role),
                ),
              ),
            ),

            if (canManage) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showManageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FlowvaAvatar(name: user.name, size: AvatarSize.sm),
                const SizedBox(width: 10),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Change Role',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _RoleOption(
              label: 'Make Admin',
              icon: Icons.admin_panel_settings_outlined,
              color: const Color(0xFFFFB347),
              onTap: () {
                Navigator.pop(context);
                onRoleChange?.call('admin');
              },
            ),
            _RoleOption(
              label: 'Make Member',
              icon: Icons.person_outline_rounded,
              color: AppColors.accent,
              onTap: () {
                Navigator.pop(context);
                onRoleChange?.call('member');
              },
            ),
            const Divider(color: AppColors.border, height: 24),
            _RoleOption(
              label: 'Remove from Group',
              icon: Icons.person_remove_outlined,
              color: AppColors.error,
              onTap: () {
                Navigator.pop(context);
                onRemove?.call();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}