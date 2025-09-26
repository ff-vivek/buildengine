import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:logging/logging.dart';

import 'handlers/upload_handler.dart';
import 'handlers/job_handler.dart';
import 'handlers/log_handler.dart';
import 'handlers/artifact_handler.dart';
import 'services/storage_service.dart';
import 'services/job_service.dart';
import 'services/log_service.dart';
import 'services/database_service.dart';
import 'config/environment_config.dart';

final _logger = Logger('BuildEngineServer');

class BuildEngineServer {
  late final StorageService _storageService;
  late final JobService _jobService;
  late final LogService _logService;
  late final DatabaseService _databaseService;
  late final UploadHandler _uploadHandler;
  late final JobHandler _jobHandler;
  late final LogHandler _logHandler;
  late final ArtifactHandler _artifactHandler;

  BuildEngineServer() {
    _storageService = StorageService();
    _logService = LogService();
    _jobService = JobService(_storageService, _logService);
    _databaseService = DatabaseService();

    _uploadHandler = UploadHandler(_storageService, _databaseService);
    _jobHandler = JobHandler(_jobService);
    _logHandler = LogHandler(_jobService);
    _artifactHandler = ArtifactHandler(_storageService);
  }

  Router get _router {
    final router = Router();

    // Health check
    router.get('/health', (Request request) {
      return Response.ok(jsonEncode({'status': 'healthy'}));
    });

    // API v1 routes
    router.mount('/v1/', _v1Router);

    return router;
  }

  Router get _v1Router {
    final router = Router();

    // Upload endpoints
    router.post('/uploads', _uploadHandler.initializeUpload);
    router.post('/uploads/<uploadId>', _uploadHandler.uploadFile);

    // Job endpoints
    router.post('/jobs', _jobHandler.createJob);
    router.get('/jobs', _jobHandler.getJobs);
    router.get('/jobs/<jobId>', _jobHandler.getJob);
    router.post('/jobs/<jobId>/cancel', _jobHandler.cancelJob);

    // Log endpoints
    router.get('/jobs/<jobId>/logs', _logHandler.getLogs);
    router.get('/logs/application', _logHandler.getApplicationLogs);

    // Artifact endpoints
    router.get('/jobs/<jobId>/artifact', _artifactHandler.getArtifactUrl);
    router.get(
        '/jobs/<jobId>/artifact/download', _artifactHandler.downloadArtifact);

    return router;
  }

  Handler get _pipeline {
    return Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(corsHeaders(
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers':
                'Content-Type, Authorization, Accept',
            'Access-Control-Max-Age': '86400',
          },
        ))
        .addMiddleware(_errorHandler)
        .addHandler(_router);
  }

  Middleware get _errorHandler {
    return (Handler handler) {
      return (Request request) async {
        try {
          return await handler(request);
        } catch (e, stackTrace) {
          _logger.severe('Unhandled error: $e', e, stackTrace);

          if (e is ArgumentError) {
            return Response.badRequest(
              body: jsonEncode({'message': e.message}),
              headers: {'Content-Type': 'application/json'},
            );
          }

          return Response.internalServerError(
            body: jsonEncode({'message': 'Internal server error'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
      };
    };
  }

  void _startPeriodicCleanup() {
    // Run cleanup every hour
    Timer.periodic(const Duration(hours: 1), (timer) async {
      try {
        // Clean up expired uploads from both database and storage
        await _databaseService.cleanupExpiredUploads();
        await _storageService.cleanupExpiredUploads(
            maxAge: const Duration(hours: 24));
      } catch (e) {
        _logger.warning('Failed to cleanup expired uploads: $e');
      }
    });
  }

  Future<void> _killExistingProcessOnPort(int port) async {
    try {
      _logger.info('Checking for existing processes on port $port...');

      // Use lsof to find processes using the port
      final result = await Process.run('lsof', ['-ti:$port']);

      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        final pids = result.stdout.toString().trim().split('\n');
        _logger.info(
            'Found ${pids.length} process(es) using port $port: ${pids.join(', ')}');

        for (final pid in pids) {
          if (pid.trim().isNotEmpty) {
            try {
              await Process.run('kill', ['-9', pid.trim()]);
              _logger.info('Killed process $pid on port $port');
            } catch (e) {
              _logger.warning('Failed to kill process $pid: $e');
            }
          }
        }

        // Wait a moment for processes to be killed
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        _logger.info('No existing processes found on port $port');
      }
    } catch (e) {
      _logger
          .warning('Failed to check for existing processes on port $port: $e');
      // Continue anyway - the server start will fail if port is still in use
    }
  }

  Future<void> start({
    String host = '127.0.0.1',
    int port = 8788,
  }) async {
    // Kill any existing processes on the port
    await _killExistingProcessOnPort(port);

    // Log environment configuration
    _logger.info('Environment Configuration:');
    _logger.info('  Storage Type: ${EnvironmentConfig.storageType.name}');
    _logger.info(
        '  Environment: ${EnvironmentConfig.isProduction ? 'production' : 'development'}');
    _logger.info('  Base URL: ${EnvironmentConfig.baseUrl}');

    if (EnvironmentConfig.storageType == StorageType.googleCloud) {
      _logger.info('  GCP Project ID: ${EnvironmentConfig.gcpProjectId}');
      _logger.info('  GCP Bucket: ${EnvironmentConfig.gcpBucketName}');
    } else {
      _logger
          .info('  Local Storage Path: ${EnvironmentConfig.localStoragePath}');
    }

    print('Starting BuildEngine Server on http://$host:$port');
    print('Storage Type: ${EnvironmentConfig.storageType.name}');
    final server = await serve(_pipeline, host, port);
    print('BuildEngine Server running on http://$host:$port');
    _logger.info('BuildEngine Server running on http://$host:$port');
    _logger.info('Health check available at http://$host:$port/health');
    print('Health check available at http://$host:$port/health');

    // Start periodic cleanup of expired uploads
    _startPeriodicCleanup();

    // Graceful shutdown
    ProcessSignal.sigint.watch().listen((_) async {
      _logger.info('Shutting down server...');
      await server.close();
      _databaseService.close();
      exit(0);
    });
  }
}

void main(List<String> args) async {
  // Setup logging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  final server = BuildEngineServer();
  await server.start();
}
