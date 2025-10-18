import 'dart:convert';
import 'dart:typed_data';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_multipart/form_data.dart';
import 'package:logging/logging.dart';

import '../models/requests.dart';
import '../models/upload_record.dart';
import '../services/storage_service.dart';
import '../services/database_service.dart';

final _logger = Logger('UploadHandler');

class UploadHandler {
  final StorageService _storageService;
  final DatabaseService _databaseService;

  UploadHandler(this._storageService, this._databaseService);

  Future<Response> initializeUpload(Request request) async {
    try {
      final uploadId = _storageService.initializeUpload();
      final uploadUrl = _storageService.getUploadUrl(uploadId);

      // Store upload record in database
      final uploadRecord = UploadRecord(
        uploadId: uploadId,
        createdAt: DateTime.now(),
        expiresAt:
            DateTime.now().add(const Duration(hours: 24)), // 24 hour expiry
        status: 'pending',
      );

      await _databaseService.storeUpload(uploadRecord);

      final response = UploadResponse(
        uploadId: uploadId,
        uploadUrl: uploadUrl,
      );

      return Response(
        201,
        body: jsonEncode(response.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      _logger.severe('Failed to initialize upload: $e');
      return Response.internalServerError(
        body: jsonEncode({'message': 'Failed to initialize upload'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> uploadFile(Request request) async {
    try {
      final uploadId = request.params['uploadId'];
      if (uploadId == null) {
        return Response.badRequest(
          body: jsonEncode({'message': 'uploadId is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check if upload exists in database
      if (!await _databaseService.uploadExists(uploadId)) {
        return Response.notFound(
          jsonEncode({'message': 'Upload not found or expired'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Parse multipart request
      if (!request.isMultipartForm) {
        return Response.badRequest(
          body: jsonEncode({'message': 'Request must be multipart/form-data'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      Uint8List? fileData;
      String? filename;
      int totalSize = 0;

      await for (final formData in request.multipartFormData) {
        if (formData.name == 'file') {
          final bytes = <int>[];
          await for (final chunk in formData.part) {
            bytes.addAll(chunk);
            totalSize += chunk.length;
            
            // Check size limit during streaming to avoid memory issues
            const maxSize = 100 * 1024 * 1024; // 100MB
            if (totalSize > maxSize) {
              return Response(
                413,
                body: jsonEncode({'message': 'File too large. Maximum size is 100MB'}),
                headers: {'Content-Type': 'application/json'},
              );
            }
          }
          fileData = Uint8List.fromList(bytes);
          filename = formData.filename;
          break;
        }
      }

      if (fileData == null) {
        return Response.badRequest(
          body: jsonEncode({'message': 'File is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Validate file type (should be ZIP)
      if (filename != null && !filename.toLowerCase().endsWith('.zip')) {
        return Response.badRequest(
          body: jsonEncode({'message': 'Only ZIP files are supported'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Store the file
      final success = await _storageService.storeUpload(uploadId, fileData);
      if (!success) {
        return Response.internalServerError(
          body: jsonEncode({'message': 'Failed to store upload'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Update database with file information
      await _databaseService.updateUploadWithFile(
          uploadId, filename ?? 'unknown.zip', fileData.length);

      final response = {'uploadId': uploadId};
      return Response.ok(
        jsonEncode(response),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      _logger.severe('Failed to upload file: $e');
      return Response.internalServerError(
        body: jsonEncode({'message': 'Upload failed'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
