class Feedback {
  final String id;
  final String message;
  final String email;
  final DateTime createdAt;
  final String? status; // 'pending', 'reviewed', 'resolved'
  final String? response; // Optional response from admin

  Feedback({
    required this.id,
    required this.message,
    required this.email,
    required this.createdAt,
    this.status = 'pending',
    this.response,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'response': response,
    };
  }

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['id'] as String,
      message: json['message'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String?,
      response: json['response'] as String?,
    );
  }

  Feedback copyWith({
    String? id,
    String? message,
    String? email,
    DateTime? createdAt,
    String? status,
    String? response,
  }) {
    return Feedback(
      id: id ?? this.id,
      message: message ?? this.message,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      response: response ?? this.response,
    );
  }
}
