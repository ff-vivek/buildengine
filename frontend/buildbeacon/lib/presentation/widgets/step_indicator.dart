import 'package:flutter/material.dart';
import 'package:buildbeacon/theme.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepTitles;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepTitles,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < totalSteps; i++) ...[
          _buildStep(context, i),
          if (i < totalSteps - 1) _buildConnector(i),
        ],
      ],
    );
  }

  Widget _buildStep(BuildContext context, int step) {
    final isActive = step == currentStep;
    final isCompleted = step < currentStep;
    final isUpcoming = step > currentStep;

    Color stepColor;
    Color textColor;
    Widget stepContent;

    if (isCompleted) {
      stepColor = LightModeColors.lightTertiary;
      textColor = Colors.white;
      stepContent = const Icon(Icons.check, size: 16, color: Colors.white);
    } else if (isActive) {
      stepColor = LightModeColors.lightPrimary;
      textColor = Colors.white;
      stepContent = Text(
        '${step + 1}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      );
    } else {
      stepColor = LightModeColors.lightNeutral200;
      textColor = LightModeColors.lightNeutral400;
      stepContent = Text(
        '${step + 1}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      );
    }

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: stepColor,
              shape: BoxShape.circle,
            ),
            child: Center(child: stepContent),
          ),
          const SizedBox(height: 8),
          Text(
            stepTitles[step],
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isActive || isCompleted
                  ? LightModeColors.lightOnSurface
                  : LightModeColors.lightNeutral500,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(int step) {
    final isCompleted = step < currentStep;
    
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isCompleted 
            ? LightModeColors.lightTertiary
            : LightModeColors.lightNeutral200,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}