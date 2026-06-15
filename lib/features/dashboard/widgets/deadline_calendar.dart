import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';

class DeadlineCalendar extends StatelessWidget {
  final List<Map<String, dynamic>> deadlines;

  const DeadlineCalendar({super.key, required this.deadlines});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.add(Duration(days: i)));

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isToday = index == 0;
          final taskCount = deadlines.where((d) {
            final due = d['dueDate'];
            if (due == null) return false;
            final dueDate = (due as Timestamp).toDate();
            return dueDate.year == day.year &&
                dueDate.month == day.month &&
                dueDate.day == day.day;
          }).length;

          final isOverdue = day.isBefore(now) && !isToday;

          return GestureDetector(
            onTap: taskCount > 0
                ? () => _showDayTasks(context, day, taskCount)
                : null,
            child: Container(
              width: 56,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isToday
                    ? AppColors.accent
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOverdue
                      ? AppColors.error.withValues(alpha: 0.5)
                      : AppColors.border,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayName(day.weekday),
                    style: TextStyle(
                      fontSize: 10,
                      color: isToday
                          ? Colors.white70
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isToday
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (taskCount > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? AppColors.error
                            : isToday
                            ? Colors.white.withValues(alpha: 0.3)
                            : AppColors.accent
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$taskCount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isToday
                              ? Colors.white
                              : isOverdue
                              ? Colors.white
                              : AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _dayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  void _showDayTasks(
      BuildContext context, DateTime day, int count) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_dayName(day.weekday)}, ${day.day}/${day.month}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$count task(s) due',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}