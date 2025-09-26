import 'package:flutter/material.dart';
import 'package:buildbeacon/data/models/build_models_simple.dart';
import 'package:buildbeacon/theme.dart';
import 'package:buildbeacon/utils/constants.dart';

class BuildProgressIndicator extends StatelessWidget {
  final BuildJob job;

  const BuildProgressIndicator({
    super.key,
    required this.job,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Build Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            _buildProgressStepper(context),
            const SizedBox(height: 16),
            _buildProgressBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStepper(BuildContext context) {
    final steps = _getProgressSteps();
    final currentStepIndex = _getCurrentStepIndex();

    return Column(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _buildProgressStep(
            context,
            steps[i],
            i,
            currentStepIndex,
            isLast: i == steps.length - 1,
          ),
        ],
      ],
    );
  }

  Widget _buildProgressStep(
    BuildContext context,
    ProgressStep step,
    int index,
    int currentIndex, {
    bool isLast = false,
  }) {
    final isCompleted = index < currentIndex;
    final isCurrent = index == currentIndex;
    final isFailed = job.status == BuildStatus.failed && isCurrent;

    Color stepColor;
    Color textColor;
    Widget stepIcon;

    if (isFailed) {
      stepColor = LightModeColors.lightError;
      textColor = LightModeColors.lightError;
      stepIcon = const Icon(Icons.error, size: 16, color: Colors.white);
    } else if (isCompleted) {
      stepColor = LightModeColors.lightTertiary;
      textColor = LightModeColors.lightOnSurface;
      stepIcon = const Icon(Icons.check, size: 16, color: Colors.white);
    } else if (isCurrent) {
      stepColor = LightModeColors.lightPrimary;
      textColor = LightModeColors.lightPrimary;
      stepIcon = _isActiveStatus(job.status) 
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.radio_button_unchecked, size: 16, color: Colors.white);
    } else {
      stepColor = LightModeColors.lightNeutral300;
      textColor = LightModeColors.lightNeutral500;
      stepIcon = const Icon(Icons.radio_button_unchecked, size: 16, color: Colors.white);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: stepColor,
                shape: BoxShape.circle,
              ),
              child: Center(child: stepIcon),
            ),
            if (!isLast) ...[
              const SizedBox(height: 4),
              Container(
                width: 2,
                height: 32,
                color: isCompleted || (isCurrent && !isFailed)
                    ? LightModeColors.lightTertiary
                    : LightModeColors.lightNeutral200,
              ),
              const SizedBox(height: 4),
            ],
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                if (step.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    step.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: LightModeColors.lightNeutral600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final progress = _getProgressPercentage();
    final isFailed = job.status == BuildStatus.failed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Overall Progress',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isFailed ? LightModeColors.lightError : LightModeColors.lightPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: LightModeColors.lightNeutral200,
            valueColor: AlwaysStoppedAnimation<Color>(
              isFailed ? LightModeColors.lightError : LightModeColors.lightPrimary,
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  List<ProgressStep> _getProgressSteps() {
    return [
      ProgressStep(
        title: 'Created',
        description: 'Job just created',
      ),
      ProgressStep(
        title: 'Queued',
        description: 'Job queued for processing',
      ),
      ProgressStep(
        title: 'Downloading source',
        description: 'Downloading source code',
      ),
      ProgressStep(
        title: 'Pre-build steps',
        description: 'Running pre-build steps',
      ),
      ProgressStep(
        title: 'Building',
        description: 'Building Flutter app',
      ),
      ProgressStep(
        title: 'Post-build steps',
        description: 'Running post-build steps',
      ),
      ProgressStep(
        title: 'Packaging',
        description: 'Packaging artifacts',
      ),
      ProgressStep(
        title: job.status == BuildStatus.failed ? 'Failed' : 'Success',
        description: job.status == BuildStatus.failed 
            ? 'Build failed - check logs for details'
            : 'Build completed successfully',
      ),
    ];
  }

  int _getCurrentStepIndex() {
    switch (job.status) {
      case BuildStatus.created:
        return 0;
      case BuildStatus.queued:
        return 1;
      case BuildStatus.downloadingSource:
        return 2;
      case BuildStatus.preSteps:
        return 3;
      case BuildStatus.building:
        return 4;
      case BuildStatus.postSteps:
        return 5;
      case BuildStatus.packaging:
        return 6;
      case BuildStatus.success:
      case BuildStatus.failed:
      case BuildStatus.canceled:
        return 7;
    }
  }

  double _getProgressPercentage() {
    final totalSteps = _getProgressSteps().length;
    final currentStep = _getCurrentStepIndex();
    
    if (job.status == BuildStatus.success) {
      return 1.0;
    } else if (job.status == BuildStatus.failed || job.status == BuildStatus.canceled) {
      return (currentStep + 1) / totalSteps;
    } else {
      return (currentStep + 0.5) / totalSteps;
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

class ProgressStep {
  final String title;
  final String? description;

  ProgressStep({
    required this.title,
    this.description,
  });
}