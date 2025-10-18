import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import '../models/feedback.dart';
import '../models/feedback_requests.dart';
import '../services/database_service.dart';

final _logger = Logger('FeedbackHandler');

class FeedbackHandler {
  final DatabaseService _databaseService;

  FeedbackHandler(this._databaseService);

  /// Submit new feedback
  Future<Response> submitFeedback(Request request) async {
    try {
      final body = await request.readAsString();
      final jsonData = jsonDecode(body) as Map<String, dynamic>;
      
      final feedbackRequest = SubmitFeedbackRequest.fromJson(jsonData);
      
      // Validate input
      if (feedbackRequest.message.trim().isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'message': 'Message is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      if (feedbackRequest.email.trim().isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'message': 'Email is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      // Basic email validation
      if (!_isValidEmail(feedbackRequest.email)) {
        return Response.badRequest(
          body: jsonEncode({'message': 'Invalid email format'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Create feedback record
      final feedbackId = 'fb_${const Uuid().v4().substring(0, 8)}';
      final feedback = Feedback(
        id: feedbackId,
        message: feedbackRequest.message.trim(),
        email: feedbackRequest.email.trim(),
        createdAt: DateTime.now(),
        status: 'pending',
      );

      // Store in database
      await _databaseService.storeFeedback(feedback);

      final response = SubmitFeedbackResponse(
        feedbackId: feedbackId,
        message: 'Feedback submitted successfully',
      );

      return Response(
        201,
        body: jsonEncode(response.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      _logger.severe('Failed to submit feedback: $e');
      return Response.internalServerError(
        body: jsonEncode({'message': 'Failed to submit feedback'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Get all feedback (admin endpoint)
  Future<Response> getAllFeedback(Request request) async {
    try {
      final uri = request.url;
      final page = int.tryParse(uri.queryParameters['page'] ?? '1') ?? 1;
      final limit = int.tryParse(uri.queryParameters['limit'] ?? '20') ?? 20;
      final status = uri.queryParameters['status'];

      // Validate pagination parameters
      if (page < 1) {
        return Response.badRequest(
          body: jsonEncode({'message': 'Page must be greater than 0'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (limit < 1 || limit > 100) {
        return Response.badRequest(
          body: jsonEncode({'message': 'Limit must be between 1 and 100'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get feedback from database
      final feedbacks = await _databaseService.getAllFeedback(
        page: page,
        limit: limit,
        status: status,
      );

      final total = await _databaseService.getFeedbackCount(status: status);

      final response = FeedbackListResponse(
        feedbacks: feedbacks,
        total: total,
        page: page,
        limit: limit,
      );

      return Response.ok(
        jsonEncode(response.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      _logger.severe('Failed to get feedback: $e');
      return Response.internalServerError(
        body: jsonEncode({'message': 'Failed to get feedback'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Get feedback by ID
  Future<Response> getFeedback(Request request) async {
    try {
      final feedbackId = request.params['feedbackId'];
      if (feedbackId == null) {
        return Response.badRequest(
          body: jsonEncode({'message': 'feedbackId is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final feedback = await _databaseService.getFeedback(feedbackId);
      if (feedback == null) {
        return Response.notFound(
          jsonEncode({'message': 'Feedback not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(feedback.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      _logger.severe('Failed to get feedback: $e');
      return Response.internalServerError(
        body: jsonEncode({'message': 'Failed to get feedback'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Update feedback status (admin endpoint)
  Future<Response> updateFeedback(Request request) async {
    try {
      final feedbackId = request.params['feedbackId'];
      if (feedbackId == null) {
        return Response.badRequest(
          body: jsonEncode({'message': 'feedbackId is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = await request.readAsString();
      final jsonData = jsonDecode(body) as Map<String, dynamic>;
      
      final status = jsonData['status'] as String?;
      final response = jsonData['response'] as String?;

      if (status == null) {
        return Response.badRequest(
          body: jsonEncode({'message': 'Status is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Validate status
      if (!['pending', 'reviewed', 'resolved'].contains(status)) {
        return Response.badRequest(
          body: jsonEncode({'message': 'Invalid status. Must be pending, reviewed, or resolved'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check if feedback exists
      final existingFeedback = await _databaseService.getFeedback(feedbackId);
      if (existingFeedback == null) {
        return Response.notFound(
          jsonEncode({'message': 'Feedback not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Update feedback
      await _databaseService.updateFeedback(feedbackId, status, response: response);

      return Response.ok(
        jsonEncode({'message': 'Feedback updated successfully'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      _logger.severe('Failed to update feedback: $e');
      return Response.internalServerError(
        body: jsonEncode({'message': 'Failed to update feedback'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Basic email validation
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }
}
