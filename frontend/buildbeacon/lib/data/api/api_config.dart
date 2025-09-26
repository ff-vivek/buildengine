/// Centralized API configuration for BuildEngine
///
/// This file declares base URLs, route templates, timeouts, and default headers
/// for every server endpoint used in the app. Fill in the values for your
/// environment (local, staging, production) and optionally switch the active
/// configuration at runtime.

// NOTE: This file does not perform any network calls. It is imported by
// API clients and providers to read configuration values in one place.

class ApiTimeoutsConfig {
  final Duration connectTimeout;
  final Duration receiveTimeout;

  const ApiTimeoutsConfig({
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
  });
}

/// Route templates for all endpoints consumed by the app
/// Keep these in sync with the backend.
class ApiRoutes {
  // Uploads
  static const String uploads = '/v1/uploads';
  static String uploadWithId(String uploadId) => '/v1/uploads/$uploadId';

  // Jobs
  static const String jobs = '/v1/jobs';
  static String jobById(String jobId) => '/v1/jobs/$jobId';
  static String jobLogs(String jobId) => '/v1/jobs/$jobId/logs';
  static String cancelJob(String jobId) => '/v1/jobs/$jobId/cancel';
  static String artifact(String jobId) => '/v1/jobs/$jobId/artifact';

  // (Optional) WebSocket logs, if your backend supports it
  static String jobLogsWs(String jobId) => '/v1/jobs/$jobId/logs/ws';
}

/// Standard query parameter keys expected by the API
class ApiQueryKeys {
  static const String page = 'page';
  static const String limit = 'limit';
  static const String status = 'status';
  static const String sourceType = 'sourceType';
  static const String buildType = 'buildType';
  static const String startDate = 'startDate';
  static const String endDate = 'endDate';
  static const String tail = 'tail';
  static const String nextToken = 'nextToken';
}

/// Headers that are commonly sent on each request
class ApiDefaultHeaders {
  static Map<String, String> json({String? apiKey}) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (apiKey != null && apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
      };

  static Map<String, String> multipart({String? apiKey}) => {
        'Accept': 'application/json',
        // Content-Type will be set by the HTTP client for multipart
        if (apiKey != null && apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
      };
}

/// Represents a fully-specified API environment configuration
class ApiConfig {
  final String name; // e.g., 'local', 'staging', 'production'
  final String baseUrl; // e.g., 'https://api.example.com'
  final String? apiKey; // nullable; most setups use token-based auth per user
  final ApiTimeoutsConfig timeouts;

  const ApiConfig({
    required this.name,
    required this.baseUrl,
    this.apiKey,
    this.timeouts = const ApiTimeoutsConfig(),
  });

  bool get isConfigured => baseUrl.isNotEmpty;

  /// Default JSON headers for typical requests
  Map<String, String> get defaultJsonHeaders => ApiDefaultHeaders.json(apiKey: apiKey);

  /// Default headers for multipart upload requests
  Map<String, String> get defaultMultipartHeaders => ApiDefaultHeaders.multipart(apiKey: apiKey);

  ApiConfig copyWith({
    String? name,
    String? baseUrl,
    String? apiKey,
    ApiTimeoutsConfig? timeouts,
  }) {
    return ApiConfig(
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      timeouts: timeouts ?? this.timeouts,
    );
  }

  @override
  String toString() => 'ApiConfig(name: ' + name + ', baseUrl: ' + baseUrl + ', apiKey: ***hidden***)';
}

/// Ready-to-use presets. Update these to match your infrastructure.
class ApiConfigs {
  // Local development (for running a local server)
  static const ApiConfig local = ApiConfig(
    name: 'local',
    baseUrl: 'http://127.0.0.1:8788',
    apiKey: null, // e.g., 'dev-token'
    timeouts: ApiTimeoutsConfig(
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
    ),
  );

  // Staging (shared testing environment)
  static const ApiConfig staging = ApiConfig(
    name: 'staging',
    baseUrl: 'https://staging.api.buildengine.dev',
    apiKey: null,
  );

  // Production
  static const ApiConfig production = ApiConfig(
    name: 'production',
    baseUrl: 'https://api.buildengine.dev',
    apiKey: null,
  );
}

/// Simple runtime holder with a sensible default. You can switch this at app
/// startup based on your own logic (e.g., environment flags, user selection).
class ApiRuntime {
  static ApiConfig active = ApiConfigs.local;

  static void use(ApiConfig config) {
    active = config;
  }
}
