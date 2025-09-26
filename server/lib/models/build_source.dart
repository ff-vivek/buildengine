import 'enums.dart';

class BuildSource {
  final SourceType type;
  final String? uploadId;
  final String? ffUrl;
  final String? ffToken;
  final String? gitUrl;
  final String branch;

  // FlutterFlow CLI configuration
  final String? ffProjectId;
  final String? ffEndpoint;
  final String? ffProjectEnvironment;
  final bool ffIncludeAssets;

  BuildSource({
    required this.type,
    this.uploadId,
    this.ffUrl,
    this.ffToken,
    this.gitUrl,
    this.branch = 'main',
    this.ffProjectId,
    this.ffEndpoint,
    this.ffProjectEnvironment,
    this.ffIncludeAssets = true,
  });

  factory BuildSource.fromJson(Map<String, dynamic> json) {
    return BuildSource(
      type: SourceTypeExtension.fromString(json['type']),
      uploadId: json['uploadId'],
      ffUrl: json['ffUrl'],
      ffToken: json['ffToken'],
      gitUrl: json['gitUrl'],
      branch: json['branch'] ?? 'main',
      ffProjectId: json['ffProjectId'],
      ffEndpoint: json['ffEndpoint'],
      ffProjectEnvironment: json['ffProjectEnvironment'],
      ffIncludeAssets: json['ffIncludeAssets'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      if (uploadId != null) 'uploadId': uploadId,
      if (ffUrl != null) 'ffUrl': ffUrl,
      if (ffToken != null) 'ffToken': ffToken,
      if (gitUrl != null) 'gitUrl': gitUrl,
      'branch': branch,
      if (ffProjectId != null) 'ffProjectId': ffProjectId,
      if (ffEndpoint != null) 'ffEndpoint': ffEndpoint,
      if (ffProjectEnvironment != null)
        'ffProjectEnvironment': ffProjectEnvironment,
      'ffIncludeAssets': ffIncludeAssets,
    };
  }

  void validate() {
    switch (type) {
      case SourceType.uploadZip:
        if (uploadId == null || uploadId!.isEmpty) {
          throw ArgumentError('uploadId is required for uploadZip source type');
        }
        break;
      case SourceType.flutterFlow:
        if (ffProjectId == null || ffProjectId!.isEmpty) {
          throw ArgumentError(
              'ffProjectId is required for flutterFlow source type');
        }
        if (ffToken == null || ffToken!.isEmpty) {
          throw ArgumentError(
              'ffToken is required for flutterFlow source type');
        }
        if (ffEndpoint == null || ffEndpoint!.isEmpty) {
          throw ArgumentError(
              'ffEndpoint is required for flutterFlow source type');
        }
        break;
      case SourceType.gitRepo:
        if (gitUrl == null || gitUrl!.isEmpty) {
          throw ArgumentError('gitUrl is required for gitRepo source type');
        }
        break;
    }
  }
}
