import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buildbeacon/app/providers.dart';
import 'package:buildbeacon/data/models/build_models_simple.dart';
import 'package:buildbeacon/presentation/widgets/error_card.dart';
import 'package:buildbeacon/theme.dart';

class BuildLogsViewer extends ConsumerStatefulWidget {
  final String jobId;

  const BuildLogsViewer({
    super.key,
    required this.jobId,
  });

  @override
  ConsumerState<BuildLogsViewer> createState() => _BuildLogsViewerState();
}

class _BuildLogsViewerState extends ConsumerState<BuildLogsViewer> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  bool _isScrolledToBottom = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final isAtBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100;

    if (isAtBottom != _isScrolledToBottom) {
      setState(() => _isScrolledToBottom = isAtBottom);
    }

    // Load more logs if scrolled to top
    if (_scrollController.position.pixels <= 100) {
      // Simplified: refresh logs when reaching top
      ref.refresh(jobLogsProvider(widget.jobId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final logsState = ref.watch(jobLogsProvider(widget.jobId));

    return Card(
      child: Column(
        children: [
          _buildLogsHeader(context, logsState),
          Expanded(
            child: logsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorCard(
                message: error.toString(),
                onRetry: () => ref.refresh(jobLogsProvider(widget.jobId)),
              ),
              data: (logsResponse) => _buildLogsContent(context, logsResponse),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsHeader(BuildContext context, AsyncValue<LogsResponse> logsState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? DarkModeColors.darkNeutral100 : LightModeColors.lightNeutral100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          bottom: BorderSide(
            color: isDark ? DarkModeColors.darkNeutral200 : LightModeColors.lightNeutral200,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.terminal,
            size: 20,
            color: isDark ? DarkModeColors.darkNeutral700 : LightModeColors.lightNeutral600,
          ),
          const SizedBox(width: 8),
          Text(
            'Build Logs',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? DarkModeColors.darkNeutral900 : LightModeColors.lightNeutral700,
            ),
          ),
          const Spacer(),
          if (logsState.hasValue && logsState.value!.logs.isNotEmpty) ...[
            IconButton(
              icon: Icon(
                _autoScroll ? Icons.pause : Icons.play_arrow,
                size: 20,
              ),
              onPressed: () => setState(() => _autoScroll = !_autoScroll),
              tooltip: _autoScroll ? 'Pause auto-scroll' : 'Resume auto-scroll',
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: () => _copyLogsToClipboard(logsState.value!),
              tooltip: 'Copy logs',
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => ref.refresh(jobLogsProvider(widget.jobId)),
              tooltip: 'Refresh logs',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogsContent(BuildContext context, LogsResponse logsResponse) {
    if (logsResponse.logs.isEmpty) {
      return _buildEmptyLogs(context);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_autoScroll && _isScrolledToBottom && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF0D1117) : LightModeColors.lightNeutral50;

    return Container(
      color: background,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: logsResponse.logs.length + (logsResponse.nextToken != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= logsResponse.logs.length) {
            // Loading indicator for more logs
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final logEntry = logsResponse.logs[index];
          return _buildLogLine(context, logEntry, index);
        },
      ),
    );
  }

  Widget _buildLogLine(BuildContext context, LogEntry logEntry, int lineNumber) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color levelColor;
    IconData? levelIcon;

    switch (logEntry.level.toLowerCase()) {
      case 'error':
        levelColor = isDark ? Colors.red[400]! : LightModeColors.lightError;
        levelIcon = Icons.error;
        break;
      case 'warn':
      case 'warning':
        levelColor = isDark ? Colors.orange[400]! : Colors.orange[700]!;
        levelIcon = Icons.warning;
        break;
      case 'info':
        levelColor = isDark ? Colors.blue[400]! : LightModeColors.lightPrimary;
        levelIcon = Icons.info;
        break;
      case 'debug':
        levelColor = isDark ? Colors.grey[400]! : LightModeColors.lightNeutral500;
        levelIcon = Icons.bug_report;
        break;
      default:
        levelColor = isDark ? Colors.grey[300]! : LightModeColors.lightNeutral400;
    }

    final lineNumberColor = isDark ? Colors.grey[600]! : LightModeColors.lightNeutral500;
    final timestampColor = isDark ? Colors.grey[500]! : LightModeColors.lightNeutral400;
    final messageColor = isDark ? Colors.grey[200]! : LightModeColors.lightNeutral900;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line number
          SizedBox(
            width: 50,
            child: Text(
              '${lineNumber + 1}',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: lineNumberColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          
          // Timestamp
          SizedBox(
            width: 80,
            child: Text(
              _formatLogTime(logEntry.timestamp),
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: timestampColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Level indicator
          if (levelIcon != null) ...[
            Icon(
              levelIcon,
              size: 14,
              color: levelColor,
            ),
            const SizedBox(width: 6),
          ],
          
          // Log message
          Expanded(
            child: SelectableText(
              logEntry.message,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: messageColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLogs(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF0D1117) : LightModeColors.lightNeutral50,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.terminal,
              size: 48,
              color: isDark ? Colors.grey[600] : LightModeColors.lightNeutral500,
            ),
            const SizedBox(height: 16),
            Text(
              'No logs available yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isDark ? Colors.grey[400] : LightModeColors.lightNeutral700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Logs will appear here as the build progresses',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[600] : LightModeColors.lightNeutral500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatLogTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}';
  }

  Future<void> _copyLogsToClipboard(LogsResponse logsResponse) async {
    final logsText = logsResponse.logs
        .map((log) => '[${_formatLogTime(log.timestamp)}] ${log.level.toUpperCase()}: ${log.message}')
        .join('\n');

    await Clipboard.setData(ClipboardData(text: logsText));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied ${logsResponse.logs.length} log entries to clipboard'),
          backgroundColor: LightModeColors.lightTertiary,
        ),
      );
    }
  }
}