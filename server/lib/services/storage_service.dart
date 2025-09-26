import 'dart:typed_data';
import 'package:logging/logging.dart';

import '../config/environment_config.dart';
import 'storage_interface.dart';
import 'local_storage_service.dart';
import 'google_cloud_storage_service.dart';

final _logger = Logger('StorageService');

class StorageService implements StorageInterface {
  late final StorageInterface _storageImpl;

  StorageService() {
    _initializeStorage();
  }

  void _initializeStorage() {
    switch (EnvironmentConfig.storageType) {
      case StorageType.local:
        _storageImpl = LocalStorageService();
        _logger.info('Using local storage service');
        break;
      case StorageType.googleCloud:
        _storageImpl = GoogleCloudStorageService();
        _logger.info('Using Google Cloud Storage service');
        break;
    }
  }

  @override
  String initializeUpload() {
    return _storageImpl.initializeUpload();
  }

  @override
  String? getUploadUrl(String uploadId) {
    return _storageImpl.getUploadUrl(uploadId);
  }

  @override
  Future<bool> storeUpload(String uploadId, Uint8List data) async {
    return _storageImpl.storeUpload(uploadId, data);
  }

  @override
  Future<bool> uploadExists(String uploadId) async {
    return _storageImpl.uploadExists(uploadId);
  }

  @override
  Future<Uint8List?> getUpload(String uploadId) async {
    return _storageImpl.getUpload(uploadId);
  }

  @override
  Future<String> storeArtifact(String jobId, Uint8List data) async {
    return _storageImpl.storeArtifact(jobId, data);
  }

  @override
  Future<String?> getArtifactUrl(String jobId) async {
    return _storageImpl.getArtifactUrl(jobId);
  }

  @override
  Future<bool> artifactExists(String jobId) async {
    return _storageImpl.artifactExists(jobId);
  }

  @override
  Future<void> cleanupExpiredUploads({Duration? maxAge}) async {
    return _storageImpl.cleanupExpiredUploads(maxAge: maxAge);
  }

  @override
  Future<bool> deleteUpload(String uploadId) async {
    return _storageImpl.deleteUpload(uploadId);
  }

  @override
  Future<bool> deleteArtifact(String jobId) async {
    return _storageImpl.deleteArtifact(jobId);
  }
}
