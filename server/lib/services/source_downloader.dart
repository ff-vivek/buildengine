import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';

import '../models/build_source.dart';
import '../models/enums.dart';
import 'storage_service.dart';

final _logger = Logger('SourceDownloader');

class SourceDownloader {
  final StorageService _storageService;
  final String _workspaceDir;

  SourceDownloader(this._storageService, {String? workspaceDir})
      : _workspaceDir = workspaceDir ?? 'workspace';

  /// Downloads and extracts source code based on the build source type
  Future<String> downloadSource(BuildSource source, String jobId) async {
    final jobWorkspaceDir = path.join(_workspaceDir, jobId);
    await _ensureDirectoryExists(jobWorkspaceDir);

    print('📁 Creating workspace directory: $jobWorkspaceDir');

    switch (source.type) {
      case SourceType.uploadZip:
        print('📦 Downloading from uploaded ZIP file...');
        return await _downloadFromUpload(source, jobWorkspaceDir);
      case SourceType.flutterFlow:
        print('🌊 Downloading from FlutterFlow...');
        return await _downloadFromFlutterFlow(source, jobWorkspaceDir);
      case SourceType.gitRepo:
        print('🔗 Cloning Git repository...');
        return await _downloadFromGit(source, jobWorkspaceDir);
    }
  }

  Future<String> _downloadFromUpload(
      BuildSource source, String workspaceDir) async {
    try {
      _logger.info('Downloading source from upload: ${source.uploadId}');

      final uploadData = await _storageService.getUpload(source.uploadId!);
      if (uploadData == null) {
        throw Exception('Upload not found: ${source.uploadId}');
      }

      // Extract ZIP file
      final archive = ZipDecoder().decodeBytes(uploadData);

      // Check if all files are under a single root directory
      final rootDirectories = <String>{};
      for (final file in archive) {
        if (file.name.isNotEmpty) {
          final parts = file.name.split('/');
          if (parts.isNotEmpty) {
            rootDirectories.add(parts.first);
          }
        }
      }

      // Determine project name and create nested structure like FlutterFlow
      String projectName;
      if (rootDirectories.length == 1 && rootDirectories.first.isNotEmpty) {
        // Use the root directory name as project name
        projectName = rootDirectories.first;
      } else {
        // Generate a project name based on upload ID
        projectName = 'uploaded_project_${source.uploadId!.substring(0, 8)}';
      }

      // Create project directory (similar to FlutterFlow structure)
      final projectDir = path.join(workspaceDir, projectName);
      await Directory(projectDir).create(recursive: true);

      // Extract files to the project directory
      for (final file in archive) {
        String targetPath;
        if (rootDirectories.length == 1 &&
            file.name.startsWith('${rootDirectories.first}/')) {
          // Remove the root directory prefix and place in project folder
          targetPath = path.join(projectDir,
              file.name.substring(rootDirectories.first.length + 1));
        } else {
          // Place directly in project folder
          targetPath = path.join(projectDir, file.name);
        }

        if (file.isFile) {
          final data = file.content as List<int>;
          await File(targetPath).create(recursive: true);
          await File(targetPath).writeAsBytes(data);
        }
      }

      _logger.info(
          'Successfully extracted upload to project directory: $projectDir');
      return workspaceDir;
    } catch (e) {
      _logger.severe('Failed to download from upload: $e');
      rethrow;
    }
  }

