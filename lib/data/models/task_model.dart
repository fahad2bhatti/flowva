import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String groupId;
  final String title;
  final String description;
  final String assignedTo;
  final String assignedToName;
  final String assignedBy;
  final String assignedByName;
  final String priority;
  final String status;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskModel({
    required this.id,
    required this.groupId,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.assignedToName,
    required this.assignedBy,
    required this.assignedByName,
    required this.priority,
    required this.status,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskModel(
      id: id,
      groupId: map['groupId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      assignedTo: map['assignedTo'] ?? '',
      assignedToName: map['assignedToName'] ?? '',
      assignedBy: map['assignedBy'] ?? '',
      assignedByName: map['assignedByName'] ?? '',
      priority: map['priority'] ?? 'medium',
      status: map['status'] ?? 'todo',
      dueDate: (map['dueDate'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'assignedBy': assignedBy,
      'assignedByName': assignedByName,
      'priority': priority,
      'status': status,
      'dueDate': dueDate,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  TaskModel copyWith({
    String? status,
    String? priority,
  }) {
    return TaskModel(
      id: id,
      groupId: groupId,
      title: title,
      description: description,
      assignedTo: assignedTo,
      assignedToName: assignedToName,
      assignedBy: assignedBy,
      assignedByName: assignedByName,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

