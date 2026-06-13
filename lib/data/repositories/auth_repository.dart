import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthRepository {
  static final AuthRepository instance = AuthRepository._internal();
  AuthRepository._internal();

  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────
  // Auth State
  // ─────────────────────────────────────────────

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  User? get currentUser => _authService.currentUser;

  bool get isLoggedIn => _authService.isLoggedIn;

  // ─────────────────────────────────────────────
  // Sign In
  // ─────────────────────────────────────────────

  Future<AuthResult> signIn(String email, String password) async {
    return await _authService.signIn(email, password);
  }

  // ─────────────────────────────────────────────
  // Sign Up
  // ─────────────────────────────────────────────

  Future<AuthResult> signUp(String email, String password, String name) async {
    return await _authService.signUp(email, password, name);
  }

  // ─────────────────────────────────────────────
  // Sign Out
  // ─────────────────────────────────────────────

  Future<void> signOut() async {
    await _authService.signOut();
  }

  // ─────────────────────────────────────────────
  // Password Reset
  // ─────────────────────────────────────────────

  Future<AuthResult> sendPasswordReset(String email) async {
    return await _authService.sendPasswordReset(email);
  }

  // ─────────────────────────────────────────────
  // Get User Stream
  // ─────────────────────────────────────────────

  Stream<UserModel?> getUserStream(String uid) {
    return _authService.getUserStream(uid);
  }

  // ─────────────────────────────────────────────
  // Get User Once
  // ─────────────────────────────────────────────

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // Update User
  // ─────────────────────────────────────────────

  Future<bool> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .update(user.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Update Online Status
  // ─────────────────────────────────────────────

  Future<void> updateOnlineStatus(bool isOnline) async {
    await _authService.updateOnlineStatus(isOnline);
  }
}