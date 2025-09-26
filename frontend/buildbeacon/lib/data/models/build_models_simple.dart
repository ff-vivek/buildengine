import 'dart:typed_data';

/// Simple data models for BuildEngine without freezed
/// This is a temporary solution to get the app running

/// Public codec for mapping BuildStatus to/from API values
class BuildStatusCodec {
  static BuildStatus fromApi(dynamic statusValue) {
    final statusString = statusValue.toString();
    switch (statusString) {
      case 'downloading_source':
        return BuildStatus.downloadingSource;
      case 'pre_steps':
        return BuildStatus.preSteps;
      case 'post_steps':
        return BuildStatus.postSteps;
      default:
        return BuildStatus.values.firstWhere(
          (e) => e.name == statusString,
          orElse: () => BuildStatus.created,
        );
    }
  }

  static String toApi(BuildStatus status) {
    switch (status) {
      case BuildStatus.downloadingSource:
        return 'downloading_source';
      case BuildStatus.preSteps:
        return 'pre_steps';
      case BuildStatus.postSteps:
        return 'post_steps';
      default:
        return status.name;
    }
  }
}

/// Helper function to parse build status from API response
BuildStatus _parseStatus(dynamic statusValue) {
  return BuildStatusCodec.fromApi(statusValue);
}

/// Source types for build jobs
enum SourceType {
  uploadZip,
  flutterFlow,
  gitRepo,
}

/// Build types supported by the system
enum BuildType {
  release,
  debug,
  profile,
}

/// Target platforms to build for
enum BuildPlatform {
  web,
  android,
  ios,
  macos,
  windows,
  linux,
}

/// Codec for mapping BuildPlatform to/from API values (case-insensitive, tolerant)
class BuildPlatformCodec {
  static BuildPlatform fromApi(dynamic value) {
    if (value == null) return BuildPlatform.web;
    final raw = value.toString().trim();
    if (raw.isEmpty) return BuildPlatform.web;
    final s = raw.toLowerCase();

    // Normalize common aliases
    if (s == 'macos' || s == 'macosx' || s == 'osx' || s == 'darwin' || s == 'mac') {
      return BuildPlatform.macos;
    }
    if (s == 'ios' || s == 'iphone' || s == 'ipad') {
      return BuildPlatform.ios;
    }
    if (s == 'android') {
      return BuildPlatform.android;
    }
    if (s == 'web' || s == 'browser') {
      return BuildPlatform.web;
    }
    if (s == 'windows' || s == 'win' || s == 'win32' || s == 'win64') {
      return BuildPlatform.windows;
    }
    if (s == 'linux') {
      return BuildPlatform.linux;
    }

    // Fallback: try direct enum name match
    return BuildPlatform.values.firstWhere(
      (e) => e.name.toLowerCase() == s,
      orElse: () => BuildPlatform.web,
    );
  }

  static String toApi(BuildPlatform platform) {
    // Default to enum name (lowercase) for API
    return platform.name;
  }
}

/// Build job statuses throughout the lifecycle
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

/// Build source configuration
class BuildSource {
  final SourceType type;
  // uploadZip
  final String? uploadId;
  // flutterFlow (new structured fields)
  final String? ffProjectId;
  final String? ffEndpoint;
  final String? ffProjectEnvironment;
  final bool? ffIncludeAssets;
  final String? ffToken;
  // Back-compat fields (optional)
  final String? ffUrl;
  // gitRepo
  final String? gitUrl;
  final String branch;

  BuildSource({
    required this.type,
    this.uploadId,
    this.ffProjectId,
    this.ffEndpoint,
    this.ffProjectEnvironment,
    this.ffIncludeAssets,
    this.ffToken,
    this.ffUrl,
    this.gitUrl,
    this.branch = 'main',
  });

  factory BuildSource.fromJson(Map<String, dynamic> json) {
    return BuildSource(
      type: SourceType.values.firstWhere((e) => e.name == json['type']),
      uploadId: json['uploadId'],
      ffProjectId: json['ffProjectId'],
      ffEndpoint: json['ffEndpoint'],
      ffProjectEnvironment: json['ffProjectEnvironment'],
      ffIncludeAssets: json['ffIncludeAssets'],
      ffToken: json['ffToken'],
      ffUrl: json['ffUrl'],
      gitUrl: json['gitUrl'],
      branch: json['branch'] ?? 'main',
    );
  }

