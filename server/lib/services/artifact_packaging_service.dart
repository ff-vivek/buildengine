import 'dart:io';
import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';

import 'storage_service.dart';

final _logger = Logger('ArtifactPackagingService');

class ArtifactPackagingService {
  final StorageService _storageService;
  final String _workspaceDir;

  ArtifactPackagingService(this._storageService, {String? workspaceDir})
      : _workspaceDir = workspaceDir ?? 'workspace';

  /// Packages build artifacts and stores them
  Future<String> packageAndStoreArtifacts(
      String jobId, String buildPath) async {
    try {
      _logger.info('Packaging artifacts for job: $jobId');
      print('   - Job ID: $jobId');
      print('   - Build path: $buildPath');

      // Create artifact package
      print('   - Creating artifact package...');
      final artifactData = await _createArtifactPackage(jobId, buildPath);
      print('   - Artifact package created (${artifactData.length} bytes)');

      // Store the artifact
      print('   - Storing artifact in storage backend...');
      final artifactUrl =
          await _storageService.storeArtifact(jobId, artifactData);

      _logger
          .info('Artifacts packaged and stored successfully for job: $jobId');
      print('   - Artifact stored successfully');
      print('   - Artifact URL: $artifactUrl');
      return artifactUrl;
    } catch (e) {
      print('   ❌ Failed to package artifacts: $e');
      _logger.severe('Failed to package artifacts for job $jobId: $e');
      rethrow;
    }
  }

  Future<Uint8List> _createArtifactPackage(
      String jobId, String buildPath) async {
    final archive = Archive();
    final jobWorkspaceDir = path.join(_workspaceDir, jobId);
    final workspaceDirectory = Directory(jobWorkspaceDir);
    if (!await workspaceDirectory.exists()) {
      await workspaceDirectory.create(recursive: true);
    }

    // Find the Flutter project directory for consistent artifact handling
    final flutterProjectDir = await _findFlutterProjectDir(buildPath);

    // Add the main build artifact (file or directory)
    await _addBuildArtifact(archive, buildPath);


    // Create ZIP archive
    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive);

    if (zipData == null) {
      throw Exception('Failed to create ZIP archive');
    }