  Future<String> _downloadFromFlutterFlow(
      BuildSource source, String workspaceDir) async {
    try {
      _logger.info(
          'Downloading source from FlutterFlow CLI: ${source.ffProjectId}');

      // Check if FlutterFlow CLI is installed
      await _checkFlutterFlowCLI();

      // Find the flutterflow command
      String flutterflowCommand = await _findFlutterFlowCommand();

      // Build the flutterflow export-code command
      final command = [
        flutterflowCommand,
        'export-code',
        '--project',
        source.ffProjectId!,
        '--endpoint',
        source.ffEndpoint!,
        '--project-environment',
        source.ffProjectEnvironment ?? 'Production',
        '--token',
        source.ffToken!,
      ];

      // Add --include-assets flag if requested
      if (source.ffIncludeAssets) {
        command.add('--include-assets');
      }

      _logger.info('Running FlutterFlow CLI command: ${command.join(' ')}');

      // Run the FlutterFlow CLI command
      final result = await Process.run(
        command.first,
        command.sublist(1),
        workingDirectory: workspaceDir,
      );

      if (result.exitCode != 0) {
        throw Exception('FlutterFlow CLI failed: ${result.stderr}');
      }

      _logger.info('Successfully downloaded FlutterFlow project using CLI');
      return workspaceDir;
    } catch (e) {
      _logger.severe('Failed to download from FlutterFlow CLI: $e');
      rethrow;
    }
  }

  /// Checks if FlutterFlow CLI is installed and available, installs it if not
  Future<void> _checkFlutterFlowCLI() async {
    try {
      final result = await Process.run('flutterflow', ['-h']);
      if (result.exitCode != 0) {
        throw Exception('FlutterFlow CLI not found or not working properly');
      }
      _logger.info('FlutterFlow CLI is available: ${result.stdout}');
    } catch (e) {
      _logger.warning('FlutterFlow CLI not found, attempting to install...');
      await _installFlutterFlowCLI();
      
      // Verify installation after attempting to install
      try {
        // Try to find flutterflow command using which
        final whichResult = await Process.run('which', ['flutterflow']);
        String flutterflowCommand = 'flutterflow';
        
        if (whichResult.exitCode == 0) {
          flutterflowCommand = whichResult.stdout.trim();
          _logger.info('Found flutterflow command at: $flutterflowCommand');
        } else {
          // Try to find it in npm global bin directory
          final npmBinResult = await Process.run('npm', ['config', 'get', 'prefix']);
          if (npmBinResult.exitCode == 0) {
            final npmPrefix = npmBinResult.stdout.trim();
            final globalBinPath = path.join(npmPrefix, 'bin');
            final flutterflowPath = path.join(globalBinPath, 'flutterflow');
            
            if (await File(flutterflowPath).exists()) {
              flutterflowCommand = flutterflowPath;
              _logger.info('Found flutterflow command at npm global bin: $flutterflowCommand');
            }
          }
        }
        
        final verifyResult = await Process.run(flutterflowCommand, ['-h']);
        if (verifyResult.exitCode != 0) {
          throw Exception('FlutterFlow CLI installation failed or not working properly');
        }
        _logger.info('FlutterFlow CLI successfully installed and verified');
      } catch (verifyError) {
        throw Exception(
            'Failed to install FlutterFlow CLI. Please install it manually using: dart pub global activate flutterflow_cli');
      }
    }
  }

  /// Installs FlutterFlow CLI using dart pub global activate
  Future<void> _installFlutterFlowCLI() async {
    try {
      _logger.info('Installing FlutterFlow CLI using dart pub global activate...');
      
      // First check if dart is available
      final dartCheck = await Process.run('dart', ['--version']);
      if (dartCheck.exitCode != 0) {
        throw Exception('Dart is not available. Please install Dart SDK first.');
      }
      
      _logger.info('Dart is available: ${dartCheck.stdout}');
      
      // Install FlutterFlow CLI globally using dart pub
      final installResult = await Process.run('dart', ['pub', 'global', 'activate', 'flutterflow_cli']);
      
      if (installResult.exitCode != 0) {
        _logger.severe('dart pub global activate failed: ${installResult.stderr}');
        throw Exception('Failed to install FlutterFlow CLI: ${installResult.stderr}');
      }
      
      _logger.info('FlutterFlow CLI installation completed: ${installResult.stdout}');
      
      // Update PATH by refreshing environment
      await _refreshEnvironment();
      
    } catch (e) {
      _logger.severe('Failed to install FlutterFlow CLI: $e');
      rethrow;
    }
  }

