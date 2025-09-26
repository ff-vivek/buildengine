import 'package:flutter/material.dart';
import 'package:buildbeacon/theme.dart';

class ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  const ErrorCard({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: LightModeColors.lightErrorContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  icon ?? Icons.error_outline,
                  color: LightModeColors.lightError,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Something went wrong',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: LightModeColors.lightOnErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: LightModeColors.lightOnErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: onRetry,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: LightModeColors.lightError,
                      side: BorderSide(color: LightModeColors.lightError),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}