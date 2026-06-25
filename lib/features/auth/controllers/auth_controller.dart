import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController {
  static final AuthController instance = AuthController._internal();
  AuthController._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? getCurrentUser() => _auth.currentUser;

  // ── Login ──────────────────────────────────────────────────────────────────
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
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('An unexpected error occurred during login.');
    }
  }

  // ── Signup ─────────────────────────────────────────────────────────────────
  Future<UserCredential> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(fullName.trim());
        await user.reload();

        // ✅ FIX 1: 'name' field (UserModel ke saath match)
        // ✅ FIX 2: role lowercase 'member' (AuthService ke saath consistent)
        // ✅ FIX 3: merge: true — CompleteProfileScreen baad mein update karega,
        //           yeh fields overwrite nahi honge
        // ✅ FIX 4: UserModel ke saare base fields initialize kiye
        await _firestore.collection('users').doc(user.uid).set({
          'uid'              : user.uid,
          'name'             : fullName.trim(),   // ✅ was 'fullName'
          'email'            : email.trim(),
          'role'             : 'member',           // ✅ was 'Member'
          'photoUrl'         : '',
          'coverPhotoUrl'    : '',
          'username'         : '',
          'bio'              : '',
          'groupIds'         : [],
          'skills'           : [],
          'badges'           : [],
          'isVerified'       : false,
          'isOnline'         : true,
          'profileCompletion': 0,
          'createdAt'        : FieldValue.serverTimestamp(),
          'lastActive'       : FieldValue.serverTimestamp(),
          'joinedAt'         : FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)); // ✅ FIX 3: merge so later updates are safe
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('An unexpected error occurred during registration.');
    }
  }

  // ── Reset Password ─────────────────────────────────────────────────────────
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('An unexpected error occurred during password reset.');
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      // Mark user offline before logout
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _firestore.collection('users').doc(uid).update({
          'isOnline'  : false,
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to log out.');
    }
  }

  // ── Error Handler ──────────────────────────────────────────────────────────
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