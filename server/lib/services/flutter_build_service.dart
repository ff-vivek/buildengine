import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import '../models/build_config.dart';
import '../models/enums.dart';

final _logger = Logger('FlutterBuildService');

class FlutterBuildService {
  final String _workspaceDir;

  FlutterBuildService({String? workspaceDir})
      : _workspaceDir = workspaceDir ?? 'workspace';

  /// Executes pre-build steps
  Future<void> executePreSteps(List<String> preSteps, String jobId) async {
    if (preSteps.isEmpty) {
      print('   - No pre-steps to execute');
      return;
    }

    _logger.info('Executing pre-steps for job: $jobId');
    print('   - Executing ${preSteps.length} pre-step commands');

    for (int i = 0; i < preSteps.length; i++) {
      final step = preSteps[i];
      try {
        print('     ${i + 1}. Running: $step');
        _logger.info('Executing pre-step: $step');
        final result = await _executeCommand(step, jobId);

        if (result.exitCode != 0) {
          print('     ❌ Pre-step failed: $step');
          print('     Error: ${result.stderr}');
          throw Exception('Pre-step failed: $step\n${result.stderr}');
        }

        print('     ✅ Pre-step completed: $step');
        if (result.stdout.isNotEmpty) {
          print('     Output: ${result.stdout}');
        }
        _logger.info('Pre-step completed: $step');
      } catch (e) {
        print('     ❌ Pre-step error: $step - $e');
        _logger.severe('Pre-step error: $step - $e');
        rethrow;
      }
    }
  }

  /// Builds the Flutter application
  Future<String> buildFlutterApp(BuildConfig config, String jobId) async {
    final jobWorkspaceDir = path.join(_workspaceDir, jobId);

    try {
      _logger.info('Building Flutter app for job: $jobId');
      print('   - Workspace directory: $jobWorkspaceDir');

      // Ensure we're in the correct directory
      if (!await Directory(jobWorkspaceDir).exists()) {
        throw Exception('Workspace directory not found: $jobWorkspaceDir');
      }

      // Check if Flutter is available
      print('   - Checking Flutter installation...');
      await _checkFlutterInstallation();
      print('   - Flutter installation verified');

      // Find the actual Flutter project directory
      final flutterProjectDir = await _findFlutterProjectDir(jobWorkspaceDir);
      print('   - Flutter project directory: $flutterProjectDir');

      // Get dependencies
      print('   - Getting Flutter dependencies...');
      await _getDependencies(flutterProjectDir);
      print('   - Dependencies retrieved successfully');

      // Build the app based on build type
      print('   - Starting Flutter build...');
      final buildPath = await _buildApp(config, flutterProjectDir);

      _logger.info('Flutter app built successfully: $buildPath');
      return buildPath;
    } catch (e) {
      print('   ❌ Failed to build Flutter app: $e');
      _logger.severe('Failed to build Flutter app: $e');
      rethrow;
    }
  }

  /// Executes post-build steps
  Future<void> executePostSteps(List<String> postSteps, String jobId) async {
    if (postSteps.isEmpty) {
      print('   - No post-steps to execute');
      return;
    }

    _logger.info('Executing post-steps for job: $jobId');
    print('   - Executing ${postSteps.length} post-step commands');

    for (int i = 0; i < postSteps.length; i++) {
      final step = postSteps[i];
      try {
        print('     ${i + 1}. Running: $step');
        _logger.info('Executing post-step: $step');
        final result = await _executeCommand(step, jobId);

        if (result.exitCode != 0) {
          print('     ❌ Post-step failed: $step');
          print('     Error: ${result.stderr}');
          throw Exception('Post-step failed: $step\n${result.stderr}');
        }

        print('     ✅ Post-step completed: $step');
        if (result.stdout.isNotEmpty) {
          print('     Output: ${result.stdout}');
        }
        _logger.info('Post-step completed: $step');
      } catch (e) {
        print('     ❌ Post-step error: $step - $e');
        _logger.severe('Post-step error: $step - $e');
        rethrow;
      }
    }
  }

