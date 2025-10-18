import 'package:sqlite3/sqlite3.dart';
import 'package:logging/logging.dart';
import '../models/upload_record.dart';
import '../models/feedback.dart';

final _logger = Logger('DatabaseService');

class DatabaseService {
  late final Database _database;
  static const String _dbPath = 'buildengine.db';

  DatabaseService() {
    _initializeDatabase();
  }

  void _initializeDatabase() {
    _database = sqlite3.open(_dbPath);
    _createTables();
    _logger.info('Database initialized at $_dbPath');
  }

  void _createTables() {
    // Create uploads table
    _database.execute('''
      CREATE TABLE IF NOT EXISTS uploads (
        upload_id TEXT PRIMARY KEY,
        created_at TEXT NOT NULL,
        expires_at TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        filename TEXT,
        file_size INTEGER
      )
    ''');

    // Create index for faster lookups
    _database.execute('''
      CREATE INDEX IF NOT EXISTS idx_uploads_status 
      ON uploads(status)
    ''');

    _database.execute('''
      CREATE INDEX IF NOT EXISTS idx_uploads_created_at 
      ON uploads(created_at)
    ''');

    // Create feedback table
    _database.execute('''
      CREATE TABLE IF NOT EXISTS feedback (
        id TEXT PRIMARY KEY,
        message TEXT NOT NULL,
        email TEXT NOT NULL,
        created_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        response TEXT
      )
    ''');

    // Create index for feedback lookups
    _database.execute('''
      CREATE INDEX IF NOT EXISTS idx_feedback_status 
      ON feedback(status)
    ''');

    _database.execute('''
      CREATE INDEX IF NOT EXISTS idx_feedback_created_at 
      ON feedback(created_at)
    ''');

    _logger.info('Database tables created/verified');
  }

  /// Store a new upload record
  Future<void> storeUpload(UploadRecord record) async {
    try {
      _database.execute('''
        INSERT INTO uploads (upload_id, created_at, expires_at, status, filename, file_size)
        VALUES (?, ?, ?, ?, ?, ?)
      ''', [
        record.uploadId,
        record.createdAt.toIso8601String(),
        record.expiresAt?.toIso8601String(),
        record.status,
        record.filename,
        record.fileSize,
      ]);

      _logger.info('Stored upload record: ${record.uploadId}');
    } catch (e) {
      _logger.severe('Failed to store upload record: $e');
      rethrow;
    }
  }

  /// Check if an upload exists and is valid
  Future<bool> uploadExists(String uploadId) async {
    try {
      final result = _database.select('''
        SELECT status, expires_at FROM uploads 
        WHERE upload_id = ?
      ''', [uploadId]);

      if (result.isEmpty) {
        return false;
      }

      final row = result.first;
      final status = row['status'] as String;
      final expiresAtStr = row['expires_at'] as String?;

      // Check if expired
      if (expiresAtStr != null) {
        final expiresAt = DateTime.parse(expiresAtStr);
        if (DateTime.now().isAfter(expiresAt)) {
          // Mark as expired
          await _updateUploadStatus(uploadId, 'expired');
          return false;
        }
      }

      // Check if status is valid
      return status == 'pending' || status == 'completed';
    } catch (e) {
      _logger.severe('Failed to check upload existence: $e');
      return false;
    }
  }

