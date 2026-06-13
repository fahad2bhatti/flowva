import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';

class TaskRepository {
  static final TaskRepository instance = TaskRepository._internal();
  TaskRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // ─────────────────────────────────────────────
  // Create Task
  // ─────────────────────────────────────────────

  Future<bool> createTask(String groupId, TaskModel task) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('tasks')
          .add(task.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Get Tasks Stream
  // ─────────────────────────────────────────────

  Stream<List<TaskModel>> getTasks(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // ─────────────────────────────────────────────
  // Get My Tasks
  // ─────────────────────────────────────────────

  Stream<List<TaskModel>> getMyTasks() {
    return _firestore
        .collectionGroup('tasks')
        .where('assigneeId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // ─────────────────────────────────────────────
  // Update Task Status
  // ─────────────────────────────────────────────

  Future<bool> updateTaskStatus(
      String groupId, String taskId, String status) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('tasks')
          .doc(taskId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Assign Task
  // ─────────────────────────────────────────────

  Future<bool> assignTask(
      String groupId, String taskId, String assigneeId) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('tasks')
          .doc(taskId)
          .update({
        'assigneeId': assigneeId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Delete Task
  // ─────────────────────────────────────────────

  Future<bool> deleteTask(String groupId, String taskId) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('tasks')
          .doc(taskId)
          .delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}