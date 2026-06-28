import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/user_model.dart';

class UserSearchController {
  static final UserSearchController instance = UserSearchController._();
  UserSearchController._();

  final _db  = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _myUid => _auth.currentUser?.uid;

  /// Search users by username prefix
  Future<List<UserModel>> searchByUsername(String query) async {
    if (query.trim().isEmpty) return [];

    final q = query.trim().toLowerCase();

    final snap = await _db
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: q)
        .where('username', isLessThan: '${q}z')
        .limit(20)
        .get();

    return snap.docs
        .map((d) => UserModel.fromMap(d.data(), d.id))
        .where((u) => u.id != _myUid) // exclude self
        .toList();
  }
}