  /// Finds the flutterflow command path
  Future<String> _findFlutterFlowCommand() async {
    try {
      // Try to find flutterflow command using which
      final whichResult = await Process.run('which', ['flutterflow']);
      
      if (whichResult.exitCode == 0) {
        final flutterflowCommand = whichResult.stdout.trim();
        _logger.info('Found flutterflow command at: $flutterflowCommand');
        return flutterflowCommand;
      }
      
      // Try to find it in dart pub global bin directory
      final dartBinResult = await Process.run('dart', ['pub', 'global', 'list']);
      if (dartBinResult.exitCode == 0) {
        // Check if flutterflow_cli is in the global packages
        if (dartBinResult.stdout.contains('flutterflow_cli')) {
          // Get the dart pub global bin directory
          final dartGlobalResult = await Process.run('dart', ['pub', 'global', 'list', '--executable']);
          if (dartGlobalResult.exitCode == 0) {
            final lines = dartGlobalResult.stdout.split('\n');
            for (final line in lines) {
              if (line.contains('flutterflow')) {
                final parts = line.split(' ');
                if (parts.isNotEmpty) {
                  final flutterflowCommand = parts.first.trim();
                  _logger.info('Found flutterflow command in dart global: $flutterflowCommand');
                  return flutterflowCommand;
                }
              }
            }
          }
        }
      }
      
      // Fallback to just 'flutterflow' and hope it's in PATH
      _logger.warning('Could not find flutterflow command, using default: flutterflow');
      return 'flutterflow';
    } catch (e) {
      _logger.warning('Error finding flutterflow command: $e');
      return 'flutterflow';
    }
  }

  /// Refreshes the environment to pick up newly installed global packages
  Future<void> _refreshEnvironment() async {
    try {
      // Get the dart pub global bin directory
      final dartGlobalResult = await Process.run('dart', ['pub', 'global', 'list', '--executable']);
      if (dartGlobalResult.exitCode == 0) {
        final lines = dartGlobalResult.stdout.split('\n');
        for (final line in lines) {
          if (line.contains('flutterflow')) {
            final parts = line.split(' ');
            if (parts.isNotEmpty) {
              final flutterflowPath = parts.first.trim();
              _logger.info('FlutterFlow CLI found at: $flutterflowPath');
              break;
            }
          }
        }
      }
      
      // Also check if flutterflow_cli package is installed
      final dartListResult = await Process.run('dart', ['pub', 'global', 'list']);
      if (dartListResult.exitCode == 0) {
        if (dartListResult.stdout.contains('flutterflow_cli')) {
          _logger.info('FlutterFlow CLI package is installed globally');
        } else {
          _logger.warning('FlutterFlow CLI package not found in global packages');
        }
      }
    } catch (e) {
      _logger.warning('Failed to refresh environment: $e');
      // Don't throw here as the installation might still work
    }
  }

  Future<String> _downloadFromGit(
      BuildSource source, String workspaceDir) async {
    try {
      _logger.info('Cloning Git repository: ${source.gitUrl}');

      // Clone the repository
      final result = await Process.run(
        'git',
        ['clone', '--branch', source.branch, source.gitUrl!, workspaceDir],
        workingDirectory: Directory.current.path,
      );

      if (result.exitCode != 0) {
        throw Exception('Git clone failed: ${result.stderr}');
      }

      _logger.info('Successfully cloned Git repository');
      return workspaceDir;
    } catch (e) {
      _logger.severe('Failed to clone Git repository: $e');
      rethrow;
    }
  }

  Future<void> _ensureDirectoryExists(String dir) async {
    final directory = Directory(dir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  /// Clean up workspace directory
  Future<void> cleanup(String jobId) async {
    try {
      final jobWorkspaceDir = path.join(_workspaceDir, jobId);
      final directory = Directory(jobWorkspaceDir);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
        _logger.info('Cleaned up workspace for job: $jobId');
      }
    } catch (e) {
      _logger.warning('Failed to cleanup workspace for job $jobId: $e');
    }
  }
}
