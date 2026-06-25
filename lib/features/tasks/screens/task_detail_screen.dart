import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flowva/core/constants/app_colors.dart';
import 'package:flowva/features/tasks/controllers/task_controller.dart';
import 'package:flowva/features/tasks/widgets/priority_badge.dart';

class TaskDetailScreen extends StatefulWidget {
  final String? taskId;
  // ✅ FIX: groupId add kiya — TaskController ab groupId bhi maangta hai
  final String? groupId;

  const TaskDetailScreen({
    super.key,
    this.taskId,
    this.groupId, // ✅ added
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _task;
  String? _error;

  final List<String> _statuses = ['todo', 'in_progress', 'done'];

  // ─────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (widget.taskId != null && widget.groupId != null) {
      _loadTask();
    } else {
      // Demo task
      _task = {
        'title'      : 'Fix login API integration',
        'description': 'The login endpoint is returning 500 error.',
        'priority'   : 'high',
        'status'     : 'in_progress',
        'dueDate'    : DateTime.now().add(const Duration(days: 1)),
        'assignedTo'     : 'demoUserId123',
        'assignedToName' : 'Demo User',
        'assignedBy'     : 'demoUserId456',
        'assignedByName' : 'Admin',
        'createdAt'  : DateTime.now(),
      };
      setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  String _formatDate(dynamic value) {
    final date = _parseDate(value);
    if (date == null) return 'No date';
    return '${date.day}/${date.month}/${date.year}';
  }

  // ✅ FIX: assignedToName / assignedByName ab directly task mein saved hain
  // (TaskController denormalize karta hai) — simple string read
  String _extractName(dynamic uid, String fallbackKey) {
    // Check denormalized name field pehle
    final name = _task?[fallbackKey]?.toString();
    if (name != null && name.isNotEmpty) return name;
    // Agar Map ho (purana format)
    if (uid is Map) return uid['name']?.toString() ?? 'Unknown';
    return 'Unknown';
  }

  String _extractEmail(dynamic value) {
    if (value is Map) return value['email']?.toString() ?? '';
    return '';
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'todo'       : return 'To Do';
      case 'in_progress': return 'In Progress';
      case 'done'       : return 'Done';
      default           : return status;
    }
  }

  // ─────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────

  Future<void> _loadTask() async {
    try {
      // ✅ FIX: groupId pass kiya — was missing before
      final task = await TaskController.instance.getTask(
        widget.groupId!,
        widget.taskId!,
      );
      setState(() {
        _task     = task;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error     = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (widget.taskId == null || widget.groupId == null) return;
    setState(() => _isLoading = true);
    try {
      // ✅ FIX: groupId + taskId + status — was missing groupId before
      await TaskController.instance.updateTaskStatus(
        widget.groupId!,
        widget.taskId!,
        newStatus,
      );
      setState(() {
        _task?['status'] = newStatus;
        _isLoading       = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task status updated'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Task Details'),
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textSecondary),
            onPressed: () => context.canPop() ? context.pop() : null,
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(_error!,
                  style: const TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Task Details',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textSecondary),
          onPressed: () => context.canPop() ? context.pop() : null,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusSelector(),
            const SizedBox(height: 24),
            _buildTitle(),
            const SizedBox(height: 20),
            _buildPriorityAndDueDate(),
            const SizedBox(height: 20),
            const Divider(color: AppColors.border),
            const SizedBox(height: 20),
            _buildDescription(),
            const SizedBox(height: 20),
            _buildAssigneeCard(),
            const SizedBox(height: 20),
            _buildCreatedBy(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Sections
  // ─────────────────────────────────────────────

  Widget _buildStatusSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: _statuses.map((status) {
          final isSelected = _task!['status'] == status;
          return Expanded(
            child: GestureDetector(
              onTap: () => _updateStatus(status),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(
                  _getStatusText(status),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Task Title',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(
          _task!['title']?.toString() ?? 'Untitled',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityAndDueDate() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Priority',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              PriorityBadge(
                priority: _task!['priority']?.toString() ?? 'medium',
                size: 'medium',
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Due Date',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    _task!['dueDate'] != null
                        ? _formatDate(_task!['dueDate'])
                        : 'No due date',
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Description',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            _task!['description']?.toString() ?? 'No description provided',
            style: const TextStyle(
                color: AppColors.textPrimary, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildAssigneeCard() {
    // ✅ FIX: denormalized 'assignedToName' directly use karo
    final String name    = _extractName(_task!['assignedTo'], 'assignedToName');
    final String email   = _extractEmail(_task!['assignedTo']);
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'T';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Assigned To',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
                Text(name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
                if (email.isNotEmpty)
                  Text(email,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatedBy() {
    // ✅ FIX: denormalized 'assignedByName' use karo
    final String creatorName =
    _extractName(_task!['assignedBy'], 'assignedByName');

    return Row(
      children: [
        const Icon(Icons.person_outline,
            size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(
          'Created by $creatorName',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const Spacer(),
        Text(
          _formatDate(_task!['createdAt']),
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}