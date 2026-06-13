import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────
  // Auth State
  // ─────────────────────────────────────────────

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isLoggedIn => _auth.currentUser != null;

  // ─────────────────────────────────────────────
  // Sign In
  // ─────────────────────────────────────────────

  Future<AuthResult> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await updateOnlineStatus(true);
      return AuthResult.success(credential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapError(e.code));
    } catch (e) {
      return AuthResult.failure('Kuch masla ho gaya. Dobara koshish karo.');
    }
  }

  // ─────────────────────────────────────────────
  // Sign Up
  // ─────────────────────────────────────────────

  Future<AuthResult> signUp(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await credential.user!.updateDisplayName(name);

      // Save user to Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': name,
        'email': email.trim(),
        'role': 'member',
        'isOnline': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'joinedAt': FieldValue.serverTimestamp(),
        'photoUrl': '',
        'username': '',
        'bio': '',
        'groupIds': [],
        'skills': [],
        'badges': [],
        'isVerified': false,
        'profileCompletion': 0,
      });

      return AuthResult.success(credential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapError(e.code));
    } catch (e) {
      return AuthResult.failure('Account nahi bana. Dobara koshish karo.');
    }
  }

  // ─────────────────────────────────────────────
  // Sign Out
  // ─────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await updateOnlineStatus(false);
      await _auth.signOut();
    } catch (_) {
      await _auth.signOut();
    }
  }

  // ─────────────────────────────────────────────
  // Password Reset
  // ─────────────────────────────────────────────

  Future<AuthResult> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success(null);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapError(e.code));
    } catch (e) {
      return AuthResult.failure('Email nahi gaya. Dobara koshish karo.');
    }
  }

  // ─────────────────────────────────────────────
  // Online Status
  // ─────────────────────────────────────────────

  Future<void> updateOnlineStatus(bool isOnline) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).update({
        'isOnline': isOnline,
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ─────────────────────────────────────────────
  // Get User Stream
  // ─────────────────────────────────────────────

  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!, doc.id) : null);
  }

  // ─────────────────────────────────────────────
  // Error Mapping
  // ─────────────────────────────────────────────

  String _mapError(String code) {
    return switch (code) {
      'user-not-found'         => 'Is email ka koi account nahi mila.',
      'wrong-password'         => 'Password galat hai. Dobara try karo.',
      'invalid-credential'     => 'Email ya password galat hai.',
      'email-already-in-use'   => 'Yeh email pehle se registered hai.',
      'weak-password'          => 'Password zyada strong banao (6+ characters).',
      'invalid-email'          => 'Email ka format sahi nahi hai.',
      'network-request-failed' => 'Internet connection check karo.',
      'too-many-requests'      => 'Zyada attempts ho gaye. Thoda ruko.',
      'user-disabled'          => 'Yeh account disable kar diya gaya hai.',
      _                        => 'Kuch masla ho gaya. Dobara koshish karo.',
    };
  }
}

// ─────────────────────────────────────────────
// Result Type
// ─────────────────────────────────────────────

class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? errorMessage;

  AuthResult._({required this.isSuccess, this.user, this.errorMessage});

  factory AuthResult.success(User? user) =>
      AuthResult._(isSuccess: true, user: user);

  factory AuthResult.failure(String message) =>
      AuthResult._(isSuccess: false, errorMessage: message);
}