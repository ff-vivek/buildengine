import 'dart:io';
import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

import '../config/environment_config.dart';
import 'storage_interface.dart';

final _logger = Logger('LocalStorageService');

class LocalStorageService implements StorageInterface {
  late final String _uploadsDir;
  late final String _artifactsDir;
  final Map<String, String> _uploadUrls = {};

  LocalStorageService() {
    final basePath = EnvironmentConfig.localStoragePath;
    _uploadsDir = path.join(basePath, 'uploads');
    _artifactsDir = path.join(basePath, 'artifacts');
    _ensureDirectories();
  }

  void _ensureDirectories() {
    Directory(_uploadsDir).createSync(recursive: true);
    Directory(_artifactsDir).createSync(recursive: true);
    _logger.info(
        'Local storage directories created: $_uploadsDir, $_artifactsDir');
  }

  @override
  String initializeUpload() {
    final uploadId = 'upl_${const Uuid().v4().substring(0, 8)}';

    // Generate local file path URL
    final baseUrl = EnvironmentConfig.baseUrl;
    _uploadUrls[uploadId] = '$baseUrl/v1/uploads/$uploadId';

    _logger.info('Initialized local upload: $uploadId');
    return uploadId;
  }

  @override
  String? getUploadUrl(String uploadId) {
    return _uploadUrls[uploadId];
  }

  @override
  Future<bool> storeUpload(String uploadId, Uint8List data) async {
    try {
      
      final uploadDir = Directory(_uploadsDir);
      if (!uploadDir.existsSync()) {
        uploadDir.createSync(recursive: true);
      }
      final file = File(path.join(_uploadsDir, '$uploadId.zip'));
      await file.writeAsBytes(data);

      _logger.info('Stored local upload: $uploadId (${data.length} bytes)');
      return true;
    } catch (e) {
      _logger.severe('Failed to store local upload $uploadId: $e');
      return false;
    }
  }

  @override
  Future<bool> uploadExists(String uploadId) async {
    final file = File(path.join(_uploadsDir, '$uploadId.zip'));
    return await file.exists();
  }

  @override
  Future<Uint8List?> getUpload(String uploadId) async {
    try {
      final file = File(path.join(_uploadsDir, '$uploadId.zip'));
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      _logger.severe('Failed to read local upload $uploadId: $e');
      return null;
    }
  }

  @override
  Future<String> storeArtifact(String jobId, Uint8List data) async {
    try {
      final fileName = '${jobId}_artifact.zip';
      final file = File(path.join(_artifactsDir, fileName));
      await file.writeAsBytes(data);

      // Generate local artifact URL
      final baseUrl = EnvironmentConfig.baseUrl;
      final artifactUrl = '$baseUrl/v1/jobs/$jobId/artifact';

      _logger.info('Stored local artifact for job $jobId: $fileName');
      return artifactUrl;
    } catch (e) {
      _logger.severe('Failed to store local artifact for job $jobId: $e');
      rethrow;
    }
  }

  @override
  Future<String?> getArtifactUrl(String jobId) async {
    try {
      final fileName = '${jobId}_artifact.zip';
      final file = File(path.join(_artifactsDir, fileName));

      if (await file.exists()) {
        final baseUrl = EnvironmentConfig.baseUrl;
        return '$baseUrl/v1/jobs/$jobId/artifact';
      }

      return null;
    } catch (e) {
      _logger.severe('Failed to get local artifact URL for job $jobId: $e');
      return null;
    }
  }

  @override
  Future<bool> artifactExists(String jobId) async {
    final fileName = '${jobId}_artifact.zip';
    final file = File(path.join(_artifactsDir, fileName));
    return await file.exists();
  }

  @override
  Future<void> cleanupExpiredUploads({Duration? maxAge}) async {
    try {
      final maxAgeDuration = maxAge ?? const Duration(hours: 24);
      final cutoffTime = DateTime.now().subtract(maxAgeDuration);

      final uploadDir = Directory(_uploadsDir);
      if (await uploadDir.exists()) {
        await for (final entity in uploadDir.list()) {
          if (entity is File) {
            final stat = await entity.stat();
            if (stat.modified.isBefore(cutoffTime)) {
              await entity.delete();
              _logger.info('Cleaned up expired upload: ${entity.path}');
            }
          }
        }
      }
    } catch (e) {
      _logger.warning('Failed to cleanup expired uploads: $e');
    }
  }

  @override
  Future<bool> deleteUpload(String uploadId) async {
    try {
      final file = File(path.join(_uploadsDir, '$uploadId.zip'));
      if (await file.exists()) {
        await file.delete();
        _uploadUrls.remove(uploadId);
        _logger.info('Deleted local upload: $uploadId');
        return true;
      }
      return false;
    } catch (e) {
      _logger.severe('Failed to delete local upload $uploadId: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteArtifact(String jobId) async {
    try {
      final fileName = '${jobId}_artifact.zip';
      final file = File(path.join(_artifactsDir, fileName));
      if (await file.exists()) {
        await file.delete();
        _logger.info('Deleted local artifact: $jobId');
        return true;
      }
      return false;
    } catch (e) {
      _logger.severe('Failed to delete local artifact $jobId: $e');
      return false;
    }
  }
}
