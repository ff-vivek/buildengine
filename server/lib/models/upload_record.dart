class UploadRecord {
  final String uploadId;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String status; // 'pending', 'completed', 'expired'
  final String? filename;
  final int? fileSize;

  UploadRecord({
    required this.uploadId,
    required this.createdAt,
    this.expiresAt,
    this.status = 'pending',
    this.filename,
    this.fileSize,
  });

  Map<String, dynamic> toJson() {
    return {
      'uploadId': uploadId,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'status': status,
      'filename': filename,
      'fileSize': fileSize,
    };
  }

  factory UploadRecord.fromJson(Map<String, dynamic> json) {
    return UploadRecord(
      uploadId: json['uploadId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      status: json['status'] as String? ?? 'pending',
      filename: json['filename'] as String?,
      fileSize: json['fileSize'] as int?,
    );
  }

  UploadRecord copyWith({
    String? uploadId,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? status,
    String? filename,
    int? fileSize,
  }) {
    return UploadRecord(
      uploadId: uploadId ?? this.uploadId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      filename: filename ?? this.filename,
      fileSize: fileSize ?? this.fileSize,
    );
  }
}
