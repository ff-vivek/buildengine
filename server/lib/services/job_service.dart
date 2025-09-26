import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import '../models/build_job.dart';
import '../models/build_source.dart';
import '../models/build_config.dart';
import '../models/enums.dart';
import '../models/log_entry.dart';
import 'storage_service.dart';
import 'source_downloader.dart';
import 'flutter_build_service.dart';
import 'artifact_packaging_service.dart';
import 'log_service.dart';

final _logger = Logger('JobService');

class JobService {
  final Map<String, BuildJob> _jobs = {};
  final StorageService _storageService;
  final LogService _logService;
  late final SourceDownloader _sourceDownloader;
  late final FlutterBuildService _flutterBuildService;
  late final ArtifactPackagingService _artifactPackagingService;

  JobService(this._storageService, this._logService) {
    _sourceDownloader = SourceDownloader(_storageService);
    _flutterBuildService = FlutterBuildService();
    _artifactPackagingService = ArtifactPackagingService(_storageService);
  }

  String createJob(BuildSource source, BuildConfig config) {
    final jobId = 'job_${const Uuid().v4().substring(0, 8)}';
    final now = DateTime.now().toUtc();

    final job = BuildJob(
      id: jobId,
      source: source,
      config: config,
      status: BuildStatus.created,
      createdAt: now,
    );

    _jobs[jobId] = job;

    _logger.info('Created job: $jobId');
    _logService.addLog(jobId, 'INFO', 'Job created: $jobId');

    // Simulate job processing
    _processJob(jobId);

    return jobId;
  }

  BuildJob? getJob(String jobId) {
    return _jobs[jobId];
  }