  Map<String, dynamic> toJson() {
    final base = <String, dynamic>{'type': type.name};
    switch (type) {
      case SourceType.uploadZip:
        base['uploadId'] = uploadId;
        break;
      case SourceType.flutterFlow:
        // Emit the exact FF payload as requested (omit nulls)
        if (ffProjectId != null) base['ffProjectId'] = ffProjectId;
        if (ffEndpoint != null) base['ffEndpoint'] = ffEndpoint;
        if (ffProjectEnvironment != null) base['ffProjectEnvironment'] = ffProjectEnvironment;
        if (ffToken != null) base['ffToken'] = ffToken;
        if (ffIncludeAssets != null) base['ffIncludeAssets'] = ffIncludeAssets;
        break;
      case SourceType.gitRepo:
        base['gitUrl'] = gitUrl;
        base['branch'] = branch;
        break;
    }
    return base;
  }
}


/// Build configuration settings
class BuildConfig {
  final String flutterVersion;
  final BuildType buildType;
  final String targetFile;
  final List<String> preSteps;
  final List<String> postSteps;
  final List<BuildPlatform> platforms;

  BuildConfig({
    this.flutterVersion = 'default',
    this.buildType = BuildType.release,
    this.targetFile = 'lib/main.dart',
    this.preSteps = const [],
    this.postSteps = const [],
    this.platforms = const [BuildPlatform.web],
  });

  factory BuildConfig.fromJson(Map<String, dynamic> json) {
    // Accept both "platforms" (array) and legacy "platform" (string)
    final dynamic platformsField = json.containsKey('platforms')
        ? json['platforms']
        : json['platform'];

    List<BuildPlatform> parsedPlatforms;
    if (platformsField == null) {
      parsedPlatforms = <BuildPlatform>[BuildPlatform.web];
    } else if (platformsField is List) {
      parsedPlatforms = platformsField.map((p) => BuildPlatformCodec.fromApi(p)).toList();
      if (parsedPlatforms.isEmpty) {
        parsedPlatforms = <BuildPlatform>[BuildPlatform.web];
      }
    } else {
      // Single value
      parsedPlatforms = <BuildPlatform>[BuildPlatformCodec.fromApi(platformsField)];
    }

    return BuildConfig(
      flutterVersion: json['flutterVersion'] ?? 'default',
      buildType: BuildType.values.firstWhere((e) => e.name == json['buildType'], orElse: () => BuildType.release),
      targetFile: json['targetFile'] ?? 'lib/main.dart',
      preSteps: List<String>.from(json['preSteps'] ?? []),
      postSteps: List<String>.from(json['postSteps'] ?? []),
      platforms: parsedPlatforms,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'flutterVersion': flutterVersion,
      'buildType': buildType.name,
      'targetFile': targetFile,
      'preSteps': preSteps,
      'postSteps': postSteps,
      'platforms': platforms.map((e) => e.name).toList(),
    };
  }
}

/// Complete build job model
class BuildJob {
  final String id;
  final BuildSource source;
  final BuildConfig config;
  final BuildStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String? artifactUrl;
  final String? errorMessage;

  BuildJob({
    required this.id,
    required this.source,
    required this.config,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.finishedAt,
    this.artifactUrl,
    this.errorMessage,
  });

