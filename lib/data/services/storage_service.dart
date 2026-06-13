import 'dart:io';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Max sizes
  static const int _maxImageSize = 5 * 1024 * 1024;  // 5MB
  static const int _maxFileSize = 20 * 1024 * 1024;   // 20MB

  // ─────────────────────────────────────────────
  // Upload Profile Photo
  // ─────────────────────────────────────────────

  Future<StorageResult> uploadProfilePhoto(File file, String uid) async {
    return _uploadFile(
      file: file,
      storagePath: 'users/$uid/profile_photo.jpg',
      maxSize: _maxImageSize,
      contentType: 'image/jpeg',
    );
  }

  // ─────────────────────────────────────────────
  // Upload Group Avatar
  // ─────────────────────────────────────────────

  Future<StorageResult> uploadGroupAvatar(File file, String groupId) async {
    return _uploadFile(
      file: file,
      storagePath: 'groups/$groupId/avatar.jpg',
      maxSize: _maxImageSize,
      contentType: 'image/jpeg',
    );
  }

  // ─────────────────────────────────────────────
  // Upload Chat File
  // ─────────────────────────────────────────────

  Future<StorageResult> uploadChatFile(File file, String groupId) async {
    final ext = path.extension(file.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final isImage = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext.toLowerCase());

    return _uploadFile(
      file: file,
      storagePath: 'groups/$groupId/files/$fileName',
      maxSize: isImage ? _maxImageSize : _maxFileSize,
      contentType: isImage ? 'image/jpeg' : 'application/octet-stream',
    );
  }

  // ─────────────────────────────────────────────
  // Delete File
  // ─────────────────────────────────────────────

  Future<StorageResult> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      return StorageResult.success(null);
    } on FirebaseException catch (e) {
      return StorageResult.failure('Failed to delete file: ${e.message}');
    } catch (e) {
      return StorageResult.failure('Something went wrong.');
    }
  }

  // ─────────────────────────────────────────────
  // Upload with Progress
  // ─────────────────────────────────────────────

  Stream<double> uploadWithProgress(File file, String storagePath) {
    final controller = StreamController<double>();

    try {
      final ref = _storage.ref(storagePath);
      final task = ref.putFile(file);

      task.snapshotEvents.listen(
            (snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          controller.add(progress);
        },
        onDone: () => controller.close(),
        onError: (e) => controller.addError(e),
      );
    } catch (e) {
      controller.addError(e);
    }

    return controller.stream;
  }

  // ─────────────────────────────────────────────
  // Private Upload Helper
  // ─────────────────────────────────────────────

  Future<StorageResult> _uploadFile({
    required File file,
    required String storagePath,
    required int maxSize,
    required String contentType,
  }) async {
    try {
      // Validate file size
      final fileSize = await file.length();
      if (fileSize > maxSize) {
        final maxMB = maxSize ~/ (1024 * 1024);
        return StorageResult.failure('File too large. Max size is ${maxMB}MB.');
      }

      final ref = _storage.ref(storagePath);
      final metadata = SettableMetadata(contentType: contentType);

      await ref.putFile(file, metadata);
      final downloadUrl = await ref.getDownloadURL();

      return StorageResult.success(downloadUrl);
    } on FirebaseException catch (e) {
      return StorageResult.failure('Upload failed: ${e.message}');
    } catch (e) {
      return StorageResult.failure('Something went wrong during upload.');
    }
  }
}

// ─────────────────────────────────────────────
// Result Type
// ─────────────────────────────────────────────

class StorageResult {
  final bool isSuccess;
  final String? url;
  final String? errorMessage;

  StorageResult._({
    required this.isSuccess,
    this.url,
    this.errorMessage,
  });

  factory StorageResult.success(String? url) =>
      StorageResult._(isSuccess: true, url: url);

  factory StorageResult.failure(String message) =>
      StorageResult._(isSuccess: false, errorMessage: message);
}