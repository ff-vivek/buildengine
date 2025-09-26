import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import '../models/requests.dart';
import '../services/storage_service.dart';
import '../config/environment_config.dart';

final _logger = Logger('ArtifactHandler');

class ArtifactHandler {
  final StorageService _storageService;

  ArtifactHandler(this._storageService);

  Future<Response> getArtifactUrl(Request request) async {
    try {
      final jobId = request.params['jobId'];
      if (jobId == null) {
        return Response.badRequest(
          body: jsonEncode({'message': 'jobId is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check if artifact exists
      final artifactExists = await _storageService.artifactExists(jobId);
      if (!artifactExists) {
        return Response.notFound(
          jsonEncode({'message': 'No artifact available for this job'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Return the download URL
      final baseUrl = EnvironmentConfig.baseUrl;
      final downloadUrl = '$baseUrl/v1/jobs/$jobId/artifact/download';

      final response = ArtifactResponse(url: downloadUrl);

      return Response.ok(
        jsonEncode(response.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      _logger.severe('Failed to get artifact URL: $e');
      return Response.internalServerError(
        body: jsonEncode({'message': 'Failed to get artifact URL'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> downloadArtifact(Request request) async {
    try {
      final jobId = request.params['jobId'];
      if (jobId == null) {
        return Response.badRequest(
          body: jsonEncode({'message': 'jobId is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check if artifact exists
      final artifactExists = await _storageService.artifactExists(jobId);
      if (!artifactExists) {
        return Response.notFound(
          jsonEncode({'message': 'No artifact available for this job'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get the artifact file path
      final fileName = '${jobId}_artifact.zip';
      final artifactsDir =
          path.join(EnvironmentConfig.localStoragePath, 'artifacts');
      final file = File(path.join(artifactsDir, fileName));

      if (!await file.exists()) {
        return Response.notFound(
          jsonEncode({'message': 'Artifact file not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Serve the file directly
      final bytes = await file.readAsBytes();
      return Response.ok(
        bytes,
        headers: {
          'Content-Type': 'application/zip',
          'Content-Disposition': 'attachment; filename="$fileName"',
          'Content-Length': bytes.length.toString(),
        },
      );
    } catch (e) {
      _logger.severe('Failed to download artifact: $e');
      return Response.internalServerError(
        body: jsonEncode({'message': 'Failed to download artifact'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
