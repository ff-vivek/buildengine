import 'package:flutter/material.dart';
import 'package:buildbeacon/theme.dart';
import 'package:buildbeacon/utils/constants.dart';
import 'package:buildbeacon/app/router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiUrlController = TextEditingController(text: AppConstants.apiBaseUrl);
  bool _enableNotifications = true;
  bool _autoRefreshJobs = true;
  bool _showDetailedLogs = true;
  String _selectedTheme = 'system';

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSection(
              context,
              title: 'API Configuration',
              icon: Icons.api,
              children: [
                _buildApiUrlField(context),
                _buildConnectionStatus(context),
              ],
            ),
            _buildSection(
              context,
              title: 'Build Preferences',
              icon: Icons.build_outlined,
              children: [
                _buildSwitchTile(
                  context,
                  title: 'Auto-refresh job list',
                  subtitle: 'Automatically refresh jobs every 30 seconds',
                  value: _autoRefreshJobs,
                  onChanged: (value) => setState(() => _autoRefreshJobs = value),
                ),
                _buildSwitchTile(
                  context,
                  title: 'Show detailed logs',
                  subtitle: 'Display debug-level logs in build output',
                  value: _showDetailedLogs,
                  onChanged: (value) => setState(() => _showDetailedLogs = value),
                ),
                _buildSwitchTile(
                  context,
                  title: 'Enable notifications',
                  subtitle: 'Get notified when builds complete',
                  value: _enableNotifications,
                  onChanged: (value) => setState(() => _enableNotifications = value),
                ),
              ],
            ),
            _buildSection(
              context,
              title: 'Appearance',
              icon: Icons.palette_outlined,
              children: [
                _buildThemeSelector(context),
              ],
            ),
            _buildSection(
              context,
              title: 'About',
              icon: Icons.info_outline,
              children: [
                _buildAboutInfo(context),
              ],
            ),
            _buildSection(
              context,
              title: 'Support & Feedback',
              icon: Icons.support_outlined,
              children: [
                _buildFeedbackTile(context),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      decoration: BoxDecoration(
        color: LightModeColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LightModeColors.lightNeutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: LightModeColors.lightPrimary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: LightModeColors.lightPrimary,
                  ),
                ),
              ],
            ),
          ),
          ...children.map((child) => Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: LightModeColors.lightNeutral200),
              ),
            ),
            child: child,
          )),
        ],
      ),
    );
  }

  Widget _buildApiUrlField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'API Base URL',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _apiUrlController,
            decoration: const InputDecoration(
              hintText: 'https://api.buildengine.dev',
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'The base URL for the BuildEngine API. Changes require app restart.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: LightModeColors.lightNeutral600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: LightModeColors.lightTertiary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Connected to BuildEngine API',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: LightModeColors.lightTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: _testConnection,
            child: const Text('Test Connection'),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LightModeColors.lightNeutral600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: LightModeColors.lightPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...['system', 'light', 'dark'].map((theme) {
            return RadioListTile<String>(
              title: Text(_getThemeLabel(theme)),
              value: theme,
              groupValue: _selectedTheme,
              onChanged: (value) => setState(() => _selectedTheme = value!),
              activeColor: LightModeColors.lightPrimary,
              contentPadding: EdgeInsets.zero,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAboutInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(context, 'Version', '1.0.0'),
          _buildInfoRow(context, 'Build', '2024.01.001'),
          _buildInfoRow(context, 'Flutter', '3.24.3'),
          const SizedBox(height: 16),
          Text(
            'BuildEngine',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your personal Flutter web build factory. Upload your project, configure your settings, and get a perfectly packaged web build ready for deployment.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: LightModeColors.lightNeutral600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton(
                onPressed: _showLicenses,
                child: const Text('Licenses'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _showPrivacyPolicy,
                child: const Text('Privacy Policy'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: LightModeColors.lightNeutral600,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeLabel(String theme) {
    switch (theme) {
      case 'system':
        return 'Follow system theme';
      case 'light':
        return 'Light theme';
      case 'dark':
        return 'Dark theme';
      default:
        return theme;
    }
  }

  void _testConnection() {
    // Simulate API connection test
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Test'),
        content: const Text('Successfully connected to BuildEngine API!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'BuildEngine',
      applicationVersion: '1.0.0',
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'BuildEngine Privacy Policy\n\n'
            '1. We collect only the data necessary to provide our build service.\n'
            '2. Your source code and build artifacts are processed securely.\n'
            '3. We do not store your source code after build completion.\n'
            '4. Build logs may be retained for debugging purposes for up to 30 days.\n'
            '5. Access tokens are used only for the build process and not stored.\n\n'
            'For complete privacy policy, visit our website.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackTile(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Icon(
        Icons.feedback_outlined,
        color: colorScheme.primary,
      ),
      title: const Text('Send Feedback'),
      subtitle: const Text('Share your thoughts and suggestions'),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: () => context.goToFeedback(),
    );
  }
}