  Future<void> _checkFlutterInstallation() async {
    try {
      final result = await Process.run('flutter', ['--version']);
      if (result.exitCode != 0) {
        throw Exception('Flutter is not installed or not in PATH');
      }
      _logger.info('Flutter installation verified');
    } catch (e) {
      throw Exception('Flutter installation check failed: $e');
    }
  }

  /// Finds the actual Flutter project directory within the workspace
  /// Handles cases where FlutterFlow CLI creates nested project folders
  Future<String> _findFlutterProjectDir(String workspaceDir) async {
    // Check if the workspace directory itself is a Flutter project
    final pubspecFile = File(path.join(workspaceDir, 'pubspec.yaml'));
    if (await pubspecFile.exists()) {
      _logger
          .info('Found Flutter project directly in workspace: $workspaceDir');
      return workspaceDir;
    }

    // Look for Flutter projects in subdirectories
    final directory = Directory(workspaceDir);
    if (!await directory.exists()) {
      throw Exception('Workspace directory not found: $workspaceDir');
    }

    await for (final entity in directory.list()) {
      if (entity is Directory) {
        final subDir = entity.path;
        final subPubspecFile = File(path.join(subDir, 'pubspec.yaml'));

        if (await subPubspecFile.exists()) {
          _logger.info('Found Flutter project in subdirectory: $subDir');
          return subDir;
        }
      }
    }

    throw Exception('No Flutter project found in workspace: $workspaceDir');
  }

  Future<void> _getDependencies(String workspaceDir) async {
    _logger.info('Getting Flutter dependencies');

    final result = await Process.run(
      'flutter',
      ['pub', 'get'],
      workingDirectory: workspaceDir,
    );

    if (result.exitCode != 0) {
      throw Exception('Failed to get dependencies: ${result.stderr}');
    }

    _logger.info('Dependencies retrieved successfully');
  }

