import 'dart:io';

enum StorageType {
  local,
  googleCloud,
}

class EnvironmentConfig {
  static StorageType get storageType {
    final envValue = Platform.environment['STORAGE_TYPE']?.toLowerCase();

    switch (envValue) {
      case 'gcp':
      case 'google':
      case 'googlecloud':
        return StorageType.googleCloud;
      case 'local':
      default:
        return StorageType.local;
    }
  }

  static String get gcpProjectId {
    return Platform.environment['GCP_PROJECT_ID'] ?? '';
  }

  static String get gcpBucketName {
    return Platform.environment['GCP_BUCKET_NAME'] ?? 'buildengine-storage';
  }

  static String get gcpServiceAccountPath {
    return Platform.environment['GCP_SERVICE_ACCOUNT_PATH'] ?? '';
  }

  static String get gcpServiceAccountJson {
    return Platform.environment['GCP_SERVICE_ACCOUNT_JSON'] ?? '';
  }

  static String get localStoragePath {
    return Platform.environment['LOCAL_STORAGE_PATH'] ?? 'storage';
  }

  static String get baseUrl {
    return Platform.environment['BASE_URL'] ?? 'http://localhost:8788';
  }

  static bool get isProduction {
    return Platform.environment['ENVIRONMENT']?.toLowerCase() == 'production';
  }

  static bool get isDevelopment {
    return !isProduction;
  }

  static Map<String, String> get allConfig {
    return {
      'STORAGE_TYPE': storageType.name,
      'GCP_PROJECT_ID': gcpProjectId,
      'GCP_BUCKET_NAME': gcpBucketName,
      'GCP_SERVICE_ACCOUNT_PATH': gcpServiceAccountPath,
      'LOCAL_STORAGE_PATH': localStoragePath,
      'BASE_URL': baseUrl,
      'ENVIRONMENT': isProduction ? 'production' : 'development',
    };
  }
}
