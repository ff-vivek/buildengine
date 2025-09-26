import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buildbeacon/data/api/build_api_client.dart';
import 'package:buildbeacon/data/repositories/build_repository.dart';
import 'package:buildbeacon/data/models/build_models_simple.dart';
import 'package:buildbeacon/utils/constants.dart';

// API Client Provider
final buildApiClientProvider = Provider<BuildApiClient>((ref) {
  return BuildApiClient(
    baseUrl: AppConstants.apiBaseUrl,
    apiKey: AppConstants.apiKey,
  );
});

// Repository Provider
final buildRepositoryProvider = Provider<BuildRepository>((ref) {
  final apiClient = ref.read(buildApiClientProvider);
  return BuildRepository(apiClient);
});

// Jobs List Provider - simplified version
final jobsListProvider = FutureProvider<JobsListResponse>((ref) async {
  final repository = ref.read(buildRepositoryProvider);
  return repository.getJobs();
});

// Individual Job Provider
final jobProvider = FutureProvider.family<BuildJob, String>((ref, jobId) async {
  final repository = ref.read(buildRepositoryProvider);
  return repository.getBuild(jobId);
});

// Job Logs Provider
final jobLogsProvider = FutureProvider.family<LogsResponse, String>((ref, jobId) async {
  final repository = ref.read(buildRepositoryProvider);
  return repository.getBuildLogs(jobId);
});