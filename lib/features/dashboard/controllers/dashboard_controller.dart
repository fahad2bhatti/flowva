import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DashboardController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;
  String selectedRange = 'This Week';

  // Summary
  int tasksDone = 0;
  int tasksInProgress = 0;
  int tasksOverdue = 0;
  int membersActive = 0;

  // Chart data
  Map<String, int> memberWorkload = {};
  List<Map<String, dynamic>> upcomingDeadlines = [];
  Set<dynamic> recentActivity = {};
  int streak = 0;

  String? _groupId;

  Future<void> loadDashboard(String groupId) async {
    _groupId = groupId;
    isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadTaskSummary(groupId),
        _loadMemberWorkload(groupId),
        _loadUpcomingDeadlines(groupId),
        _loadStreak(groupId),
        _loadMembersActive(groupId),
      ]);
    } catch (e) {
      debugPrint('Dashboard error: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadTaskSummary(String groupId) async {
    final snap = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('tasks')
        .get();

    final now = DateTime.now();
    int done = 0, inProgress = 0, overdue = 0;

    for (final doc in snap.docs) {
      final data = doc.data();
      final status = data['status'] as String? ?? '';
      final dueDate = data['dueDate'];

      if (status == 'done' || status == 'completed') {
        done++;
      } else if (status == 'in_progress') {
        inProgress++;
        if (dueDate != null) {
          final due = (dueDate as Timestamp).toDate();
          if (due.isBefore(now)) overdue++;
        }
      } else {
        if (dueDate != null) {
          final due = (dueDate as Timestamp).toDate();
          if (due.isBefore(now)) overdue++;
        }
      }
    }

    tasksDone = done;
    tasksInProgress = inProgress;
    tasksOverdue = overdue;
  }

  Future<void> _loadMemberWorkload(String groupId) async {
    final snap = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('tasks')
        .where('assigneeId', isNull: false)
        .get();

    final workload = <String, int>{};
    for (final doc in snap.docs) {
      final name = doc.data()['assigneeName'] as String? ?? 'Unknown';
      workload[name] = (workload[name] ?? 0) + 1;
    }
    memberWorkload = workload;
  }

  Future<void> _loadUpcomingDeadlines(String groupId) async {
    final now = Timestamp.now();
    final snap = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('tasks')
        .where('dueDate', isGreaterThan: now)
        .orderBy('dueDate')
        .limit(5)
        .get();

    upcomingDeadlines = snap.docs.map((doc) {
      final data = doc.data();
      return {
        'title': data['title'] ?? 'Untitled',
        'dueDate': data['dueDate'],
        'status': data['status'] ?? 'todo',
        'assigneeName': data['assigneeName'] ?? '',
      };
    }).toList();
  }

  Future<void> _loadStreak(String groupId) async {
    final now = DateTime.now();
    int currentStreak = 0;

    for (int i = 0; i < 30; i++) {
      final day = now.subtract(Duration(days: i));
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));

      final snap = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('tasks')
          .where('status', isEqualTo: 'done')
          .where('updatedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('updatedAt',
          isLessThan: Timestamp.fromDate(end))
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        currentStreak++;
      } else if (i > 0) {
        break;
      }
    }
    streak = currentStreak;
  }

  Future<void> _loadMembersActive(String groupId) async {
    final since = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(hours: 24)));
    final snap = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .get();

    int active = 0;
    for (final doc in snap.docs) {
      final userDoc = await _firestore
          .collection('users')
          .doc(doc.id)
          .get();
      final lastActive =
      userDoc.data()?['lastActive'] as Timestamp?;
      if (lastActive != null &&
          lastActive.compareTo(since) > 0) {
        active++;
      }
    }
    membersActive = active;
  }

  void setRange(String range) {
    selectedRange = range;
    if (_groupId != null) loadDashboard(_groupId!);
  }
}