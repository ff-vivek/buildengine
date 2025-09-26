import 'package:flutter/material.dart';
import 'package:buildbeacon/data/models/build_models_simple.dart';
import 'package:buildbeacon/utils/constants.dart';

class StatusChip extends StatelessWidget {
  final BuildStatus status;
  final bool showAnimation;

  const StatusChip({
    super.key,
    required this.status,
    this.showAnimation = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(statusInfo.color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(statusInfo.color).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showAnimation && _isActiveStatus(status))
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(statusInfo.color),
                ),
              ),
            )
          else
            Icon(
              statusInfo.icon,
              size: 14,
              color: Color(statusInfo.color),
            ),
          const SizedBox(width: 6),
          Text(
            statusInfo.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(statusInfo.color),
            ),
          ),
        ],
      ),
    );
  }

  StatusInfo _getStatusInfo(BuildStatus status) {
    switch (status) {
      case BuildStatus.created:
        return StatusInfo(
          label: 'Created',
          color: AppConstants.statusColors['created']!,
          icon: Icons.fiber_new_outlined,
        );
      case BuildStatus.queued:
        return StatusInfo(
          label: 'Queued',
          color: AppConstants.statusColors['queued']!,
          icon: Icons.queue_outlined,
        );
      case BuildStatus.downloadingSource:
        return StatusInfo(
          label: 'Downloading source',
          color: AppConstants.statusColors['downloading_source']!,
          icon: Icons.cloud_download_outlined,
        );
      case BuildStatus.preSteps:
        return StatusInfo(
          label: 'Pre-steps',
          color: AppConstants.statusColors['pre_steps']!,
          icon: Icons.play_arrow_outlined,
        );
      case BuildStatus.building:
        return StatusInfo(
          label: 'Building',
          color: AppConstants.statusColors['building']!,
          icon: Icons.build_outlined,
        );
      case BuildStatus.postSteps:
        return StatusInfo(
          label: 'Post-steps',
          color: AppConstants.statusColors['post_steps']!,
          icon: Icons.fast_forward_outlined,
        );
      case BuildStatus.packaging:
        return StatusInfo(
          label: 'Packaging',
          color: AppConstants.statusColors['packaging']!,
          icon: Icons.inventory_outlined,
        );
      case BuildStatus.success:
        return StatusInfo(
          label: 'Success',
          color: AppConstants.statusColors['success']!,
          icon: Icons.check_circle_outline,
        );
      case BuildStatus.failed:
        return StatusInfo(
          label: 'Failed',
          color: AppConstants.statusColors['failed']!,
          icon: Icons.error_outline,
        );
      case BuildStatus.canceled:
        return StatusInfo(
          label: 'Canceled',
          color: AppConstants.statusColors['canceled']!,
          icon: Icons.cancel_outlined,
        );
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
}

class StatusInfo {
  final String label;
  final int color;
  final IconData icon;

  StatusInfo({
    required this.label,
    required this.color,
    required this.icon,
  });
}