  factory BuildJob.fromJson(Map<String, dynamic> json) {
    return BuildJob(
      id: json['id'],
      source: BuildSource.fromJson(json['source']),
      config: BuildConfig.fromJson(json['config']),
      status: _parseStatus(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      finishedAt: json['finishedAt'] != null ? DateTime.parse(json['finishedAt']) : null,
      artifactUrl: json['artifactUrl'],
      errorMessage: json['errorMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source.toJson(),
      'config': config.toJson(),
      'status': BuildStatusCodec.toApi(status),
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'finishedAt': finishedAt?.toIso8601String(),
      'artifactUrl': artifactUrl,
      'errorMessage': errorMessage,
    };
  }
}

/// Helper function to format build status for API
String _formatStatus(BuildStatus status) {
  return BuildStatusCodec.toApi(status);
}

/// Build job creation request
class CreateBuildRequest {
  final BuildSource source;
  final BuildConfig config;

  CreateBuildRequest({
    required this.source,
    required this.config,
  });

  factory CreateBuildRequest.fromJson(Map<String, dynamic> json) {
    return CreateBuildRequest(
      source: BuildSource.fromJson(json['source']),
      config: BuildConfig.fromJson(json['config']),
    );
  }

  Map<String, dynamic> toJson() {
    final sourceJson = source.toJson();
    final configJson = Map<String, dynamic>.from(config.toJson());

    // If FlutterFlow source is used, send single-string 'platform'
    if (source.type == SourceType.flutterFlow) {
      final firstPlatform = (config.platforms.isNotEmpty ? config.platforms.first : BuildPlatform.web);
      configJson.remove('platforms');
      configJson['platform'] = BuildPlatformCodec.toApi(firstPlatform);
    }

    return {
      'source': sourceJson,
      'config': configJson,
    };
  }
}

/// API response for job creation
class CreateBuildResponse {
  final String id;
  final BuildStatus status;
  final DateTime createdAt;

  CreateBuildResponse({
    required this.id,
    required this.status,
    required this.createdAt,
  });

  factory CreateBuildResponse.fromJson(Map<String, dynamic> json) {
    return CreateBuildResponse(
      id: json['id'],
      status: BuildStatusCodec.fromApi(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Upload initialization response
class UploadResponse {
  final String uploadId;
  final String uploadUrl;

  UploadResponse({
    required this.uploadId,
    required this.uploadUrl,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      uploadId: json['uploadId'],
      uploadUrl: json['uploadUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uploadId': uploadId,
      'uploadUrl': uploadUrl,
    };
  }
}

/// Jobs list response with pagination
class JobsListResponse {
  final List<BuildJob> jobs;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  JobsListResponse({
    required this.jobs,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory JobsListResponse.fromJson(Map<String, dynamic> json) {
    return JobsListResponse(
      jobs: (json['jobs'] as List).map((e) => BuildJob.fromJson(e)).toList(),
      total: json['total'],
      page: json['page'],
      limit: json['limit'],
      hasMore: json['hasMore'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jobs': jobs.map((e) => e.toJson()).toList(),
      'total': total,
      'page': page,
      'limit': limit,
      'hasMore': hasMore,
    };
  }

  JobsListResponse copyWith({
    List<BuildJob>? jobs,
    int? total,
    int? page,
    int? limit,
    bool? hasMore,
  }) {
    return JobsListResponse(
      jobs: jobs ?? this.jobs,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Log entry for build logs
class LogEntry {
  final DateTime timestamp;
  final String level;
  final String message;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.parse(json['timestamp']),
      level: json['level'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level,
      'message': message,
    };
  }
}

/// Build logs response
class LogsResponse {
  final List<LogEntry> logs;
  final int total;
  final String? nextToken;

  LogsResponse({
    required this.logs,
    required this.total,
    this.nextToken,
  });

  factory LogsResponse.fromJson(Map<String, dynamic> json) {
    return LogsResponse(
      logs: (json['logs'] as List).map((e) => LogEntry.fromJson(e)).toList(),
      total: json['total'],
      nextToken: json['nextToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logs': logs.map((e) => e.toJson()).toList(),
      'total': total,
      'nextToken': nextToken,
    };
  }

  LogsResponse copyWith({
    List<LogEntry>? logs,
    int? total,
    String? nextToken,
  }) {
    return LogsResponse(
      logs: logs ?? this.logs,
      total: total ?? this.total,
      nextToken: nextToken ?? this.nextToken,
    );
  }
}

/// Downloaded artifact payload
class DownloadedArtifact {
  final Uint8List bytes;
  final String filename;
  final String contentType;

  const DownloadedArtifact({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });
}