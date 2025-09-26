enum SourceType {
  uploadZip,
  flutterFlow,
  gitRepo,
}

enum Platform {
  web,
  android,
  ios,
  macos,
  windows,
  linux,
}

enum BuildType {
  release,
  debug,
  profile,
}

enum BuildStatus {
  created,
  queued,
  downloadingSource,
  preSteps,
  building,
  postSteps,
  packaging,
  success,
  failed,
  canceled,
}

extension SourceTypeExtension on SourceType {
  String get value {
    switch (this) {
      case SourceType.uploadZip:
        return 'uploadZip';
      case SourceType.flutterFlow:
        return 'flutterFlow';
      case SourceType.gitRepo:
        return 'gitRepo';
    }
  }

  static SourceType fromString(String value) {
    switch (value) {
      case 'uploadZip':
        return SourceType.uploadZip;
      case 'flutterFlow':
        return SourceType.flutterFlow;
      case 'gitRepo':
        return SourceType.gitRepo;
      default:
        throw ArgumentError('Invalid SourceType: $value');
    }
  }
}

extension PlatformExtension on Platform {
  String get value {
    switch (this) {
      case Platform.web:
        return 'web';
      case Platform.android:
        return 'android';
      case Platform.ios:
        return 'ios';
      case Platform.macos:
        return 'macos';
      case Platform.windows:
        return 'windows';
      case Platform.linux:
        return 'linux';
    }
  }

  static Platform fromString(String value) {
    switch (value) {
      case 'web':
        return Platform.web;
      case 'android':
        return Platform.android;
      case 'ios':
        return Platform.ios;
      case 'macos':
        return Platform.macos;
      case 'windows':
        return Platform.windows;
      case 'linux':
        return Platform.linux;
      default:
        throw ArgumentError('Invalid Platform: $value');
    }
  }
}

extension BuildTypeExtension on BuildType {
  String get value {
    switch (this) {
      case BuildType.release:
        return 'release';
      case BuildType.debug:
        return 'debug';
      case BuildType.profile:
        return 'profile';
    }
  }

  static BuildType fromString(String value) {
    switch (value) {
      case 'release':
        return BuildType.release;
      case 'debug':
        return BuildType.debug;
      case 'profile':
        return BuildType.profile;
      default:
        throw ArgumentError('Invalid BuildType: $value');
    }
  }
}

extension BuildStatusExtension on BuildStatus {
  String get value {
    switch (this) {
      case BuildStatus.created:
        return 'created';
      case BuildStatus.queued:
        return 'queued';
      case BuildStatus.downloadingSource:
        return 'downloading_source';
      case BuildStatus.preSteps:
        return 'pre_steps';
      case BuildStatus.building:
        return 'building';
      case BuildStatus.postSteps:
        return 'post_steps';
      case BuildStatus.packaging:
        return 'packaging';
      case BuildStatus.success:
        return 'success';
      case BuildStatus.failed:
        return 'failed';
      case BuildStatus.canceled:
        return 'canceled';
    }
  }

  static BuildStatus fromString(String value) {
    switch (value) {
      case 'created':
        return BuildStatus.created;
      case 'queued':
        return BuildStatus.queued;
      case 'downloading_source':
        return BuildStatus.downloadingSource;
      case 'pre_steps':
        return BuildStatus.preSteps;
      case 'building':
        return BuildStatus.building;
      case 'post_steps':
        return BuildStatus.postSteps;
      case 'packaging':
        return BuildStatus.packaging;
      case 'success':
        return BuildStatus.success;
      case 'failed':
        return BuildStatus.failed;
      case 'canceled':
        return BuildStatus.canceled;
      default:
        throw ArgumentError('Invalid BuildStatus: $value');
    }
  }
}
