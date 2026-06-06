import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController {
  // Singleton pattern for easy global access
  static final AuthController instance = AuthController._internal();
  AuthController._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth state changes (used in main.dart)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current Firebase user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Login existing user
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred during login.');
    }
  }

  // Create new user, set display name, and save to Firestore
  Future<UserCredential> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Create user in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user != null) {
        // 2. Update display name in Firebase Auth profile
        await user.updateDisplayName(fullName.trim());
        await user.reload();

        // 3. Save user info in Firestore "users" collection
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': fullName.trim(),
          'email': email.trim(),
          'role': 'Member', // Default role
          'createdAt': FieldValue.serverTimestamp(),
          'photoUrl': '',
        });
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred during registration.');
    }
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred during password reset.');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to log out.');
    }
  }

  // Custom readable error handling
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email address is already in use by another account.';
      case 'weak-password':
        return 'The password is too weak. Must be at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'invalid-credential':
        return 'Invalid credentials provided.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}

