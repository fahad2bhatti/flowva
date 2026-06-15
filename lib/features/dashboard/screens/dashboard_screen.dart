import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/workload_chart.dart';
import '../widgets/deadline_calendar.dart';
import '../../../shared/components/empty_state.dart';
import '../../../core/constants/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  final String groupId;

  const DashboardScreen({super.key, required this.groupId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DashboardController();
    _controller.loadDashboard(widget.groupId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<DashboardController>(
        builder: (context, ctrl, _) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: _buildAppBar(ctrl),
            body: ctrl.isLoading
                ? _buildShimmer()
                : RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.surface,
              onRefresh: () =>
                  ctrl.loadDashboard(widget.groupId),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary cards
                  _buildSummaryCards(ctrl),
                  const SizedBox(height: 24),

                  // Streak
                  if (ctrl.streak > 0) ...[
                    _buildStreakCard(ctrl.streak),
                    const SizedBox(height: 24),
                  ],

                  // Workload chart
                  _buildSection(
                    title: 'Member workload',
                    child: WorkloadChart(
                        data: ctrl.memberWorkload),
                  ),
                  const SizedBox(height: 24),

                  // Deadline calendar
                  _buildSection(
                    title: 'Upcoming deadlines',
                    child: DeadlineCalendar(
                        deadlines: ctrl.upcomingDeadlines),
                  ),
                  const SizedBox(height: 24),

                  // Upcoming tasks list
                  _buildSection(
                    title: 'Due soon',
                    child: ctrl.upcomingDeadlines.isEmpty
                        ? FlowvaEmptyState(
                        type: EmptyStateType.noTasks)
                        : Column(
                      children: ctrl.upcomingDeadlines
                          .map((t) =>
                          _buildTaskRow(t))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(DashboardController ctrl) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      title: const Text(
        'Dashboard',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      actions: [
        PopupMenuButton<String>(
          color: AppColors.surface,
          icon: const Icon(Icons.tune_rounded,
              color: AppColors.textSecondary),
          onSelected: ctrl.setRange,
          itemBuilder: (_) => [
            'This Week',
            'This Month',
            'All Time',
          ]
              .map((r) => PopupMenuItem(
            value: r,
            child: Text(r,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13)),
          ))
              .toList(),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  Widget _buildSummaryCards(DashboardController ctrl) {
    return Row(
      children: [
        _buildSummaryCard('Done', ctrl.tasksDone,
            Icons.check_circle_rounded, AppColors.success),
        const SizedBox(width: 8),
        _buildSummaryCard('In Progress', ctrl.tasksInProgress,
            Icons.pending_rounded, AppColors.warning),
        const SizedBox(width: 8),
        _buildSummaryCard('Overdue', ctrl.tasksOverdue,
            Icons.warning_rounded, AppColors.error),
        const SizedBox(width: 8),
        _buildSummaryCard('Active', ctrl.membersActive,
            Icons.people_rounded, AppColors.accent),
      ],
    );
  }

  Widget _buildSummaryCard(
      String label, int value, IconData icon, Color color) {
    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.toDouble()),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOut,
        builder: (_, val, _) => Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                '${val.toInt()}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard(int streak) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$streak day streak!',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                'Keep completing tasks to maintain it',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      {required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildTaskRow(Map<String, dynamic> task) {
    final due = task['dueDate'];
    String dueText = '';
    if (due != null) {
      final date = (due as dynamic).toDate() as DateTime;
      final diff = date.difference(DateTime.now()).inDays;
      dueText = diff == 0
          ? 'Today'
          : diff == 1
          ? 'Tomorrow'
          : 'In $diff days';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task['title'] ?? 'Untitled',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            dueText,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, _) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}