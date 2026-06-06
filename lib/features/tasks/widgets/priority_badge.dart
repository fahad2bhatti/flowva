import 'package:flutter/material.dart';
import 'package:flowva/core/constants/app_colors.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;
  final String size; // small, medium, large

  const PriorityBadge({
    super.key,
    required this.priority,
    this.size = 'small',
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    switch (priority.toLowerCase()) {
      case 'high':
        bgColor = AppColors.error.withValues(alpha: 0.15);
        textColor = AppColors.error;
        label = '🔴 High';
        break;
      case 'medium':
        bgColor = AppColors.warning.withValues(alpha: 0.15);
        textColor = AppColors.warning;
        label = '🟡 Medium';
        break;
      case 'low':
        bgColor = AppColors.success.withValues(alpha: 0.15);
        textColor = AppColors.success;
        label = '🟢 Low';
        break;
      default:
        bgColor = AppColors.surface;
        textColor = AppColors.textSecondary;
        label = '⚪ Normal';
    }

    double fontSize;
    double horizontalPadding;
    double verticalPadding;

    switch (size) {
      case 'small':
        fontSize = 10;
        horizontalPadding = 8;
        verticalPadding = 3;
        break;
      case 'medium':
        fontSize = 12;
        horizontalPadding = 12;
        verticalPadding = 5;
        break;
      case 'large':
        fontSize = 14;
        horizontalPadding = 16;
        verticalPadding = 7;
        break;
      default:
        fontSize = 10;
        horizontalPadding = 8;
        verticalPadding = 3;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

