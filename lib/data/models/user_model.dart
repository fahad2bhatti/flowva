import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String photoUrl;
  final String role;      // owner, manager, member, guest
  final Timestamp joinedAt;
  final List<String> groupIds;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl = '',
    this.role = 'member',
    required this.joinedAt,
    this.groupIds = const [],
  });

  // From Firestore
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? map['displayName'] ?? 'Unknown',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? map['photoURL'] ?? '',
      role: map['role'] ?? 'member',
      joinedAt: map['joinedAt'] ?? Timestamp.now(),
      groupIds: List<String>.from(map['groupIds'] ?? []),
    );
  }

  // To Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'role': role,
      'joinedAt': joinedAt,
      'groupIds': groupIds,
    };
  }

  // Copy with
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? role,
    Timestamp? joinedAt,
    List<String>? groupIds,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      groupIds: groupIds ?? this.groupIds,
    );
  }
}