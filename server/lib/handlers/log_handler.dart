import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:logging/logging.dart';

import '../models/requests.dart';
import '../services/job_service.dart';

final _logger = Logger('LogHandler');

class LogHandler {
  final JobService _jobService;

  LogHandler(this._jobService);

  Future<Response> getLogs(Request request) async {
    try {
      final jobId = request.params['jobId'];
      if (jobId == null) {
        return Response.badRequest(
          body: jsonEncode({'message': 'jobId is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final uri = request.url;

      // Parse query parameters
      final tail = int.tryParse(uri.queryParameters['tail'] ?? '');
      final nextToken = uri.queryParameters['nextToken'];

      final logs = _jobService.getLogs(jobId, tail: tail, nextToken: nextToken);
      final total = _jobService.getLogsCount(jobId);

      final logsJson = logs.map((log) => log.toJson()).toList();

      final response = LogsResponse(
        logs: logsJson,
        total: total,
        nextToken: null, // For now, we don't implement pagination
      );

      return Response.ok(
        jsonEncode(response.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      _logger.severe('Failed to get logs: $e');
      return Response.internalServerError(
        body: jsonEncode({'message': 'Failed to get logs'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> getApplicationLogs(Request request) async {
    try {
      final uri = request.url;
      final tail = int.tryParse(uri.queryParameters['tail'] ?? '');

      final logs = _jobService.logService.getApplicationLogs(tail: tail);
      final total = _jobService.logService.getApplicationLogsCount();

      final logsJson = logs.map((log) => log.toJson()).toList();

      final response = LogsResponse(
        logs: logsJson,
        total: total,
        nextToken: null,
      );

      return Response.ok(
        jsonEncode(response.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      _logger.severe('Failed to get application logs: $e');
      return Response.internalServerError(
        body: jsonEncode({'message': 'Failed to get application logs'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
