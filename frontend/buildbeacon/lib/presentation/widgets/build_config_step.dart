import 'package:flutter/material.dart';
import 'package:buildbeacon/data/models/build_models_simple.dart';
import 'package:buildbeacon/theme.dart';
import 'package:buildbeacon/utils/constants.dart';
import 'package:buildbeacon/utils/validators.dart';

class BuildConfigStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String flutterVersion;
  final BuildType buildType;
  final String targetFile;
  final List<BuildPlatform> platforms;
  final ValueChanged<String> onFlutterVersionChanged;
  final ValueChanged<BuildType> onBuildTypeChanged;
  final ValueChanged<String> onTargetFileChanged;
  final ValueChanged<List<BuildPlatform>> onPlatformsChanged;

  const BuildConfigStep({
    super.key,
    required this.formKey,
    required this.flutterVersion,
    required this.buildType,
    required this.targetFile,
    required this.platforms,
    required this.onFlutterVersionChanged,
    required this.onBuildTypeChanged,
    required this.onTargetFileChanged,
    required this.onPlatformsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            _buildFlutterVersionSection(context),
            const SizedBox(height: 32),
            _buildBuildTypeSection(context),
            const SizedBox(height: 32),
            _buildPlatformsSection(context),
            const SizedBox(height: 32),
            _buildTargetFileSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Build Configuration',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Configure how your Flutter project will be built.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: LightModeColors.lightNeutral600,
          ),
        ),
      ],
    );
  }

  Widget _buildFlutterVersionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Flutter Version',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: flutterVersion,
          decoration: const InputDecoration(
            labelText: 'Flutter Version',
            hintText: 'default, stable, or 3.24.3',
            prefixIcon: Icon(Icons.flutter_dash),
            helperText: 'Leave empty or use "default" for server default',
          ),
          validator: Validators.validateFlutterVersion,
          onChanged: onFlutterVersionChanged,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          context,
          'Use "default" to use the server\'s default Flutter version, or specify a version like "3.24.3" or "stable".',
        ),
      ],
    );
  }

  Widget _buildBuildTypeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Build Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...BuildType.values.map((type) => _buildBuildTypeRadio(context, type)),
        const SizedBox(height: 12),
        _buildBuildTypeInfo(context),
      ],
    );
  }

  Widget _buildBuildTypeRadio(BuildContext context, BuildType type) {
    return RadioListTile<BuildType>(
      title: Text(
        type.name.toUpperCase(),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        _getBuildTypeDescription(type),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: LightModeColors.lightNeutral600,
        ),
      ),
      value: type,
      groupValue: buildType,
      onChanged: (value) => onBuildTypeChanged(value!),
      activeColor: LightModeColors.lightPrimary,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildTargetFileSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target File',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: targetFile,
          decoration: const InputDecoration(
            labelText: 'Target File',
            hintText: 'lib/main.dart',
            prefixIcon: Icon(Icons.code),
            helperText: 'The main Dart file to build from',
          ),
          validator: Validators.validateTargetFile,
          onChanged: onTargetFileChanged,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          context,
          'Specify the main Dart file for your Flutter app. This is typically "lib/main.dart".',
        ),
      ],
    );
  }

  Widget _buildBuildTypeInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LightModeColors.lightNeutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LightModeColors.lightNeutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: LightModeColors.lightPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Build Type Guide',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: LightModeColors.lightPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBuildTypeGuideItem(context, 'Release', 'Optimized for production deployment'),
          _buildBuildTypeGuideItem(context, 'Debug', 'Includes debugging information'),
          _buildBuildTypeGuideItem(context, 'Profile', 'Optimized with profiling enabled'),
        ],
      ),
    );
  }

  Widget _buildPlatformsSection(BuildContext context) {
    final BuildPlatform? current = platforms.isNotEmpty ? platforms.first : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Platform',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BuildPlatform.values.map((p) {
            final isSelected = current == p;
            return ChoiceChip(
              label: Text(p.name.toUpperCase()),
              selected: isSelected,
              onSelected: (_) {
                // Force single selection: always set to exactly [p]
                onPlatformsChanged([p]);
              },
              selectedColor: LightModeColors.lightPrimary.withValues(alpha: 0.15),
              // ChoiceChip doesn't show checkmark by default; keep text style clear
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          context,
          'Select exactly one platform to build for (e.g., Web, Android, iOS).',
        ),
      ],
    );
  }

  Widget _buildBuildTypeGuideItem(BuildContext context, String type, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: LightModeColors.lightNeutral400,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall,
                children: [
                  TextSpan(
                    text: '$type: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LightModeColors.lightNeutral100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LightModeColors.lightNeutral200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: LightModeColors.lightNeutral500,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: LightModeColors.lightNeutral600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getBuildTypeDescription(BuildType type) {
    switch (type) {
      case BuildType.release:
        return 'Optimized for production with smaller file size';
      case BuildType.debug:
        return 'Includes debugging symbols and hot reload support';
      case BuildType.profile:
        return 'Optimized build with performance profiling enabled';
    }
  }
}