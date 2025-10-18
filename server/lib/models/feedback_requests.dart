import 'feedback.dart';

class SubmitFeedbackRequest {
  final String message;
  final String email;

  SubmitFeedbackRequest({
    required this.message,
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'email': email,
    };
  }

  factory SubmitFeedbackRequest.fromJson(Map<String, dynamic> json) {
    return SubmitFeedbackRequest(
      message: json['message'] as String,
      email: json['email'] as String,
    );
  }
}

class SubmitFeedbackResponse {
  final String feedbackId;
  final String message;

  SubmitFeedbackResponse({
    required this.feedbackId,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'feedbackId': feedbackId,
      'message': message,
    };
  }
}

class FeedbackListResponse {
  final List<Feedback> feedbacks;
  final int total;
  final int page;
  final int limit;

  FeedbackListResponse({
    required this.feedbacks,
    required this.total,
    required this.page,
    required this.limit,
  });

  Map<String, dynamic> toJson() {
    return {
      'feedbacks': feedbacks.map((f) => f.toJson()).toList(),
      'total': total,
      'page': page,
      'limit': limit,
    };
  }
}
