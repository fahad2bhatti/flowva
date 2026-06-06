import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  // ─────────────────────────────────────────────
  // Core Fields
  // ─────────────────────────────────────────────
  final String id;
  final String name;
  final String username;
  final String email;
  final String photoUrl;
  final String coverPhotoUrl;
  final String bio;

  // ─────────────────────────────────────────────
  // Professional Info
  // ─────────────────────────────────────────────
  final String role;           // owner, manager, member, guest (group role)
  final String jobRole;        // Developer, Designer, Manager, etc.
  final String experienceLevel; // Junior, Mid, Senior, Lead
  final List<String> skills;   // ['Flutter', 'Firebase', 'UI/UX']
  final List<String> interests; // ['#Coding', '#Gym', '#AI']
  final List<String> languages; // ['English', 'Urdu']

  // ─────────────────────────────────────────────
  // Activity & Status
  // ─────────────────────────────────────────────
  final String currentStatus;  // "Working on Flowva 🚀"
  final bool isOnline;
  final Timestamp lastActive;
  final Timestamp joinedAt;
  final Timestamp createdAt;

  // ─────────────────────────────────────────────
  // Social
  // ─────────────────────────────────────────────
  final List<String> followers;
  final List<String> following;
  final List<String> groupIds;

  // ─────────────────────────────────────────────
  // Featured & Achievements
  // ─────────────────────────────────────────────
  final List<Map<String, dynamic>> featuredItems; // [{type, title, url}]
  final List<String> badges;                       // ['early_adopter', 'top_contributor']

  // ─────────────────────────────────────────────
  // Trust & Completion
  // ─────────────────────────────────────────────
  final bool isVerified;
  final int profileCompletion; // 0-100

  UserModel({
    required this.id,
    required this.name,
    this.username = '',
    required this.email,
    this.photoUrl = '',
    this.coverPhotoUrl = '',
    this.bio = '',
    this.role = 'member',
    this.jobRole = '',
    this.experienceLevel = '',
    this.skills = const [],
    this.interests = const [],
    this.languages = const [],
    this.currentStatus = '',
    this.isOnline = false,
    required this.lastActive,
    required this.joinedAt,
    required this.createdAt,
    this.followers = const [],
    this.following = const [],
    this.groupIds = const [],
    this.featuredItems = const [],
    this.badges = const [],
    this.isVerified = false,
    this.profileCompletion = 0,
  });

  // ─────────────────────────────────────────────
  // Computed Properties
  // ─────────────────────────────────────────────

  int get followerCount => followers.length;
  int get followingCount => following.length;
  int get groupCount => groupIds.length;
  int get badgeCount => badges.length;

  bool get hasPhoto => photoUrl.isNotEmpty;
  bool get hasCover => coverPhotoUrl.isNotEmpty;
  bool get hasBio => bio.isNotEmpty;

  /// Calculate profile completion %
  int calculateCompletion() {
    int score = 0;
    if (name.isNotEmpty) score += 15;
    if (username.isNotEmpty) score += 15;
    if (bio.isNotEmpty) score += 15;
    if (photoUrl.isNotEmpty) score += 15;
    if (coverPhotoUrl.isNotEmpty) score += 10;
    if (jobRole.isNotEmpty) score += 10;
    if (skills.isNotEmpty) score += 10;
    if (interests.isNotEmpty) score += 5;
    if (currentStatus.isNotEmpty) score += 5;
    return score;
  }

  // ─────────────────────────────────────────────
  // From Firestore
  // ─────────────────────────────────────────────

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    final now = Timestamp.now();
    return UserModel(
      id: id,
      name: map['name'] ?? map['displayName'] ?? 'Unknown',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? map['photoURL'] ?? '',
      coverPhotoUrl: map['coverPhotoUrl'] ?? '',
      bio: map['bio'] ?? '',
      role: map['role'] ?? 'member',
      jobRole: map['jobRole'] ?? '',
      experienceLevel: map['experienceLevel'] ?? '',
      skills: List<String>.from(map['skills'] ?? []),
      interests: List<String>.from(map['interests'] ?? []),
      languages: List<String>.from(map['languages'] ?? []),
      currentStatus: map['currentStatus'] ?? '',
      isOnline: map['isOnline'] ?? false,
      lastActive: map['lastActive'] ?? now,
      joinedAt: map['joinedAt'] ?? now,
      createdAt: map['createdAt'] ?? now,
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
      groupIds: List<String>.from(map['groupIds'] ?? []),
      featuredItems: List<Map<String, dynamic>>.from(map['featuredItems'] ?? []),
      badges: List<String>.from(map['badges'] ?? []),
      isVerified: map['isVerified'] ?? false,
      profileCompletion: map['profileCompletion'] ?? 0,
    );
  }

  // ─────────────────────────────────────────────
  // To Firestore
  // ─────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'email': email,
      'photoUrl': photoUrl,
      'coverPhotoUrl': coverPhotoUrl,
      'bio': bio,
      'role': role,
      'jobRole': jobRole,
      'experienceLevel': experienceLevel,
      'skills': skills,
      'interests': interests,
      'languages': languages,
      'currentStatus': currentStatus,
      'isOnline': isOnline,
      'lastActive': lastActive,
      'joinedAt': joinedAt,
      'createdAt': createdAt,
      'followers': followers,
      'following': following,
      'groupIds': groupIds,
      'featuredItems': featuredItems,
      'badges': badges,
      'isVerified': isVerified,
      'profileCompletion': calculateCompletion(),
    };
  }

  // ─────────────────────────────────────────────
  // Copy With
  // ─────────────────────────────────────────────

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? photoUrl,
    String? coverPhotoUrl,
    String? bio,
    String? role,
    String? jobRole,
    String? experienceLevel,
    List<String>? skills,
    List<String>? interests,
    List<String>? languages,
    String? currentStatus,
    bool? isOnline,
    Timestamp? lastActive,
    Timestamp? joinedAt,
    Timestamp? createdAt,
    List<String>? followers,
    List<String>? following,
    List<String>? groupIds,
    List<Map<String, dynamic>>? featuredItems,
    List<String>? badges,
    bool? isVerified,
    int? profileCompletion,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      jobRole: jobRole ?? this.jobRole,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      skills: skills ?? this.skills,
      interests: interests ?? this.interests,
      languages: languages ?? this.languages,
      currentStatus: currentStatus ?? this.currentStatus,
      isOnline: isOnline ?? this.isOnline,
      lastActive: lastActive ?? this.lastActive,
      joinedAt: joinedAt ?? this.joinedAt,
      createdAt: createdAt ?? this.createdAt,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      groupIds: groupIds ?? this.groupIds,
      featuredItems: featuredItems ?? this.featuredItems,
      badges: badges ?? this.badges,
      isVerified: isVerified ?? this.isVerified,
      profileCompletion: profileCompletion ?? this.profileCompletion,
    );
  }
}

