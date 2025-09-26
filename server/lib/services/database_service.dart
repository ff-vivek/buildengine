import 'package:sqlite3/sqlite3.dart';
import 'package:logging/logging.dart';
import '../models/upload_record.dart';

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

  /// Close database connection
  void close() {
    _database.dispose();
    _logger.info('Database connection closed');
  }
}
