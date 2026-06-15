import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/avatar_widget.dart';

class MemberProgressBar extends StatelessWidget {
  final String memberName;
  final String? photoUrl;
  final int completed;
  final int total;

  const MemberProgressBar({
    super.key,
    required this.memberName,
    this.photoUrl,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : completed / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          FlowvaAvatar(
            name: memberName,
            imageUrl: photoUrl,
            size: AvatarSize.sm,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      memberName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$completed/$total',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor:
                    AppColors.border.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percent >= 0.8
                          ? AppColors.success
                          : percent >= 0.5
                          ? AppColors.accent
                          : AppColors.warning,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${(percent * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: percent >= 0.8
                  ? AppColors.success
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}