import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:buildbeacon/app/providers.dart';
import 'package:buildbeacon/data/models/build_models_simple.dart';
import 'package:buildbeacon/app/router.dart';
import 'package:buildbeacon/presentation/widgets/status_chip.dart';
import 'package:buildbeacon/presentation/widgets/source_indicator.dart';
import 'package:buildbeacon/presentation/widgets/build_progress_indicator.dart';
import 'package:buildbeacon/presentation/widgets/build_logs_viewer.dart';
import 'package:buildbeacon/presentation/widgets/error_card.dart';
import 'package:buildbeacon/theme.dart';
import 'package:buildbeacon/utils/constants.dart';
import 'package:buildbeacon/utils/artifact_readiness.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;

  const JobDetailScreen({
    super.key,
    required this.jobId,
  });

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  Timer? _pollTimer;
  late final AppLifecycleListener _lifecycleListener;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onResume: _onAppResumed,
      onInactive: _onAppPaused,
      onPause: _onAppPaused,
      onHide: _onAppPaused,
      onShow: _onAppResumed,
    );
    _startPolling();
  }

  void _onAppResumed() {
    _isActive = true;
    _startPolling();
  }

  void _onAppPaused() {
    _isActive = false;
    _stopPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted || !_isActive) return;
      // If job already reached a terminal state, stop polling
      final current = ref.read(jobProvider(widget.jobId));
      final status = current.value?.status;
      if (status != null && _isTerminalStatus(status)) {
        _stopPolling();
        return;
      }
      // Refresh job and logs
      ref.refresh(jobProvider(widget.jobId));
      ref.refresh(jobLogsProvider(widget.jobId));
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  bool _isTerminalStatus(BuildStatus status) {
    return status == BuildStatus.success ||
        status == BuildStatus.failed ||
        status == BuildStatus.canceled;
  }

  @override
  void dispose() {
    _stopPolling();
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobState = ref.watch(jobProvider(widget.jobId));
    final logsState = ref.watch(jobLogsProvider(widget.jobId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Build #${widget.jobId.substring(0, 8)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(jobProvider(widget.jobId));
              ref.refresh(jobLogsProvider(widget.jobId));
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.goToDashboard(),
            tooltip: 'Home',
          ),
        ],
      ),
      body: jobState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: ErrorCard(
            message: error.toString(),
            onRetry: () => ref.refresh(jobProvider(widget.jobId)),
          ),
        ),
        data: (job) => _buildJobDetails(context, job, logsState),
      ),
    );
  }

  Widget _buildJobDetails(BuildContext context, BuildJob job, AsyncValue<LogsResponse> logsState) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildJobHeader(context, job),
                const SizedBox(height: 24),
                BuildProgressIndicator(job: job),
                const SizedBox(height: 24),
                _buildJobConfig(context, job),
                if (ArtifactReadiness.isReady(
                  status: job.status,
                  logs: logsState.maybeWhen(data: (v) => v, orElse: () => null),
                )) ...[
                  const SizedBox(height: 24),
                  _buildDownloadSection(context, job),
                ],
                if (job.status == BuildStatus.failed && job.errorMessage != null) ...[
                  const SizedBox(height: 24),
                  _buildErrorSection(context, job),
                ],
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Build Logs',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        SliverFillRemaining(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: BuildLogsViewer(jobId: widget.jobId),
          ),
        ),
      ],
    );
  }

  Widget _buildJobHeader(BuildContext context, BuildJob job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Build Job #${job.id}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Created ${_formatDateTime(job.createdAt)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: LightModeColors.lightNeutral600,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(status: job.status, showAnimation: true),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (job.startedAt != null) ...[
                  Icon(
                    Icons.play_arrow,
                    size: 16,
                    color: LightModeColors.lightNeutral500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Started ${_formatDateTime(job.startedAt!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (job.finishedAt != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.timer,
                    size: 16,
                    color: LightModeColors.lightNeutral500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Duration: ${_getDuration(job.startedAt!, job.finishedAt!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
            if (_canCancelJob(job)) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _cancelJob(job),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Build'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: LightModeColors.lightError,
                    side: BorderSide(color: LightModeColors.lightError),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJobConfig(BuildContext context, BuildJob job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildConfigRow(
              context,
              'Source',
              SourceIndicator(sourceType: job.source.type),
            ),
            _buildConfigRow(context, 'Flutter Version', job.config.flutterVersion),
            _buildConfigRow(context, 'Build Type', job.config.buildType.name.toUpperCase()),
            _buildConfigRow(context, 'Target File', job.config.targetFile),
            _buildConfigRow(
              context,
              'Platforms',
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: job.config.platforms
                    .map((p) => Chip(
                          label: Text(p.name.toUpperCase()),
                          avatar: const Icon(Icons.devices, size: 16),
                        ))
                    .toList(),
              ),
            ),
            if (job.source.branch != AppConstants.noBranch)
              _buildConfigRow(context, 'Branch', job.source.branch),
            if (job.config.preSteps.isNotEmpty || job.config.postSteps.isNotEmpty) ...[
              const SizedBox(height: 16),
              if (job.config.preSteps.isNotEmpty)
                _buildStepsInfo(context, 'Pre-steps', job.config.preSteps),
              if (job.config.postSteps.isNotEmpty)
                _buildStepsInfo(context, 'Post-steps', job.config.postSteps),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfigRow(BuildContext context, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: LightModeColors.lightNeutral600,
              ),
            ),
          ),
          Expanded(
            child: value is Widget ? value : Text(
              value.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsInfo(BuildContext context, String title, List<String> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${steps.length})',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        ...steps.take(3).map((step) => Text(
          step,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            color: LightModeColors.lightNeutral600,
          ),
        )),
        if (steps.length > 3)
          Text(
            '... and ${steps.length - 3} more',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: LightModeColors.lightNeutral500,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildDownloadSection(BuildContext context, BuildJob job) {
    return Card(
      color: LightModeColors.lightTertiary.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.download_for_offline,
              size: 48,
              color: LightModeColors.lightTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Build Completed Successfully!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: LightModeColors.lightTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _successSubtitle(job),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _downloadArtifact(job),
                icon: const Icon(Icons.download),
                label: const Text('Download Build'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LightModeColors.lightTertiary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.goToDashboard(),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Go to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSection(BuildContext context, BuildJob job) {
    return ErrorCard(
      message: job.errorMessage!,
      icon: Icons.build_circle_outlined,
    );
  }

  String _successSubtitle(BuildJob job) {
    final plats = job.config.platforms;
    if (plats.isEmpty) return 'Your build is ready for download.';
    if (plats.length == 1) {
      final p = plats.first.name.toUpperCase();
      return 'Your Flutter $p build is ready for download.';
    }
    final joined = plats.map((e) => e.name.toUpperCase()).join(', ');
    return 'Your build for $joined is ready for download.';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    if (duration.inMinutes < 1) {
      return '${duration.inSeconds}s';
    } else if (duration.inHours < 1) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
  }

  bool _isActiveStatus(BuildStatus status) {
    return [
      BuildStatus.queued,
      BuildStatus.downloadingSource,
      BuildStatus.preSteps,
      BuildStatus.building,
      BuildStatus.postSteps,
      BuildStatus.packaging,
    ].contains(status);
  }

  bool _canCancelJob(BuildJob job) {
    return AppConstants.enableJobCancellation && 
           _isActiveStatus(job.status);
  }

  Future<void> _cancelJob(BuildJob job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Build'),
        content: const Text('Are you sure you want to cancel this build? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Building'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: LightModeColors.lightError,
            ),
            child: const Text('Cancel Build'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Show progress while cancelling
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        final repository = ref.read(buildRepositoryProvider);
        await repository.cancelBuild(job.id);

        if (!mounted) return;
        Navigator.of(context).pop(); // close progress dialog

        // Optionally show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppConstants.jobCanceledSuccess),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );

        // Navigate to dashboard
        if (mounted) {
          context.goToDashboard();
        }
      } catch (error) {
        if (!mounted) return;
        Navigator.of(context).pop(); // close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel build: $error'),
            backgroundColor: LightModeColors.lightError,
          ),
        );
      }
    }
  }

  Future<void> _downloadArtifact(BuildJob job) async {
    try {
      final repository = ref.read(buildRepositoryProvider);
      final artifactUrl = await repository.getArtifactUrl(widget.jobId);
      final uri = Uri.parse(artifactUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch download URL');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download artifact: $error'),
            backgroundColor: LightModeColors.lightError,
          ),
        );
      }
    }
  }
}