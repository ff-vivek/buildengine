import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:buildbeacon/data/models/build_models_simple.dart';
import 'package:buildbeacon/presentation/widgets/source_indicator.dart';
import 'package:buildbeacon/theme.dart';
import 'package:buildbeacon/utils/constants.dart';
import 'package:buildbeacon/utils/validators.dart';

class ReviewStep extends StatelessWidget {
  final SourceType sourceType;
  final PlatformFile? selectedFile;
  final String? memoryFileName;
  final int? memoryFileSize;
  final String ffUrl;
  final String gitUrl;
  final String branch;
  final String flutterVersion;
  final BuildType buildType;
  final String targetFile;
  final List<String> preSteps;
  final List<String> postSteps;
  final List<BuildPlatform> platforms;

  const ReviewStep({
    super.key,
    required this.sourceType,
    required this.selectedFile,
    this.memoryFileName,
    this.memoryFileSize,
    required this.ffUrl,
    required this.gitUrl,
    required this.branch,
    required this.flutterVersion,
    required this.buildType,
    required this.targetFile,
    required this.preSteps,
    required this.postSteps,
    this.platforms = const [BuildPlatform.web],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 32),
          _buildSourceSection(context),
          const SizedBox(height: 24),
          _buildConfigSection(context),
          const SizedBox(height: 24),
          _buildStepsSection(context),
          const SizedBox(height: 24),
          _buildWarningCard(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review & Create Build',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Review your configuration before creating the build job.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: LightModeColors.lightNeutral600,
          ),
        ),
      ],
    );
  }

  Widget _buildSourceSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Source Configuration',
      icon: Icons.source_outlined,
      children: [
        _buildDetailRow(
          context,
          'Source Type',
          SourceIndicator(sourceType: sourceType, showIcon: false),
        ),
        if (sourceType == SourceType.uploadZip && selectedFile != null) ...[
          _buildDetailRow(context, 'File', Text(selectedFile!.name)),
          _buildDetailRow(
            context,
            'File Size',
            Text(Validators.formatFileSize(selectedFile!.size)),
          ),
        ],
        if (sourceType == SourceType.flutterFlow) ...[
          _buildDetailRow(context, 'Project URL', _buildUrlText(context, ffUrl)),
          _buildDetailRow(context, 'Access Token', _buildMaskedToken(context))
        ],
        if (sourceType == SourceType.gitRepo) ...[
          _buildDetailRow(context, 'Git URL', _buildUrlText(context, gitUrl)),
        ],
        if (sourceType != SourceType.uploadZip && branch != AppConstants.noBranch)
          _buildDetailRow(context, 'Branch', Text(branch)),
      ],
    );
  }

  Widget _buildConfigSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Build Configuration',
      icon: Icons.settings_outlined,
      children: [
        _buildDetailRow(
          context,
          'Flutter Version',
          Text(flutterVersion.isEmpty ? 'default' : flutterVersion),
        ),
        _buildDetailRow(
          context,
          'Build Type',
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getBuildTypeColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              buildType.name.toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getBuildTypeColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        _buildDetailRow(context, 'Target File', Text(targetFile)),
        _buildDetailRow(
          context,
          'Platforms',
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: platforms.map((p) => Chip(
              label: Text(p.name.toUpperCase()),
              avatar: const Icon(Icons.devices, size: 16),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStepsSection(BuildContext context) {
    final hasSteps = preSteps.isNotEmpty || postSteps.isNotEmpty;

    return _buildSection(
      context,
      title: 'Build Steps',
      icon: Icons.list_alt_outlined,
      children: [
        if (!hasSteps)
          Text(
            'No custom build steps configured',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: LightModeColors.lightNeutral500,
              fontStyle: FontStyle.italic,
            ),
          )
        else ...[
          if (preSteps.isNotEmpty) ...[
            _buildStepsList(context, 'Pre-Build Steps', preSteps),
            if (postSteps.isNotEmpty) const SizedBox(height: 16),
          ],
          if (postSteps.isNotEmpty)
            _buildStepsList(context, 'Post-Build Steps', postSteps),
        ],
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LightModeColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LightModeColors.lightNeutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: LightModeColors.lightPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: LightModeColors.lightPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(width: 16),
          Expanded(child: value),
        ],
      ),
    );
  }

  Widget _buildStepsList(BuildContext context, String title, List<String> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: LightModeColors.lightNeutral200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: LightModeColors.lightNeutral600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: LightModeColors.lightNeutral700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildUrlText(BuildContext context, String url) {
    return Text(
      url,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: LightModeColors.lightPrimary,
        decoration: TextDecoration.underline,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMaskedToken(BuildContext context) {
    return Text(
      '••••••••••••••••',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontFamily: 'monospace',
        color: LightModeColors.lightNeutral500,
      ),
    );
  }

  Widget _buildWarningCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Important Information',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildWarningItem(context, 'Your build will be queued and processed on our secure servers'),
          _buildWarningItem(context, 'Access tokens are used only for this build and not stored permanently'),
          _buildWarningItem(context, 'Build artifacts will be available for download for 7 days'),
          _buildWarningItem(context, 'You can monitor build progress and logs in real-time'),
        ],
      ),
    );
  }

  Widget _buildWarningItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: Colors.orange[600],
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.orange[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBuildTypeColor() {
    switch (buildType) {
      case BuildType.release:
        return LightModeColors.lightTertiary;
      case BuildType.debug:
        return LightModeColors.lightAccent;
      case BuildType.profile:
        return LightModeColors.lightSecondary;
    }
  }
}