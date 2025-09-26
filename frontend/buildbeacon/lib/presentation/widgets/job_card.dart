import 'package:flutter/material.dart';
import 'package:buildbeacon/data/models/build_models_simple.dart';
import 'package:buildbeacon/presentation/widgets/status_chip.dart';
import 'package:buildbeacon/presentation/widgets/source_indicator.dart';
import 'package:buildbeacon/theme.dart';
import 'package:buildbeacon/utils/constants.dart';

class JobCard extends StatelessWidget {
  final BuildJob job;
  final VoidCallback? onTap;

  const JobCard({
    super.key,
    required this.job,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildDetails(context),
              const SizedBox(height: 16),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Build #${job.id.substring(0, 8)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTimeAgo(job.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: LightModeColors.lightNeutral500,
                ),
              ),
            ],
          ),
        ),
        StatusChip(status: job.status),
      ],
    );
  }

  Widget _buildDetails(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                context,
                icon: Icons.source_outlined,
                label: 'Source',
                child: SourceIndicator(sourceType: job.source.type),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                icon: Icons.flutter_dash,
                label: 'Flutter',
                value: job.config.flutterVersion,
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                context,
                icon: Icons.build_outlined,
                label: 'Type',
                value: job.config.buildType.name.toUpperCase(),
              ),
              const SizedBox(height: 8),
              if (job.source.branch != AppConstants.noBranch)
                _buildDetailRow(
                  context,
                  icon: Icons.account_tree_outlined,
                  label: 'Branch',
                  value: job.source.branch,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? value,
    Widget? child,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: LightModeColors.lightNeutral400,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: LightModeColors.lightNeutral500,
          ),
        ),
        if (child != null) child else Text(
          value ?? 'N/A',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final duration = _getBuildDuration();
    
    return Row(
      children: [
        if (duration != null) ...[
          Icon(
            Icons.timer_outlined,
            size: 16,
            color: LightModeColors.lightNeutral400,
          ),
          const SizedBox(width: 4),
          Text(
            duration,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: LightModeColors.lightNeutral500,
            ),
          ),
          const Spacer(),
        ],
        if (job.status == BuildStatus.success && job.artifactUrl != null)
          Icon(
            Icons.download_outlined,
            size: 16,
            color: LightModeColors.lightTertiary,
          ),
        if (job.status == BuildStatus.failed)
          Icon(
            Icons.error_outline,
            size: 16,
            color: LightModeColors.lightError,
          ),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String? _getBuildDuration() {
    if (job.startedAt == null) return null;
    
    final endTime = job.finishedAt ?? DateTime.now();
    final duration = endTime.difference(job.startedAt!);
    
    if (duration.inMinutes < 1) {
      return '${duration.inSeconds}s';
    } else if (duration.inHours < 1) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
  }
}