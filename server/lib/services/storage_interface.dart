import 'dart:typed_data';

/// Abstract interface for storage operations
/// Implementations can be local file storage or cloud storage
abstract class StorageInterface {
  /// Initialize an upload and return an upload ID
  String initializeUpload();

  /// Get the upload URL for a given upload ID
  String? getUploadUrl(String uploadId);

  /// Store uploaded data
  Future<bool> storeUpload(String uploadId, Uint8List data);

  /// Check if an upload exists
  Future<bool> uploadExists(String uploadId);

  /// Retrieve uploaded data
  Future<Uint8List?> getUpload(String uploadId);

  /// Store build artifact
  Future<String> storeArtifact(String jobId, Uint8List data);

  /// Get artifact download URL
  Future<String?> getArtifactUrl(String jobId);

  /// Check if artifact exists
  Future<bool> artifactExists(String jobId);

  /// Clean up expired uploads (optional)
  Future<void> cleanupExpiredUploads({Duration? maxAge});

  /// Delete an upload (optional)
  Future<bool> deleteUpload(String uploadId);

  /// Delete an artifact (optional)
  Future<bool> deleteArtifact(String jobId);
}
