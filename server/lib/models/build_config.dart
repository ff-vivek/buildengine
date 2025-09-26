import 'enums.dart';

class BuildConfig {
  final String flutterVersion;
  final BuildType buildType;
  final Platform platform;
  final String targetFile;
  final List<String> preSteps;
  final List<String> postSteps;

  BuildConfig({
    this.flutterVersion = 'default',
    required this.buildType,
    this.platform = Platform.web,
    this.targetFile = 'lib/main.dart',
    this.preSteps = const [],
    this.postSteps = const [],
  });

  factory BuildConfig.fromJson(Map<String, dynamic> json) {
    return BuildConfig(
      flutterVersion: json['flutterVersion'] ?? 'default',
      buildType: BuildTypeExtension.fromString(json['buildType']),
      platform: json['platform'] != null
          ? PlatformExtension.fromString(json['platform'])
          : Platform.web,
      targetFile: json['targetFile'] ?? 'lib/main.dart',
      preSteps: List<String>.from(json['preSteps'] ?? []),
      postSteps: List<String>.from(json['postSteps'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'flutterVersion': flutterVersion,
      'buildType': buildType.value,
      'platform': platform.value,
      'targetFile': targetFile,
      'preSteps': preSteps,
      'postSteps': postSteps,
    };
  }
}
