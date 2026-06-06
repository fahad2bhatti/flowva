import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String color;
  final String ownerId;
  final String inviteCode;
  final int memberCount;
  final Timestamp createdAt;
  final Timestamp lastActive;

  const GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.ownerId,
    required this.inviteCode,
    required this.memberCount,
    required this.createdAt,
    required this.lastActive,
  });

  /// Create a GroupModel from a Firestore document snapshot.
  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      color: data['color'] as String? ?? '#00D4AA',
      ownerId: data['ownerId'] as String? ?? '',
      inviteCode: data['inviteCode'] as String? ?? '',
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 1,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      lastActive: data['lastActive'] as Timestamp? ?? Timestamp.now(),
    );
  }

  /// Serialize this model to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'color': color,
      'ownerId': ownerId,
      'inviteCode': inviteCode,
      'memberCount': memberCount,
      'createdAt': createdAt,
      'lastActive': lastActive,
    };
  }

  /// Returns a copy of this model with the given fields replaced.
  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    String? ownerId,
    String? inviteCode,
    int? memberCount,
    Timestamp? createdAt,
    Timestamp? lastActive,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      ownerId: ownerId ?? this.ownerId,
      inviteCode: inviteCode ?? this.inviteCode,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}

