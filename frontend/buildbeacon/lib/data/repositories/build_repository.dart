import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:buildbeacon/data/api/build_api_client.dart';
import 'package:buildbeacon/data/models/build_models_simple.dart';

/// Repository for build operations
class BuildRepository {
  final BuildApiClient _apiClient;

  BuildRepository(this._apiClient);

  /// Upload a picked file and return upload ID (web-safe via PlatformFile)
  Future<String> uploadPickedFile(PlatformFile file, {void Function(double)? onProgress}) async {
    final uploadResponse = await _apiClient.initializeUpload();
    await _apiClient.uploadPlatformFile(
      uploadId: uploadResponse.uploadId,
      file: file,
      onProgress: onProgress,
    );
    return uploadResponse.uploadId;
  }

  /// Upload bytes and return upload ID (web-safe)
  Future<String> uploadBytes(Uint8List bytes, String filename, {void Function(double)? onProgress}) async {
    final uploadResponse = await _apiClient.initializeUpload();
    await _apiClient.uploadBytes(
      uploadId: uploadResponse.uploadId,
      bytes: bytes,
      filename: filename,
      onProgress: onProgress,
    );
    return uploadResponse.uploadId;
  }

  /// Create a new build job
  Future<CreateBuildResponse> createBuild(CreateBuildRequest request) async {
    return await _apiClient.createBuildJob(request);
  }

  /// Get a specific build job
  Future<BuildJob> getBuild(String jobId) async {
    return await _apiClient.getBuildJob(jobId);
  }

  /// Get build logs
  Future<LogsResponse> getBuildLogs(String jobId, {int? tail, String? nextToken}) async {
    return await _apiClient.getBuildJobLogs(jobId, tail: tail, nextToken: nextToken);
  }

  /// Get jobs list with filters
  Future<JobsListResponse> getJobs({
    int page = 1,
    int limit = 20,
    BuildStatus? status,
    SourceType? sourceType,
    BuildType? buildType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _apiClient.getJobs(
      page: page,
      limit: limit,
      status: status,
      sourceType: sourceType,
      buildType: buildType,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Cancel a build job
  Future<void> cancelBuild(String jobId) async {
    await _apiClient.cancelBuildJob(jobId);
  }

  /// Get artifact download URL
  Future<String> getArtifactUrl(String jobId) async {
    return await _apiClient.getArtifactUrl(jobId);
  }

  /// Download artifact file bytes
  Future<DownloadedArtifact> downloadArtifact(String jobId) async {
    return await _apiClient.downloadArtifactFile(jobId);
  }
}