  List<BuildJob> getJobs({
    int page = 1,
    int limit = 20,
    BuildStatus? status,
    SourceType? sourceType,
    BuildType? buildType,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var jobs = _jobs.values.toList();

    // Apply filters
    if (status != null) {
      jobs = jobs.where((job) => job.status == status).toList();
    }

    if (sourceType != null) {
      jobs = jobs.where((job) => job.source.type == sourceType).toList();
    }

    if (buildType != null) {
      jobs = jobs.where((job) => job.config.buildType == buildType).toList();
    }

    if (startDate != null) {
      jobs = jobs.where((job) => job.createdAt.isAfter(startDate)).toList();
    }

    if (endDate != null) {
      jobs = jobs.where((job) => job.createdAt.isBefore(endDate)).toList();
    }

    // Sort by creation date (newest first)
    jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Apply pagination
    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;

    if (startIndex >= jobs.length) {
      return [];
    }

    return jobs.sublist(
      startIndex,
      endIndex > jobs.length ? jobs.length : endIndex,
    );
  }

  int getTotalJobsCount({
    BuildStatus? status,
    SourceType? sourceType,
    BuildType? buildType,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var jobs = _jobs.values.toList();

    // Apply same filters as getJobs
    if (status != null) {
      jobs = jobs.where((job) => job.status == status).toList();
    }

    if (sourceType != null) {
      jobs = jobs.where((job) => job.source.type == sourceType).toList();
    }

    if (buildType != null) {
      jobs = jobs.where((job) => job.config.buildType == buildType).toList();
    }

    if (startDate != null) {
      jobs = jobs.where((job) => job.createdAt.isAfter(startDate)).toList();
    }

    if (endDate != null) {
      jobs = jobs.where((job) => job.createdAt.isBefore(endDate)).toList();
    }

    return jobs.length;
  }

  bool cancelJob(String jobId) {
    final job = _jobs[jobId];
    if (job == null) return false;

    if (job.status == BuildStatus.success ||
        job.status == BuildStatus.failed ||
        job.status == BuildStatus.canceled) {
      return false; // Cannot cancel completed jobs
    }

    _jobs[jobId] = job.copyWith(
      status: BuildStatus.canceled,
      finishedAt: DateTime.now().toUtc(),
    );

    _logger.info('Canceled job: $jobId');
    return true;
  }

  void updateJobStatus(String jobId, BuildStatus status,
      {String? errorMessage}) {
    final job = _jobs[jobId];
    if (job == null) return;

    final now = DateTime.now().toUtc();
    final updatedJob = job.copyWith(
      status: status,
      startedAt: job.startedAt ?? (status != BuildStatus.created ? now : null),
      finishedAt: (status == BuildStatus.success ||
              status == BuildStatus.failed ||
              status == BuildStatus.canceled)
          ? now
          : null,
      errorMessage: errorMessage,
    );

    _jobs[jobId] = updatedJob;
    _logger.info('Updated job $jobId status to ${status.value}');
  }

  void _processJob(String jobId) async {
    final job = _jobs[jobId];
    if (job == null) return;

    print('🚀 Starting build process for job: $jobId');
    print('📋 Job details:');
    print('   - Source Type: ${job.source.type.value}');
    print('   - Build Type: ${job.config.buildType.value}');
    print('   - Flutter Version: ${job.config.flutterVersion}');
    print('   - Target File: ${job.config.targetFile}');
    print('   - Pre-steps: ${job.config.preSteps.length} commands');
    print('   - Post-steps: ${job.config.postSteps.length} commands');

    try {
      // Step 1: Queue the job
      print('\n📝 Step 1: Queuing job...');
      await _executeJobStep(jobId, BuildStatus.queued, 'Job queued');
      print('✅ Job queued successfully');

      // Step 2: Download source code
      print('\n📥 Step 2: Downloading source code...');
      await _executeJobStep(
          jobId, BuildStatus.downloadingSource, 'Downloading source code');
      print('   - Source type: ${job.source.type.value}');
      if (job.source.type == SourceType.uploadZip) {
        print('   - Upload ID: ${job.source.uploadId}');
      } else if (job.source.type == SourceType.flutterFlow) {
        print('   - FlutterFlow Project ID: ${job.source.ffProjectId}');
        print('   - FlutterFlow Endpoint: ${job.source.ffEndpoint}');
        print(
            '   - FlutterFlow Environment: ${job.source.ffProjectEnvironment ?? 'Production'}');
        print('   - Include Assets: ${job.source.ffIncludeAssets}');
      } else if (job.source.type == SourceType.gitRepo) {
        print('   - Git URL: ${job.source.gitUrl}');
        print('   - Branch: ${job.source.branch}');
      }

      final workspaceDir =
          await _sourceDownloader.downloadSource(job.source, jobId);
      _addLog(jobId, 'INFO', 'Source code downloaded to: $workspaceDir');
      print('✅ Source code downloaded to: $workspaceDir');

      // Step 3: Execute pre-steps
      print('\n🔧 Step 3: Executing pre-steps...');
      await _executeJobStep(jobId, BuildStatus.preSteps, 'Running pre-steps');
      if (job.config.preSteps.isNotEmpty) {
        print('   - Running ${job.config.preSteps.length} pre-step commands:');
        for (int i = 0; i < job.config.preSteps.length; i++) {
          print('     ${i + 1}. ${job.config.preSteps[i]}');
        }
      } else {
        print('   - No pre-steps configured');
      }
      await _flutterBuildService.executePreSteps(job.config.preSteps, jobId);
      _addLog(jobId, 'INFO', 'Pre-steps completed');
      print('✅ Pre-steps completed successfully');

      // Step 4: Build Flutter app
      print('\n🏗️  Step 4: Building Flutter app...');
      await _executeJobStep(
          jobId, BuildStatus.building, 'Building Flutter app');
      print('   - Build type: ${job.config.buildType.value}');
      print('   - Platform: ${job.config.platform.value}');
      print('   - Target file: ${job.config.targetFile}');
      print('   - Flutter version: ${job.config.flutterVersion}');

      final buildPath =
          await _flutterBuildService.buildFlutterApp(job.config, jobId);
      _addLog(jobId, 'INFO',
          'Flutter app built successfully for ${job.config.platform.value}: $buildPath');
      print('✅ Flutter app built successfully');
      print('   - Build output: $buildPath');

      // Step 5: Execute post-steps
      print('\n🔧 Step 5: Executing post-steps...');
      await _executeJobStep(jobId, BuildStatus.postSteps, 'Running post-steps');
      if (job.config.postSteps.isNotEmpty) {
        print(
            '   - Running ${job.config.postSteps.length} post-step commands:');
        for (int i = 0; i < job.config.postSteps.length; i++) {
          print('     ${i + 1}. ${job.config.postSteps[i]}');
        }
      } else {
        print('   - No post-steps configured');
      }
      await _flutterBuildService.executePostSteps(job.config.postSteps, jobId);
      _addLog(jobId, 'INFO', 'Post-steps completed');
      print('✅ Post-steps completed successfully');

      // Step 6: Package artifacts
      print('\n📦 Step 6: Packaging artifacts...');
      await _executeJobStep(
          jobId, BuildStatus.packaging, 'Packaging artifacts');
      print('   - Packaging build output: $buildPath');
      print('   - Including build logs and metadata');

      final artifactUrl = await _artifactPackagingService
          .packageAndStoreArtifacts(jobId, buildPath);
      _addLog(jobId, 'INFO', 'Artifacts packaged and stored: $artifactUrl');
      print('✅ Artifacts packaged and stored successfully');
      print('   - Artifact URL: $artifactUrl');

      // Step 7: Mark as successful
      print('\n🎉 Step 7: Completing job...');
      await _executeJobStep(
          jobId, BuildStatus.success, 'Build completed successfully');

      // Update job with artifact URL (use current job state, not original)
      final currentJob = _jobs[jobId];
      if (currentJob != null) {
        final updatedJob = currentJob.copyWith(artifactUrl: artifactUrl);
        _jobs[jobId] = updatedJob;
      }

      print('🎊 Job $jobId completed successfully!');
      print('📊 Build Summary:');
      print('   - Job ID: $jobId');
      print('   - Status: SUCCESS');
      print('   - Artifact URL: $artifactUrl');
      print('   - Build Type: ${job.config.buildType.value}');

      _logger.info('Job $jobId completed successfully');
    } catch (e) {
      print('\n❌ Job $jobId failed with error: $e');
      print('🔍 Error details:');
      print('   - Error: $e');
      print('   - Job ID: $jobId');
      print('   - Status: FAILED');

      _logger.severe('Job $jobId failed: $e');
      updateJobStatus(jobId, BuildStatus.failed, errorMessage: e.toString());
      _addLog(jobId, 'ERROR', 'Job failed: $e');
    } finally {
      // Cleanup workspace
      print('\n🧹 Cleaning up workspace...');
      await _cleanupJob(jobId);
      print('✅ Workspace cleanup completed');
    }
  }

  Future<void> _executeJobStep(
      String jobId, BuildStatus status, String message) async {
    updateJobStatus(jobId, status);
    _addLog(jobId, 'INFO', message);
  }

  Future<void> _cleanupJob(String jobId) async {
    try {
      // Cleanup workspace
      await _sourceDownloader.cleanup(jobId);

      // Cleanup build artifacts
      await _flutterBuildService.cleanup(jobId);

      // Cleanup packaging artifacts
      await _artifactPackagingService.cleanup(jobId);

      _logger.info('Cleanup completed for job: $jobId');
    } catch (e) {
      _logger.warning('Failed to cleanup job $jobId: $e');
    }
  }

  void _addLog(String jobId, String level, String message) {
    _logService.addLog(jobId, level, message);
  }

  // Expose log access methods for LogHandler
  List<LogEntry> getLogs(String jobId, {int? tail, String? nextToken}) {
    return _logService.getLogs(jobId, tail: tail, nextToken: nextToken);
  }

  int getLogsCount(String jobId) {
    return _logService.getLogsCount(jobId);
  }

  // Expose LogService for application logs access
  LogService get logService => _logService;
}
