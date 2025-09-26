/// Application constants
class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'http://127.0.0.1:8788';
  static const String? apiKey = null; // Set via environment or config
  
  // File Upload Constraints
  static const int maxFileSize = 100 * 1024 * 1024; // 100 MB
  static const List<String> allowedFileExtensions = ['.zip'];
  
  // Build Configuration Defaults
  static const String defaultFlutterVersion = 'default';
  static const String defaultTargetFile = 'lib/main.dart';
  static const String defaultBranch = 'main';
  static const String noBranch = 'none';
  
  // UI Constants
  static const int jobsPerPage = 20;
  static const int logsPerPage = 100;
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;
  
  // Build Status Colors
  static const Map<String, int> statusColors = {
    'created': 0xFF64748B,      // neutral
    'queued': 0xFF0EA5E9,       // sky blue
    'downloading_source': 0xFF8B5CF6, // violet
    'pre_steps': 0xFF06B6D4,    // cyan
    'building': 0xFF0070F3,     // primary blue
    'post_steps': 0xFF06B6D4,   // cyan
    'packaging': 0xFF8B5CF6,    // violet
    'success': 0xFF10B981,      // emerald
    'failed': 0xFFEF4444,       // red
    'canceled': 0xFF6B7280,     // gray
  };
  
  // Build Progress Steps
  static const List<String> buildSteps = [
    'created',
    'queued',
    'downloading_source',
    'pre_steps',
    'building',
    'post_steps',
    'packaging',
    'success',
  ];
  
  // Error Messages
  static const String genericError = 'An unexpected error occurred. Please try again.';
  static const String networkError = 'Network error. Please check your connection and try again.';
  static const String fileUploadError = 'Failed to upload file. Please try again.';
  static const String jobCreationError = 'Failed to create build job. Please try again.';
  
  // Success Messages
  static const String jobCreatedSuccess = 'Build job created successfully!';
  static const String jobCanceledSuccess = 'Build job canceled successfully.';
  static const String fileUploadSuccess = 'File uploaded successfully.';
  
  // Validation Messages
  static const String invalidFileType = 'Please select a valid .zip file.';
  static const String fileTooLarge = 'File size must be less than 100 MB.';
  static const String invalidUrl = 'Please enter a valid HTTPS URL.';
  static const String invalidCommand = 'Commands must start with "flutter" or "dart".';
  static const String emptyField = 'This field cannot be empty.';
  
  // Feature Flags
  static const bool enableGitRepoSource = false; // Not implemented yet
  static const bool enableWebSocketLogs = true;
  static const bool enableArtifactDownload = true;
  static const bool enableJobCancellation = true;
}