    return Uint8List.fromList(zipData);
  }

  /// Adds the main build artifact to the archive (zips the entire build folder)
  Future<void> _addBuildArtifact(Archive archive, String buildPath) async {
    try {
      // Find the Flutter project directory by looking for pubspec.yaml
      final flutterProjectDir = await _findFlutterProjectDir(buildPath);
      final buildDir = Directory(path.join(flutterProjectDir, 'build'));

      if (await buildDir.exists()) {
        // Add the entire build directory to the archive
        await _addDirectoryToArchive(archive, buildDir, 'build');
        _logger.info(
            'Added build directory to archive: ${buildDir.path} -> build/');
      } else {
        _logger.warning('Build directory not found: ${buildDir.path}');

        // Fallback: try to add the specific build path if build directory doesn't exist
        if (await File(buildPath).exists()) {
          final fileName = path.basename(buildPath);
          await _addFileToArchive(archive, buildPath, fileName);
          _logger.info(
              'Added build file to archive (fallback): $buildPath -> $fileName');
        } else if (await Directory(buildPath).exists()) {
          final dirName = path.basename(buildPath);
          await _addDirectoryToArchive(archive, Directory(buildPath), dirName);
          _logger.info(
              'Added build directory to archive (fallback): $buildPath -> $dirName/');
        }
      }
    } catch (e) {
      _logger.warning('Failed to add build artifact: $buildPath - $e');
    }
  }

  /// Finds the Flutter project directory by looking for pubspec.yaml
  Future<String> _findFlutterProjectDir(String buildPath) async {
    // Start from the build path and work backwards to find the project root
    String currentPath = buildPath;

    while (
        currentPath.isNotEmpty && currentPath != path.rootPrefix(currentPath)) {
      final pubspecFile = File(path.join(currentPath, 'pubspec.yaml'));
      if (await pubspecFile.exists()) {
        return currentPath;
      }
      currentPath = path.dirname(currentPath);
    }

    // If not found, return the directory containing the build path
    return path.dirname(buildPath);
  }

  Future<void> _addFileToArchive(
      Archive archive, String filePath, String archivePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final fileArchive = ArchiveFile(archivePath, bytes.length, bytes);
        archive.addFile(fileArchive);
        _logger.info('Added file to archive: $filePath -> $archivePath');
      } else {
        _logger.warning('File not found for archive: $filePath');
      }
    } catch (e) {
      _logger.warning('Failed to add file to archive: $filePath - $e');
    }
  }

  Future<void> _addBuildLogs(Archive archive, String workspaceDir) async {
    try {
      // Look for common log files
      final logFiles = [
        'build.log',
        'flutter_build.log',
        'pub.log',
        'gradle.log',
      ];

      for (final logFile in logFiles) {
        final logPath = path.join(workspaceDir, logFile);
        await _addFileToArchive(archive, logPath, 'logs/$logFile');
      }

      // Add any logs from build directory
      final buildDir = Directory(path.join(workspaceDir, 'build'));
      if (await buildDir.exists()) {
        await _addDirectoryToArchive(archive, buildDir, 'build/');
      }
    } catch (e) {
      _logger.warning('Failed to add build logs: $e');
    }
  }

  Future<void> _addBuildMetadata(
      Archive archive, String jobId, String buildPath) async {
    try {
      // Calculate build size - handle both files and directories
      int buildSize;
      if (await File(buildPath).exists()) {
        // It's a file (APK, etc.)
        buildSize = await File(buildPath).length();
      } else if (await Directory(buildPath).exists()) {
        // It's a directory (web build, etc.)
        buildSize = await _calculateDirectorySize(buildPath);
      } else {
        buildSize = 0;
      }

      final metadata = {
        'jobId': jobId,
        'buildPath': buildPath,
        'buildTime': DateTime.now().toUtc().toIso8601String(),
        'buildFileSize': buildSize,
        'buildFileName': path.basename(buildPath),
      };

      final metadataJson =
          '${metadata.entries.map((e) => '${e.key}: ${e.value}').join('\n')}\n';
      final metadataBytes = metadataJson.codeUnits;

      final metadataFile = ArchiveFile(
          'build_metadata.txt', metadataBytes.length, metadataBytes);
      archive.addFile(metadataFile);

      _logger.info('Added build metadata to archive');
    } catch (e) {
      _logger.warning('Failed to add build metadata: $e');
    }
  }

  /// Calculates the total size of a directory recursively
  Future<int> _calculateDirectorySize(String dirPath) async {
    int totalSize = 0;
    final directory = Directory(dirPath);

    if (!await directory.exists()) {
      return 0;
    }

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        try {
          totalSize += await entity.length();
        } catch (e) {
          // Skip files that can't be read
          _logger.warning('Could not read file size for ${entity.path}: $e');
        }
      }
    }

    return totalSize;
  }

  Future<void> _addDirectoryToArchive(
      Archive archive, Directory directory, String archivePrefix) async {
    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final relativePath = path.relative(entity.path, from: directory.path);
          final archivePath = '$archivePrefix/$relativePath';
          await _addFileToArchive(archive, entity.path, archivePath);
        }
      }
    } catch (e) {
      _logger.warning(
          'Failed to add directory to archive: ${directory.path} - $e');
    }
  }

  bool _shouldIncludeFile(String fileName) {
    // Include common project files
    const includeExtensions = [
      '.dart',
      '.yaml',
      '.yml',
      '.json',
      '.md',
      '.txt'
    ];
    const includeFiles = [
      'pubspec.yaml',
      'pubspec.lock',
      'README.md',
      'CHANGELOG.md'
    ];

    if (includeFiles.contains(fileName)) return true;

    final extension = path.extension(fileName);
    return includeExtensions.contains(extension);
  }

  /// Clean up temporary files
  Future<void> cleanup(String jobId) async {
    try {
      final jobWorkspaceDir = path.join(_workspaceDir, jobId);
      final tempDir = Directory(path.join(jobWorkspaceDir, 'temp_artifacts'));

      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        _logger.info('Cleaned up temporary artifacts for job: $jobId');
      }
    } catch (e) {
      _logger
          .warning('Failed to cleanup temporary artifacts for job $jobId: $e');
    }
  }
}
