import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/task_model.dart';

/// TaskController — single source of truth for all task operations.
///
/// ✅ FIX (Manus Report #2): Tasks ab top-level 'tasks' collection ki
/// jagah 'groups/{groupId}/tasks' subcollection mein store honge.
/// Yeh TaskRepository ke saath consistent hai aur data siloing khatam karta hai.
///
/// Field naming standard:
///   assignedTo      → assignee UID
///   assignedToName  → assignee display name (denormalized)
///   assignedBy      → assigner UID
///   assignedByName  → assigner display name (denormalized)

class TaskController {
  static final TaskController _instance = TaskController._internal();
  static TaskController get instance => _instance;
  TaskController._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Collection path helper ─────────────────────────────────────────────────
  // ✅ FIX: har jagah ek hi path — groups/{groupId}/tasks
  CollectionReference<Map<String, dynamic>> _tasksRef(String groupId) =>
      _firestore.collection('groups').doc(groupId).collection('tasks');

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

    // Assigner naam fetch
    final userDoc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final assignerName = userDoc.data()?['name']?.toString() ?? 'Someone';

    // Assignee naam fetch
    final assigneeDoc = await _firestore
        .collection('users')
        .doc(assignedTo)
        .get();
    final assigneeName =
        assigneeDoc.data()?['name']?.toString() ?? 'Team Member';

    final WriteBatch batch = _firestore.batch();

    // ✅ FIX: 'groups/{groupId}/tasks' subcollection
    final taskRef = _tasksRef(groupId).doc();
    batch.set(taskRef, {
      'groupId'        : groupId,
      'title'          : title,
      'description'    : description,
      'assignedTo'     : assignedTo,
      'assignedToName' : assigneeName,
      'assignedBy'     : currentUser.uid,
      'assignedByName' : assignerName,
      'priority'       : priority,
      'status'         : status,
      // ✅ SKILL: FieldValue.serverTimestamp() — never DateTime.now()
      'dueDate'        : dueDate != null
          ? Timestamp.fromDate(dueDate)
          : null,
      'createdAt'      : FieldValue.serverTimestamp(),
      'updatedAt'      : FieldValue.serverTimestamp(),
    });

    // Feed event
    final feedRef = _firestore
        .collection('feed')
        .doc(groupId)
        .collection('items')
        .doc();
    batch.set(feedRef, {
      'type'           : 'task_assigned',
      'taskId'         : taskRef.id,
      'taskTitle'      : title,
      'priority'       : priority,
      'dueDate'        : dueDate != null ? Timestamp.fromDate(dueDate) : null,
      'assignedTo'     : assignedTo,
      'assignedToName' : assigneeName,
      'assignedBy'     : currentUser.uid,
      'assignedByName' : assignerName,
      'groupId'        : groupId,
      'createdAt'      : FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ─────────────────────────────────────────────
  // Get Group Tasks — Stream (UI ke liye)
  // ─────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getGroupTasks(String groupId) {
    return _tasksRef(groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data()};
    }).toList());
  }

  // ─────────────────────────────────────────────
  // Get Group Tasks — Future List (Gemini / AI ke liye)
  // ─────────────────────────────────────────────

  Future<List<TaskModel>> getGroupTasksList(String groupId) async {
    final snapshot = await _tasksRef(groupId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ─────────────────────────────────────────────
  // Get Single Task
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getTask(String groupId, String taskId) async {
    final doc = await _tasksRef(groupId).doc(taskId).get();
    if (!doc.exists) throw Exception('Task not found');

    final data = doc.data()!;

    // Agar naam pehle se saved hain — fast path
    if (data['assignedToName'] != null && data['assignedByName'] != null) {
      return {
        'id': doc.id,
        ...data,
        'assignedTo': {
          'id'   : data['assignedTo'],
          'name' : data['assignedToName'],
          'email': '',
        },
        'assignedBy': {
          'id'  : data['assignedBy'],
          'name': data['assignedByName'],
        },
      };
    }

    // Fallback — purane tasks ke liye user fetch
    final assigneeDoc = await _firestore
        .collection('users')
        .doc(data['assignedTo'])
        .get();
    final assignerDoc = await _firestore
        .collection('users')
        .doc(data['assignedBy'])
        .get();

    return {
      'id': doc.id,
      ...data,
      'assignedTo': {
        'id'   : assigneeDoc.id,
        'name' : assigneeDoc.data()?['name'] ?? 'Unknown',
        'email': assigneeDoc.data()?['email'] ?? '',
      },
      'assignedBy': {
        'id'  : assignerDoc.id,
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
        .map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // ─────────────────────────────────────────────
  // Update Task Status
  // ─────────────────────────────────────────────

  Future<void> updateTaskStatus(
      String groupId, String taskId, String newStatus) async {
    await _tasksRef(groupId).doc(taskId).update({
      'status'   : newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────
  // Update Task (generic)
  // ─────────────────────────────────────────────

  Future<void> updateTask(
      String groupId, String taskId, Map<String, dynamic> data) async {
    await _tasksRef(groupId).doc(taskId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────
  // Delete Task
  // ─────────────────────────────────────────────

  Future<void> deleteTask(String groupId, String taskId) async {
    await _tasksRef(groupId).doc(taskId).delete();
  }

  // ─────────────────────────────────────────────
  // Get My Tasks — current user ko assigned (Stream)
  // ─────────────────────────────────────────────

  /// ✅ FIX: Ab CollectionGroup query use kari — user ke saare groups mein
  /// se uske tasks ek hi stream mein milenge, collection path change ke baad bhi.
  Stream<List<Map<String, dynamic>>> getMyTasks() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    return _firestore
        .collectionGroup('tasks')
        .where('assignedTo', isEqualTo: currentUser.uid)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // ─────────────────────────────────────────────
  // Get Dashboard Stats — group ke liye summary
  // ─────────────────────────────────────────────

  Future<Map<String, int>> getGroupTaskStats(String groupId) async {
    final snapshot = await _tasksRef(groupId).get();
    final tasks = snapshot.docs.map((d) => d.data()).toList();

    return {
      'total'      : tasks.length,
      'todo'       : tasks.where((t) => t['status'] == 'todo').length,
      'inProgress' : tasks.where((t) => t['status'] == 'in_progress').length,
      'done'       : tasks.where((t) => t['status'] == 'done').length,
    };
  }
}