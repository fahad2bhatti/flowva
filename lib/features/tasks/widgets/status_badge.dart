import 'package:flutter/material.dart';
import 'package:flowva/core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String size;

  const StatusBadge({
    super.key,
    required this.status,
    this.size = 'small',
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'todo':
        bgColor = AppColors.textMuted.withValues(alpha: 0.15);
        textColor = AppColors.textSecondary;
        label = 'To Do';
        icon = Icons.circle_outlined;
        break;
      case 'in_progress':
        bgColor = AppColors.warning.withValues(alpha: 0.15);
        textColor = AppColors.warning;
        label = 'In Progress';
        icon = Icons.hourglass_empty_rounded;
        break;
      case 'done':
        bgColor = AppColors.success.withValues(alpha: 0.15);
        textColor = AppColors.success;
        label = 'Done';
        icon = Icons.check_circle_rounded;
        break;
      default:
        bgColor = AppColors.surface;
        textColor = AppColors.textSecondary;
        label = status;
        icon = Icons.help_outline;
    }

    double fontSize;
    double padding;

    switch (size) {
      case 'small':
        fontSize = 10;
        padding = 6;
        break;
      case 'medium':
        fontSize = 12;
        padding = 8;
        break;
      case 'large':
        fontSize = 14;
        padding = 10;
        break;
      default:
        fontSize = 10;
        padding = 6;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding - 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: fontSize + 2),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

