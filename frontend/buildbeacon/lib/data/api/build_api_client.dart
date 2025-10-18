import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:buildbeacon/data/models/build_models_simple.dart';

/// API client for BuildEngine backend
class BuildApiClient {
  final Dio _dio;
  final String baseUrl;

  BuildApiClient({
    required this.baseUrl,
    String? apiKey,
  }) : _dio = Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(minutes: 5); // Increased for large uploads
    _dio.options.sendTimeout = const Duration(minutes: 5); // Added send timeout

    // Add API key if provided
    if (apiKey != null) {
      _dio.options.headers['Authorization'] = 'Bearer $apiKey';
    }

    // Add request/response interceptors
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add common headers
        options.headers['Content-Type'] = 'application/json';
        options.headers['Accept'] = 'application/json';
        handler.next(options);
      },
      onError: (error, handler) {
        // Handle common errors
        if (error.response?.statusCode == 401) {
          // Handle unauthorized
        }
        handler.next(error);
      },
    ));
  }

  /// Initialize a file upload
  Future<UploadResponse> initializeUpload() async {
    try {
      final response = await _dio.post('/v1/uploads');
      return UploadResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload a file from PlatformFile (web-safe). Uses bytes when available; falls back to path on IO platforms.
  Future<String> uploadPlatformFile({
    required String uploadId,
    required PlatformFile file,
    void Function(double)? onProgress,
  }) async {
    try {
      MultipartFile multipart;
      if (file.bytes != null) {
        multipart = MultipartFile.fromBytes(file.bytes!, filename: file.name);
      } else if (file.path != null) {
        multipart = await MultipartFile.fromFile(file.path!, filename: file.name);
      } else {
        throw Exception('Selected file has no bytes or path');
      }

      final formData = FormData.fromMap({'file': multipart});

      await _dio.post(
        '/v1/uploads/$uploadId',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
        onSendProgress: onProgress != null
            ? (sent, total) => onProgress(total == 0 ? 0 : sent / total)
            : null,
      );

      return uploadId;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload bytes (web-safe)
  Future<String> uploadBytes({
    required String uploadId,
    required Uint8List bytes,
    required String filename,
    void Function(double)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });

      await _dio.post(
        '/v1/uploads/$uploadId',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: onProgress != null
            ? (sent, total) => onProgress(total == 0 ? 0 : sent / total)
            : null,
      );

      return uploadId;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a new build job
  Future<CreateBuildResponse> createBuildJob(CreateBuildRequest request) async {
    try {
      final response = await _dio.post(
        '/v1/jobs',
        data: request.toJson(),
      );
      return CreateBuildResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get a specific build job
  Future<BuildJob> getBuildJob(String jobId) async {
    try {
      final response = await _dio.get('/v1/jobs/$jobId');
      return BuildJob.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get build job logs
  Future<LogsResponse> getBuildJobLogs(
    String jobId, {
    int? tail,
    String? nextToken,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (tail != null) queryParams['tail'] = tail;
      if (nextToken != null) queryParams['nextToken'] = nextToken;

      final response = await _dio.get(
        '/v1/jobs/$jobId/logs',
        queryParameters: queryParams,
      );
      return LogsResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get jobs list with filters
  Future<JobsListResponse> getJobs({
    int page = 1,
    int limit = 20,
    BuildStatus? status,
    SourceType? sourceType,
    BuildType? buildType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (status != null) queryParams['status'] = BuildStatusCodec.toApi(status);
      if (sourceType != null) queryParams['sourceType'] = sourceType.name;
      if (buildType != null) queryParams['buildType'] = buildType.name;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await _dio.get(
        '/v1/jobs',
        queryParameters: queryParams,
      );
      return JobsListResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Cancel a build job
  Future<void> cancelBuildJob(String jobId) async {
    try {
      await _dio.post('/v1/jobs/$jobId/cancel');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get artifact download URL
  Future<String> getArtifactUrl(String jobId) async {
    try {
      final response = await _dio.get('/v1/jobs/$jobId/artifact');
      return response.data['url'] as String;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Download the artifact file (bytes) for a job
  Future<DownloadedArtifact> downloadArtifactFile(String jobId) async {
    try {
      final response = await _dio.get(
        '/v1/jobs/$jobId/artifact/download',
        options: Options(
          responseType: ResponseType.bytes, // receive raw bytes
          followRedirects: true,
          // allow 3xx for storage redirects if any
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      final bytes = Uint8List.fromList(response.data as List<int>);
      final headers = response.headers;
      final contentType = headers.value(Headers.contentTypeHeader) ?? 'application/octet-stream';
      final cd = headers.value('content-disposition') ?? headers.value('Content-Disposition');

      String filename = 'artifact';
      if (cd != null) {
        final matchQuoted = RegExp(r'''filename\*=UTF-8''([^;]+)|filename="([^"]+)"|filename=([^;]+)''')
            .firstMatch(cd);
        if (matchQuoted != null) {
          filename = matchQuoted.group(1) ?? matchQuoted.group(2) ?? matchQuoted.group(3) ?? filename;
        }
        filename = filename.trim();
      }

      // If no extension was provided, default to .zip
      if (!filename.contains('.')) {
        filename = '$filename.zip';
      }

      return DownloadedArtifact(
        bytes: bytes,
        filename: filename,
        contentType: contentType,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Submit feedback
  Future<Map<String, dynamic>> submitFeedback({
    required String message,
    required String email,
  }) async {
    try {
      final response = await _dio.post(
        '/v1/feedback',
        data: {
          'message': message,
          'email': email,
        },
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get feedback list (admin endpoint)
  Future<Map<String, dynamic>> getFeedbackList({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _dio.get(
        '/v1/feedback',
        queryParameters: queryParams,
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get specific feedback by ID (admin endpoint)
  Future<Map<String, dynamic>> getFeedback(String feedbackId) async {
    try {
      final response = await _dio.get('/v1/feedback/$feedbackId');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Update feedback status (admin endpoint)
  Future<Map<String, dynamic>> updateFeedback({
    required String feedbackId,
    required String status,
    String? response,
  }) async {
    try {
      final data = <String, dynamic>{
        'status': status,
      };
      
      if (response != null) {
        data['response'] = response;
      }

      final dioResponse = await _dio.put(
        '/v1/feedback/$feedbackId',
        data: data,
      );
      return dioResponse.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle API errors and convert to user-friendly messages
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return Exception('Connection timeout. Please check your internet connection.');
        case DioExceptionType.connectionError:
          return Exception('Unable to connect to server. Please try again later.');
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = error.response?.data?['message'] as String?;
          
          switch (statusCode) {
            case 400:
              return Exception(message ?? 'Invalid request. Please check your input.');
            case 401:
              return Exception('Authentication failed. Please check your credentials.');
            case 403:
              return Exception('Access denied. You don\'t have permission to perform this action.');
            case 404:
              return Exception('Resource not found. The requested item may have been deleted.');
            case 409:
              return Exception(message ?? 'Conflict detected. Please try again.');
            case 422:
              return Exception(message ?? 'Validation failed. Please check your input.');
            case 429:
              return Exception('Too many requests. Please wait a moment before trying again.');
            case 500:
              return Exception('Server error occurred. Please try again later.');
            default:
              return Exception(message ?? 'An unexpected error occurred.');
          }
        default:
          return Exception('Network error occurred. Please try again.');
      }
    }
    return Exception('An unexpected error occurred: $error');
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
  }
}