  Future<String> _buildApp(BuildConfig config, String workspaceDir) async {
    final buildType = config.buildType;
    final platform = config.platform;
    final targetFile = config.targetFile;

    List<String> buildCommand;
    String outputPath;

    // Build command based on platform
    switch (platform) {
      case Platform.web:
        switch (buildType) {
          case BuildType.release:
            buildCommand = ['build', 'web', '--release'];
            outputPath = path.join(workspaceDir, 'build', 'web');
            break;
          case BuildType.debug:
            buildCommand = ['build', 'web', '--debug'];
            outputPath = path.join(workspaceDir, 'build', 'web');
            break;
          case BuildType.profile:
            buildCommand = ['build', 'web', '--profile'];
            outputPath = path.join(workspaceDir, 'build', 'web');
            break;
        }
        break;
      case Platform.android:
        switch (buildType) {
          case BuildType.release:
            buildCommand = ['build', 'apk', '--release'];
            outputPath = path.join(workspaceDir, 'build', 'app', 'outputs',
                'flutter-apk', 'app-release.apk');
            break;
          case BuildType.debug:
            buildCommand = ['build', 'apk', '--debug'];
            outputPath = path.join(workspaceDir, 'build', 'app', 'outputs',
                'flutter-apk', 'app-debug.apk');
            break;
          case BuildType.profile:
            buildCommand = ['build', 'apk', '--profile'];
            outputPath = path.join(workspaceDir, 'build', 'app', 'outputs',
                'flutter-apk', 'app-profile.apk');
            break;
        }
        break;
      case Platform.ios:
        switch (buildType) {
          case BuildType.release:
            buildCommand = ['build', 'ios', '--release'];
            outputPath = path.join(
                workspaceDir, 'build', 'ios', 'iphoneos', 'Runner.app');
            break;
          case BuildType.debug:
            buildCommand = ['build', 'ios', '--debug'];
            outputPath = path.join(
                workspaceDir, 'build', 'ios', 'iphoneos', 'Runner.app');
            break;
          case BuildType.profile:
            buildCommand = ['build', 'ios', '--profile'];
            outputPath = path.join(
                workspaceDir, 'build', 'ios', 'iphoneos', 'Runner.app');
            break;
        }
        break;
      case Platform.macos:
        switch (buildType) {
          case BuildType.release:
            buildCommand = ['build', 'macos', '--release'];
            outputPath = path.join(workspaceDir, 'build', 'macos', 'Build',
                'Products', 'Release', 'buildbeacon.app');
            break;
          case BuildType.debug:
            buildCommand = ['build', 'macos', '--debug'];
            outputPath = path.join(workspaceDir, 'build', 'macos', 'Build',
                'Products', 'Debug', 'buildbeacon.app');
            break;
          case BuildType.profile:
            buildCommand = ['build', 'macos', '--profile'];
            outputPath = path.join(workspaceDir, 'build', 'macos', 'Build',
                'Products', 'Profile', 'buildbeacon.app');
            break;
        }
        break;
      case Platform.windows:
        switch (buildType) {
          case BuildType.release:
            buildCommand = ['build', 'windows', '--release'];
            outputPath = path.join(workspaceDir, 'build', 'windows', 'runner',
                'Release', 'buildbeacon.exe');
            break;
          case BuildType.debug:
            buildCommand = ['build', 'windows', '--debug'];
            outputPath = path.join(workspaceDir, 'build', 'windows', 'runner',
                'Debug', 'buildbeacon.exe');
            break;
          case BuildType.profile:
            buildCommand = ['build', 'windows', '--profile'];
            outputPath = path.join(workspaceDir, 'build', 'windows', 'runner',
                'Profile', 'buildbeacon.exe');
            break;
        }
        break;
      case Platform.linux:
        switch (buildType) {
          case BuildType.release:
            buildCommand = ['build', 'linux', '--release'];
            outputPath = path.join(workspaceDir, 'build', 'linux', 'x64',
                'release', 'bundle', 'buildbeacon');
            break;
          case BuildType.debug:
            buildCommand = ['build', 'linux', '--debug'];
            outputPath = path.join(workspaceDir, 'build', 'linux', 'x64',
                'debug', 'bundle', 'buildbeacon');
            break;
          case BuildType.profile:
            buildCommand = ['build', 'linux', '--profile'];
            outputPath = path.join(workspaceDir, 'build', 'linux', 'x64',
                'profile', 'bundle', 'buildbeacon');
            break;
        }
        break;
    }

    // Add target file if specified
    if (targetFile.isNotEmpty && targetFile != 'lib/main.dart') {
      buildCommand.addAll(['--target', targetFile]);
    }

    _logger.info(
        'Building Flutter app with command: flutter ${buildCommand.join(' ')}');

    final result = await Process.run(
      'flutter',
      buildCommand,
      workingDirectory: workspaceDir,
    );

    if (result.exitCode != 0) {
      throw Exception('Flutter build failed: ${result.stderr}');
    }

    // Verify the output exists (file for mobile/desktop, directory for web/macos)
    if (platform == Platform.web || platform == Platform.macos) {
      final outputDir = Directory(outputPath);
      if (!await outputDir.exists()) {
        throw Exception('Build output directory not found: $outputPath');
      }
    } else {
      final outputFile = File(outputPath);
      if (!await outputFile.exists()) {
        throw Exception('Build output file not found: $outputPath');
      }
    }

    return outputPath;
  }

  Future<ProcessResult> _executeCommand(String command, String jobId) async {
    final jobWorkspaceDir = path.join(_workspaceDir, jobId);

    // Find the actual Flutter project directory
    final flutterProjectDir = await _findFlutterProjectDir(jobWorkspaceDir);

    // Parse command and arguments
    final parts = command.split(' ');
    final executable = parts.first;
    final arguments = parts.length > 1 ? parts.sublist(1) : <String>[];

    return await Process.run(
      executable,
      arguments,
      workingDirectory: flutterProjectDir,
    );
  }

  /// Clean up build artifacts
  Future<void> cleanup(String jobId) async {
    try {
      // final jobWorkspaceDir = path.join(_workspaceDir, jobId);
      // final buildDir = path.join(jobWorkspaceDir, 'build');

      // final directory = Directory(buildDir);
      // if (await directory.exists()) {
      //   await directory.delete(recursive: true);
      _logger.info('Cleaned up build artifacts for job: $jobId');
      // }
    } catch (e) {
      _logger.warning('Failed to cleanup build artifacts for job $jobId: $e');
    }
  }
}
