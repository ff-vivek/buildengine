import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

import '../config/environment_config.dart';
import 'storage_interface.dart';

final _logger = Logger('GoogleCloudStorageService');

class GoogleCloudStorageService implements StorageInterface {
  late final String _bucketName;
  late final String _accessToken;
  final Map<String, String> _uploadUrls = {};

  GoogleCloudStorageService() {
    _bucketName = EnvironmentConfig.gcpBucketName;
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      _accessToken = await _getAccessToken();
      _logger
          .info('Google Cloud Storage initialized with bucket: $_bucketName');
    } catch (e) {
      _logger.severe('Failed to initialize Google Cloud Storage: $e');
      rethrow;
    }
  }

  Future<String> _getAccessToken() async {
    try {
      // Try service account JSON from environment variable first
      final serviceAccountJson = EnvironmentConfig.gcpServiceAccountJson;
      if (serviceAccountJson.isNotEmpty) {
        return await _getTokenFromServiceAccount(
            jsonDecode(serviceAccountJson));
      }

      // Try service account file path
      final serviceAccountPath = EnvironmentConfig.gcpServiceAccountPath;
      if (serviceAccountPath.isNotEmpty) {
        // Read file and parse JSON
        final file = await File(serviceAccountPath).readAsString();
        return await _getTokenFromServiceAccount(jsonDecode(file));
      }

      // Fall back to default credentials (for GCP environments)
      return await _getTokenFromMetadata();
    } catch (e) {
      _logger.severe('Failed to authenticate with Google Cloud: $e');
      rethrow;
    }
  }

  Future<String> _getTokenFromServiceAccount(
      Map<String, dynamic> serviceAccount) async {
    // This is a simplified implementation
    // In a real implementation, you would use proper JWT signing
    _logger.warning(
        'Service account authentication not fully implemented. Using placeholder token.');
    return 'placeholder-token';
  }

  Future<String> _getTokenFromMetadata() async {
    try {
      // Try to get token from metadata server (for GCP environments)
      final response = await http.get(
        Uri.parse(
            'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token'),
        headers: {'Metadata-Flavor': 'Google'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access_token'];
      }

      throw Exception('Failed to get token from metadata server');
    } catch (e) {
      _logger.warning('Failed to get token from metadata server: $e');
      return 'placeholder-token';
    }
  }

  @override
  String initializeUpload() {
    final uploadId = 'upl_${const Uuid().v4().substring(0, 8)}';

    // For GCS, we'll generate a signed URL for upload
    // This is a placeholder - in practice, you'd generate a proper signed URL
    _uploadUrls[uploadId] =
        'https://storage.googleapis.com/$_bucketName/uploads/$uploadId.zip';

    _logger.info('Initialized GCS upload: $uploadId');
    return uploadId;
  }

  @override
  String? getUploadUrl(String uploadId) {
    return _uploadUrls[uploadId];
  }

  @override
  Future<bool> storeUpload(String uploadId, Uint8List data) async {
    try {
      final objectName = 'uploads/$uploadId.zip';
      final url = 'https://storage.googleapis.com/$_bucketName/$objectName';

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/zip',
        },
        body: data,
      );

      if (response.statusCode == 200) {
        _logger.info('Stored GCS upload: $uploadId (${data.length} bytes)');
        return true;
      } else {
        _logger.severe(
            'Failed to store GCS upload $uploadId: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      _logger.severe('Failed to store GCS upload $uploadId: $e');
      return false;
    }
  }

  @override
  Future<bool> uploadExists(String uploadId) async {
    try {
      final objectName = 'uploads/$uploadId.zip';
      final url = 'https://storage.googleapis.com/$_bucketName/$objectName';

      final response = await http.head(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Uint8List?> getUpload(String uploadId) async {
    try {
      final objectName = 'uploads/$uploadId.zip';
      final url = 'https://storage.googleapis.com/$_bucketName/$objectName';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        _logger.severe(
            'Failed to read GCS upload $uploadId: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.severe('Failed to read GCS upload $uploadId: $e');
      return null;
    }
  }

  @override
  Future<String> storeArtifact(String jobId, Uint8List data) async {
    try {
      final objectName = 'artifacts/${jobId}_artifact.zip';
      final url = 'https://storage.googleapis.com/$_bucketName/$objectName';

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/zip',
        },
        body: data,
      );

      if (response.statusCode == 200) {
        // Generate signed URL for download (simplified - in practice use proper signing)
        final artifactUrl =
            'https://storage.googleapis.com/$_bucketName/$objectName';

        _logger.info('Stored GCS artifact for job $jobId: $objectName');
        return artifactUrl;
      } else {
        _logger.severe(
            'Failed to store GCS artifact for job $jobId: ${response.statusCode} ${response.body}');
        throw Exception('Failed to store artifact: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Failed to store GCS artifact for job $jobId: $e');
      rethrow;
    }
  }

  @override
  Future<String?> getArtifactUrl(String jobId) async {
    try {
      final objectName = 'artifacts/${jobId}_artifact.zip';

      // Check if object exists
      final exists = await artifactExists(jobId);
      if (exists) {
        // Generate signed URL for download (simplified - in practice use proper signing)
        return 'https://storage.googleapis.com/$_bucketName/$objectName';
      }

      return null;
    } catch (e) {
      _logger.severe('Failed to get GCS artifact URL for job $jobId: $e');
      return null;
    }
  }

  @override
  Future<bool> artifactExists(String jobId) async {
    try {
      final objectName = 'artifacts/${jobId}_artifact.zip';
      final url = 'https://storage.googleapis.com/$_bucketName/$objectName';

      final response = await http.head(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> cleanupExpiredUploads({Duration? maxAge}) async {
    try {
      final maxAgeDuration = maxAge ?? const Duration(hours: 24);
      final cutoffTime = DateTime.now().subtract(maxAgeDuration);

      // List objects in uploads folder
      final url =
          'https://storage.googleapis.com/$_bucketName/o?prefix=uploads/';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List?;

        if (items != null) {
          for (final item in items) {
            final timeCreated = DateTime.parse(item['timeCreated']);
            if (timeCreated.isBefore(cutoffTime)) {
              final objectName = item['name'];
              await deleteUpload(
                  objectName.split('/').last.replaceAll('.zip', ''));
              _logger.info('Cleaned up expired GCS upload: $objectName');
            }
          }
        }
      }
    } catch (e) {
      _logger.warning('Failed to cleanup expired GCS uploads: $e');
    }
  }

  @override
  Future<bool> deleteUpload(String uploadId) async {
    try {
      final objectName = 'uploads/$uploadId.zip';
      final url = 'https://storage.googleapis.com/$_bucketName/$objectName';

      final response = await http.delete(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 204) {
        _uploadUrls.remove(uploadId);
        _logger.info('Deleted GCS upload: $uploadId');
        return true;
      } else {
        _logger.severe(
            'Failed to delete GCS upload $uploadId: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.severe('Failed to delete GCS upload $uploadId: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteArtifact(String jobId) async {
    try {
      final objectName = 'artifacts/${jobId}_artifact.zip';
      final url = 'https://storage.googleapis.com/$_bucketName/$objectName';

      final response = await http.delete(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 204) {
        _logger.info('Deleted GCS artifact: $jobId');
        return true;
      } else {
        _logger.severe(
            'Failed to delete GCS artifact $jobId: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.severe('Failed to delete GCS artifact $jobId: $e');
      return false;
    }
  }
}
