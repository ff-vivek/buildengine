import 'package:file_picker/file_picker.dart';
import 'package:buildbeacon/utils/constants.dart';

/// Validation utilities for BuildEngine
class Validators {
  /// Validate file upload (PlatformFile)
  static String? validateFile(PlatformFile? file) {
    if (file == null) {
      return 'Please select a file';
    }

    // Check file extension using the file name
    final extension = file.name.toLowerCase().split('.').last;
    if (!AppConstants.allowedFileExtensions.contains('.$extension')) {
      return AppConstants.invalidFileType;
    }

    // Check file size using PlatformFile.size
    final fileSize = file.size;
    if (fileSize <= 0) {
      return AppConstants.invalidFileType;
    }
    if (fileSize > AppConstants.maxFileSize) {
      return AppConstants.fileTooLarge;
    }

    return null;
  }

  /// Validate a picked file by its name and size (web-safe)
  static String? validatePickedFileMeta({required String name, required int size}) {
    final extension = name.toLowerCase().split('.').last;
    if (!AppConstants.allowedFileExtensions.contains('.$extension')) {
      return AppConstants.invalidFileType;
    }
    if (size <= 0) {
      return AppConstants.invalidFileType;
    }
    if (size > AppConstants.maxFileSize) {
      return AppConstants.fileTooLarge;
    }
    return null;
  }

  /// Validate URL (must be HTTPS)
  static String? validateUrl(String? url) {
    if (url == null || url.isEmpty) {
      return AppConstants.emptyField;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') {
      return AppConstants.invalidUrl;
    }

    return null;
  }

  /// Validate FlutterFlow URL
  static String? validateFlutterFlowUrl(String? url) {
    final basicValidation = validateUrl(url);
    if (basicValidation != null) return basicValidation;

    if (!url!.contains('app.flutterflow.io')) {
      return 'Please enter a valid FlutterFlow project URL';
    }

    return null;
  }

  /// Validate Git URL
  static String? validateGitUrl(String? url) {
    if (url == null || url.isEmpty) return null; // Optional field

    final uri = Uri.tryParse(url);
    if (uri == null) {
      return 'Please enter a valid Git URL';
    }

    // Allow both HTTPS and Git protocols
    if (!['https', 'git'].contains(uri.scheme)) {
      return 'Git URL must use HTTPS or Git protocol';
    }

    return null;
  }

  /// Validate Flutter/Dart command
  static String? validateCommand(String? command) {
    if (command == null || command.isEmpty) {
      return AppConstants.emptyField;
    }

    final trimmed = command.trim();
    
    // Check if command starts with flutter or dart
    if (!trimmed.startsWith('flutter ') && !trimmed.startsWith('dart ')) {
      return AppConstants.invalidCommand;
    }

    // Check for dangerous characters/commands
    final dangerous = ['>', '<', '|', '&', ';', '`', '\$', '(', ')'];
    for (final char in dangerous) {
      if (trimmed.contains(char)) {
        return 'Commands cannot contain special characters like $char';
      }
    }

    return null;
  }

  /// Validate target file path
  static String? validateTargetFile(String? path) {
    if (path == null || path.isEmpty) {
      return AppConstants.emptyField;
    }

    // Check if it's a valid Dart file path
    if (!path.endsWith('.dart')) {
      return 'Target file must be a .dart file';
    }

    // Check for valid path format
    if (path.contains('..') || path.startsWith('/')) {
      return 'Please enter a valid relative file path';
    }

    return null;
  }

  /// Validate Flutter version string
  static String? validateFlutterVersion(String? version) {
    if (version == null || version.isEmpty) {
      return null; // Use default
    }

    if (version == 'default') {
      return null; // Valid default option
    }

    // Basic semantic version pattern
    final versionRegex = RegExp(r'^\d+\.\d+\.\d+(-.*)?$');
    if (!versionRegex.hasMatch(version)) {
      return 'Please enter a valid version (e.g., 3.24.3) or use "default"';
    }

    return null;
  }

  /// Validate branch name
  static String? validateBranch(String? branch) {
    if (branch == null || branch.isEmpty) {
      return null; // Use default
    }

    if (branch == AppConstants.noBranch) {
      return null; // Valid for non-Git sources
    }

    // Check for valid Git branch name
    if (branch.contains(' ') || 
        branch.startsWith('-') || 
        branch.endsWith('.') ||
        branch.contains('..')) {
      return 'Please enter a valid branch name';
    }

    return null;
  }

  /// Validate access token (basic check)
  static String? validateToken(String? token) {
    if (token == null || token.isEmpty) {
      return AppConstants.emptyField;
    }

    if (token.length < 10) {
      return 'Token appears to be too short';
    }

    return null;
  }

  /// Sanitize command to remove dangerous elements
  static String sanitizeCommand(String command) {
    return command.trim()
        .replaceAll(RegExp(r'[;&|`$(){}[\]<>]'), '') // Remove dangerous chars
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Check if string is a valid email (basic check)
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  /// Mask sensitive token for display
  static String maskToken(String token) {
    if (token.length <= 8) {
      return '*' * token.length;
    }
    final visible = token.substring(0, 4);
    final masked = '*' * (token.length - 8);
    final end = token.substring(token.length - 4);
    return '$visible$masked$end';
  }
}