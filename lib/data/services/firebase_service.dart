import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────
// Failure Types
// ─────────────────────────────────────────────

abstract class Failure {
  final String message;
  const Failure(this.message);
}
// ✅ Naya
class FirebaseFailure extends Failure {
  final String code;
  const FirebaseFailure(this.code, super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super('No internet connection.');
}
// ─────────────────────────────────────────────
// Firebase Service
// ─────────────────────────────────────────────

class FirebaseService {
  static final FirebaseService instance = FirebaseService._internal();
  FirebaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseFirestore get db => _db;
  FirebaseAuth get auth => _auth;

  // ─────────────────────────────────────────────
  // Safe Call Wrapper
  // ─────────────────────────────────────────────

  Future<({T? data, Failure? error})> safeCall<T>(
      Future<T> Function() call,
      ) async {
    try {
      final result = await call();
      return (data: result, error: null);
    } on FirebaseException catch (e) {
      return (
      data: null,
      error: FirebaseFailure(
        e.code,
        _mapFirebaseError(e.code),
      ),
      );
    } catch (e) {
      return (
      data: null,
      error: UnknownFailure(e.toString()),
      );
    }
  }

  // ─────────────────────────────────────────────
  // Batch Write Helper
  // ─────────────────────────────────────────────

  Future<Failure?> batchWrite(
      void Function(WriteBatch batch) operations,
      ) async {
    try {
      final batch = _db.batch();
      operations(batch);
      await batch.commit();
      return null;
    } on FirebaseException catch (e) {
      return FirebaseFailure(e.code, _mapFirebaseError(e.code));
    } catch (e) {
      return UnknownFailure(e.toString());
    }
  }

  // ─────────────────────────────────────────────
  // Transaction Helper
  // ─────────────────────────────────────────────

  Future<({T? data, Failure? error})> runTransaction<T>(
      Future<T> Function(Transaction transaction) handler,
      ) async {
    try {
      final result = await _db.runTransaction(handler);
      return (data: result, error: null);
    } on FirebaseException catch (e) {
      return (
      data: null,
      error: FirebaseFailure(e.code, _mapFirebaseError(e.code)),
      );
    } catch (e) {
      return (data: null, error: UnknownFailure(e.toString()));
    }
  }

  // ─────────────────────────────────────────────
  // Document Helpers
  // ─────────────────────────────────────────────

  Future<Failure?> setDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    try {
      await _db
          .collection(collection)
          .doc(docId)
          .set(data, SetOptions(merge: merge));
      return null;
    } on FirebaseException catch (e) {
      return FirebaseFailure(e.code, _mapFirebaseError(e.code));
    } catch (e) {
      return UnknownFailure(e.toString());
    }
  }

  Future<Failure?> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db.collection(collection).doc(docId).update(data);
      return null;
    } on FirebaseException catch (e) {
      return FirebaseFailure(e.code, _mapFirebaseError(e.code));
    } catch (e) {
      return UnknownFailure(e.toString());
    }
  }

  Future<Failure?> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      await _db.collection(collection).doc(docId).delete();
      return null;
    } on FirebaseException catch (e) {
      return FirebaseFailure(e.code, _mapFirebaseError(e.code));
    } catch (e) {
      return UnknownFailure(e.toString());
    }
  }

  Future<({Map<String, dynamic>? data, Failure? error})> getDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      final doc = await _db.collection(collection).doc(docId).get();
      if (!doc.exists) return (data: null, error: null);
      return (data: doc.data(), error: null);
    } on FirebaseException catch (e) {
      return (
      data: null,
      error: FirebaseFailure(e.code, _mapFirebaseError(e.code)),
      );
    } catch (e) {
      return (data: null, error: UnknownFailure(e.toString()));
    }
  }

  // ─────────────────────────────────────────────
  // Offline Persistence (call once in main.dart)
  // ─────────────────────────────────────────────

  static void enableOfflinePersistence() {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // ─────────────────────────────────────────────
  // Error Mapping
  // ─────────────────────────────────────────────

  String _mapFirebaseError(String code) {
    return switch (code) {
      'permission-denied'      => 'You don\'t have permission to do this.',
      'not-found'              => 'The requested data was not found.',
      'already-exists'         => 'This record already exists.',
      'resource-exhausted'     => 'Quota exceeded. Please try again later.',
      'unauthenticated'        => 'Please log in to continue.',
      'unavailable'            => 'Service temporarily unavailable. Try again.',
      'network-request-failed' => 'No internet connection.',
      'deadline-exceeded'      => 'Request timed out. Please try again.',
      _                        => 'Something went wrong. Please try again.',
    };
  }
}