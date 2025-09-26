import 'package:buildbeacon/data/models/build_models_simple.dart';

/// Utility to infer when a build artifact is ready based on job status and logs.
class ArtifactReadiness {
  /// Returns true when it is safe to request the artifact URL.
  ///
  /// Rules:
  /// - If the job status is success -> ready.
  /// - If any log line contains "Artifacts packaged and stored" -> ready.
  /// - Otherwise -> not ready yet.
  static bool isReady({required BuildStatus status, required LogsResponse? logs}) {
    if (status == BuildStatus.success) return true;
    if (logs == null) return false;

    // Look for packaging completion line emitted by backend
    return logs.logs.any((e) =>
        e.message.contains('Artifacts packaged and stored successfully') ||
        e.message.contains('Artifacts packaged and stored:'));
  }
}
