import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskController {
  static final TaskController _instance = TaskController._internal();
  static TaskController get instance => _instance;
  TaskController._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─────────────────────────────────────────────
  // Create Task + Feed Event (Batch Write)
  // ─────────────────────────────────────────────

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

    // Current user ka naam fetch karo (feed mein dikhane ke liye)
    final userDoc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final assignerName = userDoc.data()?['name']?.toString() ?? 'Someone';

    // Assignee ka naam bhi fetch karo
    final assigneeDoc = await _firestore
        .collection('users')
        .doc(assignedTo)
        .get();
    final assigneeName = assigneeDoc.data()?['name']?.toString() ?? 'Team Member';

    // Batch write — ek hi Firestore call
    final WriteBatch batch = _firestore.batch();

    // 1. Task document
    final taskRef = _firestore.collection('tasks').doc();
    batch.set(taskRef, {
      'groupId': groupId,
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'assignedToName': assigneeName,   // naam bhi save karo
      'assignedBy': currentUser.uid,
      'assignedByName': assignerName,   // naam bhi save karo
      'priority': priority,
      'status': status,
      'dueDate': dueDate,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Feed event document
    final feedRef = _firestore
        .collection('feed')
        .doc(groupId)
        .collection('items')
        .doc();
    batch.set(feedRef, {
      'type': 'task_assigned',
      'taskId': taskRef.id,
      'taskTitle': title,
      'priority': priority,
      'dueDate': dueDate,
      'assignedTo': assignedTo,
      'assignedToName': assigneeName,
      'assignedBy': currentUser.uid,
      'assignedByName': assignerName,
      'groupId': groupId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Dono ek saath save
    await batch.commit();
  }

  // ─────────────────────────────────────────────
  // Get Tasks for a Group
  // ─────────────────────────────────────────────

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

  // ─────────────────────────────────────────────
  // Get Single Task (with user names)
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getTask(String taskId) async {
    final doc = await _firestore.collection('tasks').doc(taskId).get();
    if (!doc.exists) throw Exception('Task not found');

    final taskData = doc.data()!;

    // Agar assignedToName already saved hai toh user fetch na karo (faster)
    if (taskData['assignedToName'] != null && taskData['assignedByName'] != null) {
      return {
        'id': doc.id,
        ...taskData,
        'assignedTo': {
          'id': taskData['assignedTo'],
          'name': taskData['assignedToName'],
          'email': '',
        },
        'assignedBy': {
          'id': taskData['assignedBy'],
          'name': taskData['assignedByName'],
        },
      };
    }

    // Purane tasks ke liye (naam nahi saved) — user fetch karo
    final assigneeDoc = await _firestore
        .collection('users')
        .doc(taskData['assignedTo'])
        .get();
    final assignerDoc = await _firestore
        .collection('users')
        .doc(taskData['assignedBy'])
        .get();

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

  // ─────────────────────────────────────────────
  // Get Feed Items for a Group
  // ─────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getGroupFeed(String groupId) {
    return _firestore
        .collection('feed')
        .doc(groupId)
        .collection('items')
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

  // ─────────────────────────────────────────────
  // Update Task Status
  // ─────────────────────────────────────────────

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────
  // Update Task
  // ─────────────────────────────────────────────

  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    await _firestore.collection('tasks').doc(taskId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────
  // Delete Task
  // ─────────────────────────────────────────────

  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
  }

  // ─────────────────────────────────────────────
  // Get Tasks Assigned to Current User
  // ─────────────────────────────────────────────

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