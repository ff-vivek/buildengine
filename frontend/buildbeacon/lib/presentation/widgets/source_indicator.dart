import 'package:flutter/material.dart';
import 'package:buildbeacon/data/models/build_models_simple.dart';
import 'package:buildbeacon/theme.dart';

class SourceIndicator extends StatelessWidget {
  final SourceType sourceType;
  final bool showIcon;

  const SourceIndicator({
    super.key,
    required this.sourceType,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final info = _getSourceInfo(sourceType);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(
            info.icon,
            size: 16,
            color: Color(info.color),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          info.label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Color(info.color),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  SourceInfo _getSourceInfo(SourceType sourceType) {
    switch (sourceType) {
      case SourceType.uploadZip:
        return SourceInfo(
          label: 'Upload',
          icon: Icons.upload_outlined,
          color: LightModeColors.lightSecondary.value,
        );
      case SourceType.flutterFlow:
        return SourceInfo(
          label: 'FlutterFlow',
          icon: Icons.flutter_dash_outlined,
          color: LightModeColors.lightAccent.value,
        );
      case SourceType.gitRepo:
        return SourceInfo(
          label: 'Git Repo',
          icon: Icons.account_tree_outlined,
          color: LightModeColors.lightTertiary.value,
        );
    }
  }
}

class SourceInfo {
  final String label;
  final IconData icon;
  final int color;

  SourceInfo({
    required this.label,
    required this.icon,
    required this.color,
  });
}