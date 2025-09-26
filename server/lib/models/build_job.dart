import 'build_source.dart';
import 'build_config.dart';
import 'enums.dart';

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
      status: BuildStatusExtension.fromString(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      startedAt:
          json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'])
          : null,
      artifactUrl: json['artifactUrl'],
      errorMessage: json['errorMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source.toJson(),
      'config': config.toJson(),
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
      if (finishedAt != null) 'finishedAt': finishedAt!.toIso8601String(),
      if (artifactUrl != null) 'artifactUrl': artifactUrl,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  BuildJob copyWith({
    String? id,
    BuildSource? source,
    BuildConfig? config,
    BuildStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? finishedAt,
    String? artifactUrl,
    String? errorMessage,
  }) {
    return BuildJob(
      id: id ?? this.id,
      source: source ?? this.source,
      config: config ?? this.config,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      artifactUrl: artifactUrl ?? this.artifactUrl,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
