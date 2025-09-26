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

      // Build the flutterflow export-code command
      final command = [
        'flutterflow',
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

  /// Checks if FlutterFlow CLI is installed and available
  Future<void> _checkFlutterFlowCLI() async {
    try {
      final result = await Process.run('flutterflow', ['-h']);
      if (result.exitCode != 0) {
        throw Exception('FlutterFlow CLI not found or not working properly');
      }
      _logger.info('FlutterFlow CLI is available: ${result.stdout}');
    } catch (e) {
      throw Exception(
          'FlutterFlow CLI is not installed. Please install it using: npm install -g flutterflow-cli');
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
