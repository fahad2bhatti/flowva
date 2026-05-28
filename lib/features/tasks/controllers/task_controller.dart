import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskController {
  static final TaskController _instance = TaskController._internal();
  static TaskController get instance => _instance;
  TaskController._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create Task
  Future<void> createTask({
    required String groupId,
    required String title,
    required String description,
    required String assignedTo,
    required String priority,
    required DateTime? dueDate,
    required String status,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    final taskData = {
      'groupId': groupId,
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'assignedBy': currentUser.uid,
      'priority': priority,
      'status': status,
      'dueDate': dueDate ?? null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('tasks').add(taskData);
  }

  // Get Tasks for a Group
  Stream<List<Map<String, dynamic>>> getGroupTasks(String groupId) {
    return _firestore
        .collection('tasks')
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  // Get Single Task
  Future<Map<String, dynamic>> getTask(String taskId) async {
    final doc = await _firestore.collection('tasks').doc(taskId).get();
    if (!doc.exists) throw Exception('Task not found');

    // Fetch assignee name
    final taskData = doc.data()!;
    final assigneeDoc = await _firestore.collection('users').doc(taskData['assignedTo']).get();
    final assignerDoc = await _firestore.collection('users').doc(taskData['assignedBy']).get();

    return {
      'id': doc.id,
      ...taskData,
      'assignedTo': {
        'id': assigneeDoc.id,
        'name': assigneeDoc.data()?['name'] ?? 'Unknown',
        'email': assigneeDoc.data()?['email'] ?? '',
      },
      'assignedBy': {
        'id': assignerDoc.id,
        'name': assignerDoc.data()?['name'] ?? 'Unknown',
      },
    };
  }

  // Update Task Status
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update Task
  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    await _firestore.collection('tasks').doc(taskId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete Task
  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
  }

  // Get Tasks Assigned to Current User
  Stream<List<Map<String, dynamic>>> getMyTasks() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    return _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: currentUser.uid)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }
}