  /// Get upload record by ID
  Future<UploadRecord?> getUpload(String uploadId) async {
    try {
      final result = _database.select('''
        SELECT * FROM uploads WHERE upload_id = ?
      ''', [uploadId]);

      if (result.isEmpty) {
        return null;
      }

      final row = result.first;
      return UploadRecord(
        uploadId: row['upload_id'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
        expiresAt: row['expires_at'] != null
            ? DateTime.parse(row['expires_at'] as String)
            : null,
        status: row['status'] as String,
        filename: row['filename'] as String?,
        fileSize: row['file_size'] as int?,
      );
    } catch (e) {
      _logger.severe('Failed to get upload record: $e');
      return null;
    }
  }

  /// Update upload status
  Future<void> _updateUploadStatus(String uploadId, String status) async {
    try {
      _database.execute('''
        UPDATE uploads SET status = ? WHERE upload_id = ?
      ''', [status, uploadId]);

      _logger.info('Updated upload status: $uploadId -> $status');
    } catch (e) {
      _logger.severe('Failed to update upload status: $e');
      rethrow;
    }
  }

  /// Update upload with file information
  Future<void> updateUploadWithFile(
      String uploadId, String filename, int fileSize) async {
    try {
      _database.execute('''
        UPDATE uploads 
        SET status = 'completed', filename = ?, file_size = ?
        WHERE upload_id = ?
      ''', [filename, fileSize, uploadId]);

      _logger.info('Updated upload with file info: $uploadId');
    } catch (e) {
      _logger.severe('Failed to update upload with file info: $e');
      rethrow;
    }
  }

  /// Clean up expired uploads
  Future<void> cleanupExpiredUploads() async {
    try {
      final now = DateTime.now().toIso8601String();

      // First count how many will be affected
      final countResult = _database.select('''
        SELECT COUNT(*) as count FROM uploads 
        WHERE expires_at IS NOT NULL 
        AND expires_at < ? 
        AND status = 'pending'
      ''', [now]);

      final count = countResult.first['count'] as int;

      if (count > 0) {
        // Then update them
        _database.execute('''
          UPDATE uploads 
          SET status = 'expired' 
          WHERE expires_at IS NOT NULL 
          AND expires_at < ? 
          AND status = 'pending'
        ''', [now]);

        _logger.info('Marked $count uploads as expired');
      }
    } catch (e) {
      _logger.severe('Failed to cleanup expired uploads: $e');
    }
  }

  /// Get all uploads (for debugging/admin purposes)
  Future<List<UploadRecord>> getAllUploads() async {
    try {
      final result = _database.select('''
        SELECT * FROM uploads ORDER BY created_at DESC
      ''');

      return result
          .map((row) => UploadRecord(
                uploadId: row['upload_id'] as String,
                createdAt: DateTime.parse(row['created_at'] as String),
                expiresAt: row['expires_at'] != null
                    ? DateTime.parse(row['expires_at'] as String)
                    : null,
                status: row['status'] as String,
                filename: row['filename'] as String?,
                fileSize: row['file_size'] as int?,
              ))
          .toList();
    } catch (e) {
      _logger.severe('Failed to get all uploads: $e');
      return [];
    }
  }

  /// Store a new feedback record
  Future<void> storeFeedback(Feedback feedback) async {
    try {
      _database.execute('''
        INSERT INTO feedback (id, message, email, created_at, status, response)
        VALUES (?, ?, ?, ?, ?, ?)
      ''', [
        feedback.id,
        feedback.message,
        feedback.email,
        feedback.createdAt.toIso8601String(),
        feedback.status ?? 'pending',
        feedback.response,
      ]);

      _logger.info('Stored feedback record: ${feedback.id}');
    } catch (e) {
      _logger.severe('Failed to store feedback record: $e');
      rethrow;
    }
  }

  /// Get feedback by ID
  Future<Feedback?> getFeedback(String feedbackId) async {
    try {
      final result = _database.select('''
        SELECT * FROM feedback WHERE id = ?
      ''', [feedbackId]);

      if (result.isEmpty) {
        return null;
      }

      final row = result.first;
      return Feedback(
        id: row['id'] as String,
        message: row['message'] as String,
        email: row['email'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
        status: row['status'] as String?,
        response: row['response'] as String?,
      );
    } catch (e) {
      _logger.severe('Failed to get feedback record: $e');
      return null;
    }
  }

  /// Get all feedback with pagination
  Future<List<Feedback>> getAllFeedback({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final offset = (page - 1) * limit;
      String query = '''
        SELECT * FROM feedback
      ''';
      
      List<dynamic> params = [];
      
      if (status != null) {
        query += ' WHERE status = ?';
        params.add(status);
      }
      
      query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
      params.addAll([limit, offset]);

      final result = _database.select(query, params);

      return result
          .map((row) => Feedback(
                id: row['id'] as String,
                message: row['message'] as String,
                email: row['email'] as String,
                createdAt: DateTime.parse(row['created_at'] as String),
                status: row['status'] as String?,
                response: row['response'] as String?,
              ))
          .toList();
    } catch (e) {
      _logger.severe('Failed to get feedback records: $e');
      return [];
    }
  }

  /// Get feedback count
  Future<int> getFeedbackCount({String? status}) async {
    try {
      String query = 'SELECT COUNT(*) as count FROM feedback';
      List<dynamic> params = [];
      
      if (status != null) {
        query += ' WHERE status = ?';
        params.add(status);
      }

      final result = _database.select(query, params);
      return result.first['count'] as int;
    } catch (e) {
      _logger.severe('Failed to get feedback count: $e');
      return 0;
    }
  }

  /// Update feedback status and response
  Future<void> updateFeedback(String feedbackId, String status, {String? response}) async {
    try {
      _database.execute('''
        UPDATE feedback 
        SET status = ?, response = ?
        WHERE id = ?
      ''', [status, response, feedbackId]);

      _logger.info('Updated feedback: $feedbackId -> $status');
    } catch (e) {
      _logger.severe('Failed to update feedback: $e');
      rethrow;
    }
  }

  /// Close database connection
  void close() {
    _database.dispose();
    _logger.info('Database connection closed');
  }
}