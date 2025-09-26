import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:logging/logging.dart';

import '../models/requests.dart';
import '../models/enums.dart';
import '../services/job_service.dart';

final _logger = Logger('JobHandler');

class JobHandler {
  final JobService _jobService;

  JobHandler(this._jobService);

  Future<Response> createJob(Request request) async {
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;

      final createRequest = CreateBuildRequest.fromJson(json);
      createRequest.validate();

      final jobId = _jobService.createJob(
        createRequest.source,
        createRequest.config,
      );

      final job = _jobService.getJob(jobId);
      if (job == null) {
        return Response.internalServerError(
          body: jsonEncode({'message': 'Failed to create job'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final response = CreateBuildResponse(
        id: job.id,
        status: job.status.value,
        createdAt: job.createdAt,
      );

      return Response(
        201,
        body: jsonEncode(response.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      _logger.severe('Failed to create job: $e');

      if (e is ArgumentError) {
        return Response.badRequest(
          body: jsonEncode({'message': e.message}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.internalServerError(
        body: jsonEncode({'message': 'Failed to create job'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> getJobs(Request request) async {
    try {
      final uri = request.url;

      // Parse query parameters
      final page = int.tryParse(uri.queryParameters['page'] ?? '1') ?? 1;
      final limit = int.tryParse(uri.queryParameters['limit'] ?? '20') ?? 20;

      BuildStatus? status;
      if (uri.queryParameters['status'] != null) {
        try {
          status =
              BuildStatusExtension.fromString(uri.queryParameters['status']!);
        } catch (e) {
          return Response.badRequest(
            body: jsonEncode({'message': 'Invalid status parameter'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
      }

      SourceType? sourceType;
      if (uri.queryParameters['sourceType'] != null) {
        try {
          sourceType = SourceTypeExtension.fromString(
              uri.queryParameters['sourceType']!);
        } catch (e) {
          return Response.badRequest(
            body: jsonEncode({'message': 'Invalid sourceType parameter'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
      }

      BuildType? buildType;
      if (uri.queryParameters['buildType'] != null) {
        try {
          buildType =
              BuildTypeExtension.fromString(uri.queryParameters['buildType']!);
        } catch (e) {
          return Response.badRequest(
            body: jsonEncode({'message': 'Invalid buildType parameter'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
      }

      DateTime? startDate;
      if (uri.queryParameters['startDate'] != null) {
        try {
          startDate = DateTime.parse(uri.queryParameters['startDate']!);
        } catch (e) {
          return Response.badRequest(
            body: jsonEncode({'message': 'Invalid startDate parameter'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
      }

      DateTime? endDate;
      if (uri.queryParameters['endDate'] != null) {
        try {
          endDate = DateTime.parse(uri.queryParameters['endDate']!);
        } catch (e) {
          return Response.badRequest(
            body: jsonEncode({'message': 'Invalid endDate parameter'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
      }

      final jobs = _jobService.getJobs(
        page: page,
        limit: limit,
        status: status,
        sourceType: sourceType,
        buildType: buildType,
        startDate: startDate,
        endDate: endDate,
      );

      final total = _jobService.getTotalJobsCount(
        status: status,
        sourceType: sourceType,
        buildType: buildType,
        startDate: startDate,
        endDate: endDate,
      );

      final hasMore = (page * limit) < total;

      final jobsJson = jobs.map((job) => job.toJson()).toList();

      final response = JobsListResponse(
        jobs: jobsJson,
        total: total,
        page: page,
        limit: limit,
        hasMore: hasMore,
      );

      return Response.ok(
        jsonEncode(response.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      _logger.severe('Failed to get jobs: $e');
      return Response.internalServerError(
        body: jsonEncode({'message': 'Failed to get jobs'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> getJob(Request request) async {
    try {
      final jobId = request.params['jobId'];
      if (jobId == null) {
        return Response.badRequest(
          body: jsonEncode({'message': 'jobId is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final job = _jobService.getJob(jobId);
      if (job == null) {
        return Response.notFound(
          jsonEncode({'message': 'Job not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(job.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      _logger.severe('Failed to get job: $e');
      return Response.internalServerError(
        body: jsonEncode({'message': 'Failed to get job'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> cancelJob(Request request) async {
    try {
      final jobId = request.params['jobId'];
      if (jobId == null) {
        return Response.badRequest(
          body: jsonEncode({'message': 'jobId is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final success = _jobService.cancelJob(jobId);
      if (!success) {
        return Response(
          409,
          body: jsonEncode({'message': 'Cannot cancel this job'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final job = _jobService.getJob(jobId);
      if (job == null) {
        return Response.notFound(
          jsonEncode({'message': 'Job not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final response = {
        'id': job.id,
        'status': job.status.value,
      };

      return Response(
        202,
        body: jsonEncode(response),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      _logger.severe('Failed to cancel job: $e');
      return Response.internalServerError(
        body: jsonEncode({'message': 'Failed to cancel job'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
