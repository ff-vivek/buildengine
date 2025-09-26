import 'dart:convert';
import 'package:logging/logging.dart';

import '../models/log_entry.dart';

final _logger = Logger('LogService');

class LogService {
  final Map<String, List<LogEntry>> _logs = {};
  static const String _appLogsJobId = '__app_logs__';

  LogService() {
    _setupApplicationLogCapture();
  }

  List<LogEntry> getLogs(String jobId, {int? tail, String? nextToken}) {
    final jobLogs = _logs[jobId] ?? [];

    if (tail != null && tail > 0) {
      // Return only the last N entries
      final startIndex = jobLogs.length > tail ? jobLogs.length - tail : 0;
      return jobLogs.sublist(startIndex);
    }

    // For now, we don't implement pagination with nextToken
    // In a real implementation, you would use nextToken for pagination
    return jobLogs;
  }

  int getLogsCount(String jobId) {
    return _logs[jobId]?.length ?? 0;
  }

  void addLog(String jobId, String level, String message) {
    final logs = _logs[jobId] ?? [];
    final logEntry = LogEntry(
      timestamp: DateTime.now().toUtc(),
      level: level,
      message: message,
    );
    logs.add(logEntry);
    _logs[jobId] = logs;
  }

  void addLogsFromJobService(String jobId, List<String> logStrings) {
    final logs = <LogEntry>[];

    for (final logString in logStrings) {
      try {
        final logData = jsonDecode(logString) as Map<String, dynamic>;
        final logEntry = LogEntry.fromJson(logData);
        logs.add(logEntry);
      } catch (e) {
        _logger.warning('Failed to parse log entry: $logString');
      }
    }

    _logs[jobId] = logs;
  }

  void _setupApplicationLogCapture() {
    // Capture all application logs to a special job ID
    Logger.root.onRecord.listen((record) {
      final level = record.level.name.toUpperCase();
      final message = '[${record.loggerName}] ${record.message}';

      // Add to application logs
      addLog(_appLogsJobId, level, message);

      // Also add to specific job logs if the message contains a job ID
      final jobIdMatch = RegExp(r'job_[a-f0-9]{8}').firstMatch(record.message);
      if (jobIdMatch != null) {
        final jobId = jobIdMatch.group(0)!;
        addLog(jobId, level, message);
      }
    });
  }

  // Get application logs
  List<LogEntry> getApplicationLogs({int? tail}) {
    return getLogs(_appLogsJobId, tail: tail);
  }

  int getApplicationLogsCount() {
    return getLogsCount(_appLogsJobId);
  }
}
