import 'build_source.dart';
import 'build_config.dart';

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
    return {
      'source': source.toJson(),
      'config': config.toJson(),
    };
  }

  void validate() {
    source.validate();
  }
}

class CreateBuildResponse {
  final String id;
  final String status;
  final DateTime createdAt;

  CreateBuildResponse({
    required this.id,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class UploadResponse {
  final String uploadId;
  final String? uploadUrl;

  UploadResponse({
    required this.uploadId,
    this.uploadUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'uploadId': uploadId,
      if (uploadUrl != null) 'uploadUrl': uploadUrl,
    };
  }
}

class JobsListResponse {
  final List<Map<String, dynamic>> jobs;
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

  Map<String, dynamic> toJson() {
    return {
      'jobs': jobs,
      'total': total,
      'page': page,
      'limit': limit,
      'hasMore': hasMore,
    };
  }
}

class LogsResponse {
  final List<Map<String, dynamic>> logs;
  final int total;
  final String? nextToken;

  LogsResponse({
    required this.logs,
    required this.total,
    this.nextToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'logs': logs,
      'total': total,
      if (nextToken != null) 'nextToken': nextToken,
    };
  }
}

class ArtifactResponse {
  final String url;

  ArtifactResponse({
    required this.url,
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
    };
  }
}
