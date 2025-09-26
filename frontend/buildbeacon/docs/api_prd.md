# BuildEngine Server API PRD (v1)

Status: Draft
Last updated: 2025-09-24

Overview
- This document defines the REST API contract required by the BuildEngine frontend to manage Flutter web build jobs.
- It is backend-agnostic and can be implemented on any stack as long as it adheres to the contracts below.
- All routes are versioned under `/v1`.

Environments
- Local: http://127.0.0.1:8787
- Staging: https://staging.api.buildengine.dev
- Production: https://api.buildengine.dev

Authentication
- Scheme: Bearer token (optional). If your deployment requires auth, send `Authorization: Bearer <token>` on all endpoints.

Headers
- Required: `Accept: application/json`
- JSON requests: `Content-Type: application/json`
- Multipart upload: Let the client set `Content-Type` automatically; server must accept `multipart/form-data`.

Timeouts (client expectations)
- Connect timeout: 30s
- Receive timeout: 30s

Common Error Model
- On errors, return appropriate HTTP status code with JSON body:
  - Shape: `{ "message": string }`
  - Example: `{ "message": "Validation failed: uploadId is required" }`

Enumerations
- SourceType: `uploadZip` | `flutterFlow` | `gitRepo`
- BuildType: `release` | `debug` | `profile`
- BuildStatus: `created` | `queued` | `downloading_source` | `pre_steps` | `building` | `post_steps` | `packaging` | `success` | `failed` | `canceled`
  - Note: While the frontend shows some statuses in camelCase, the API should return the snake_case variants for: `downloading_source`, `pre_steps`, `post_steps`.

Pagination
- Query params: `page` (int, 1-based), `limit` (int)
- Response fields: `total` (int), `page` (int), `limit` (int), `hasMore` (bool)

Rate Limiting
- If implemented, return 429 with `{ "message": "Too many requests" }`. Optional headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `Retry-After`.

CORS (for Web)
- Allow requests from web origins hosting the frontend.
- Permit headers: `Authorization`, `Content-Type`.

Versioning
- All endpoints are namespaced under `/v1`. Breaking changes should bump the version.

----------------------------------------------------------------
Endpoints
----------------------------------------------------------------

1) Initialize Upload
- Method: POST
- URL: `/v1/uploads`
- Purpose: Allocate an upload ID (and optionally a pre-signed direct upload URL) for uploading a source ZIP.
- Request Body: none
- Success Response: 201 Created
```
{
  "uploadId": "upl_123",
  "uploadUrl": "https://storage.example.com/upl_123?..." // optional
}
```
- Error Responses:
  - 400 Bad Request: `{ "message": "Invalid request" }`
  - 401 Unauthorized: `{ "message": "Authentication failed" }`
  - 429 Too Many Requests
  - 500 Internal Server Error

2) Upload File (multipart)
- Method: POST
- URL: `/v1/uploads/{uploadId}`
- Purpose: Upload the ZIP file bits for a previously initialized upload.
- Request Content-Type: `multipart/form-data`
- Form Fields:
  - `file` (required): binary ZIP content; filename should be preserved.
- Success Response: 200 OK (or 204 No Content)
```
{ "uploadId": "upl_123" }
// 204 may return empty body
```
- Error Responses:
  - 400 Bad Request (e.g., unsupported file type, too large)
  - 401 Unauthorized
  - 404 Not Found (invalid or expired uploadId)
  - 413 Payload Too Large (optional)
  - 429, 500

3) Create Build Job
- Method: POST
- URL: `/v1/jobs`
- Purpose: Create a new build job referencing a source and build configuration.
- Request Body (application/json):
```
{
  "source": {
    "type": "uploadZip" | "flutterFlow" | "gitRepo",
    "uploadId": "upl_123",        // required if type = uploadZip
    "ffUrl": "https://...",       // required if type = flutterFlow
    "ffToken": "...",             // optional/required depending on backend auth
    "gitUrl": "https://...",      // required if type = gitRepo (or SSH URL)
    "branch": "main"               // optional, default "main"
  },
  "config": {
    "flutterVersion": "default",   // or a specific version like "3.22.2"
    "buildType": "release" | "debug" | "profile",
    "targetFile": "lib/main.dart", // optional
    "preSteps": ["echo pre"],      // optional, array of shell snippets/commands
    "postSteps": ["echo post"]     // optional
  }
}
```
- Success Response: 201 Created
```
{
  "id": "job_abc",
  "status": "created",
  "createdAt": "2025-01-01T12:00:00Z"
}
```
- Error Responses: 400, 401, 409 (conflict), 422 (validation), 429, 500

4) Get Jobs (list with filters)
- Method: GET
- URL: `/v1/jobs`
- Query Parameters:
  - `page` (int, default 1)
  - `limit` (int, default 20)
  - `status` (BuildStatus as string; snake_case allowed)
  - `sourceType` (SourceType)
  - `buildType` (BuildType)
  - `startDate` (ISO8601)
  - `endDate` (ISO8601)
- Success Response: 200 OK
```
{
  "jobs": [
    {
      "id": "job_abc",
      "source": {
        "type": "uploadZip",
        "uploadId": "upl_123",
        "branch": "main"
      },
      "config": {
        "flutterVersion": "default",
        "buildType": "release",
        "targetFile": "lib/main.dart",
        "preSteps": [],
        "postSteps": []
      },
      "status": "queued",
      "createdAt": "2025-01-01T12:00:00Z",
      "startedAt": null,
      "finishedAt": null,
      "artifactUrl": null,
      "errorMessage": null
    }
  ],
  "total": 1,
  "page": 1,
  "limit": 20,
  "hasMore": false
}
```
- Error Responses: 400, 401, 429, 500

5) Get Job (by id)
- Method: GET
- URL: `/v1/jobs/{jobId}`
- Purpose: Fetch the latest state for a specific job.
- Success Response: 200 OK
```
{
  "id": "job_abc",
  "source": {
    "type": "uploadZip",
    "uploadId": "upl_123",
    "branch": "main"
  },
  "config": {
    "flutterVersion": "default",
    "buildType": "release",
    "targetFile": "lib/main.dart",
    "preSteps": [],
    "postSteps": []
  },
  "status": "building",
  "createdAt": "2025-01-01T12:00:00Z",
  "startedAt": "2025-01-01T12:05:00Z",
  "finishedAt": null,
  "artifactUrl": null,
  "errorMessage": null
}
```
- Error Responses: 401, 404, 500

6) Get Job Logs
- Method: GET
- URL: `/v1/jobs/{jobId}/logs`
- Query Parameters:
  - `tail` (int, optional): only return the last N entries
  - `nextToken` (string, optional): pagination token for fetching next page
- Success Response: 200 OK
```
{
  "logs": [
    {
      "timestamp": "2025-01-01T12:05:01.000Z",
      "level": "INFO",
      "message": "Starting build"
    },
    {
      "timestamp": "2025-01-01T12:05:02.000Z",
      "level": "INFO",
      "message": "Running flutter build web"
    }
  ],
  "total": 2,
  "nextToken": null
}
```
- Error Responses: 401, 404, 429, 500

7) Cancel Job
- Method: POST
- URL: `/v1/jobs/{jobId}/cancel`
- Purpose: Request cancellation of a running or queued job.
- Success Response: 202 Accepted (preferred) or 204 No Content
```
{
  "id": "job_abc",
  "status": "canceled"
}
// If 204 No Content, body may be empty; client accepts both
```
- Error Responses: 401, 404, 409 (cannot cancel), 500

8) Get Artifact URL
- Method: GET
- URL: `/v1/jobs/{jobId}/artifact`
- Purpose: Obtain a time-limited URL to download the build artifact (e.g., zipped web build).
- Success Response: 200 OK
```
{
  "url": "https://storage.example.com/job_abc/artifact.zip?sig=...&expires=..."
}
```
- Error Responses: 401, 404 (no artifact yet or job failed), 410 (expired, optional), 500

9) (Optional) WebSocket Logs
- URL: `/v1/jobs/{jobId}/logs/ws`
- Purpose: Stream live logs over WebSocket. Not used by the current app code, but reserved for future use.
- Suggested Protocol:
  - On connect, server starts sending JSON messages of shape: `{ "timestamp": ISO8601, "level": string, "message": string }`
  - Support close with a final message `{ "type": "complete" }`

----------------------------------------------------------------
Data Models (as used by the frontend)
----------------------------------------------------------------

UploadResponse
```
{
  "uploadId": string,
  "uploadUrl": string // optional
}
```

CreateBuildRequest
```
{
  "source": BuildSource,
  "config": BuildConfig
}
```

BuildSource
```
{
  "type": "uploadZip" | "flutterFlow" | "gitRepo",
  "uploadId": string, // when type = uploadZip
  "ffUrl": string,     // when type = flutterFlow
  "ffToken": string,   // optional/required based on backend
  "gitUrl": string,    // when type = gitRepo
  "branch": string     // default "main"
}
```

BuildConfig
```
{
  "flutterVersion": string, // "default" or specific
  "buildType": "release" | "debug" | "profile",
  "targetFile": string,     // default "lib/main.dart"
  "preSteps": string[],
  "postSteps": string[]
}
```

CreateBuildResponse
```
{
  "id": string,
  "status": BuildStatus,
  "createdAt": ISO8601 string
}
```

BuildJob
```
{
  "id": string,
  "source": BuildSource,
  "config": BuildConfig,
  "status": BuildStatus,      // snake_case for select values, see Enumerations
  "createdAt": ISO8601 string,
  "startedAt": ISO8601 string | null,
  "finishedAt": ISO8601 string | null,
  "artifactUrl": string | null,
  "errorMessage": string | null
}
```

JobsListResponse
```
{
  "jobs": BuildJob[],
  "total": number,
  "page": number,
  "limit": number,
  "hasMore": boolean
}
```

LogEntry
```
{
  "timestamp": ISO8601 string,
  "level": string,  // e.g., INFO, WARN, ERROR
  "message": string
}
```

LogsResponse
```
{
  "logs": LogEntry[],
  "total": number,
  "nextToken": string | null
}
```

----------------------------------------------------------------
Validation Notes
----------------------------------------------------------------
- Upload size limits should be enforced server-side; return 413 if exceeded.
- For Git sources, validate repo URL format and access permissions; provide clear 401/403 messaging.
- For FlutterFlow imports, ffUrl and ffToken handling depends on your backend integration; document any additional requirements if applicable.
- Return consistent ISO8601 timestamps in UTC.
- `page` is 1-based. If `limit` is omitted, default to 20.

----------------------------------------------------------------
Security Notes
----------------------------------------------------------------
- If authentication is required, every endpoint should validate the bearer token and return 401 on failure, 403 on insufficient permissions.
- Signed artifact URLs should be time-limited and single-purpose.
- Sanitize logs to avoid leaking secrets.

----------------------------------------------------------------
Change Log
----------------------------------------------------------------
- v1.0 (Draft): Initial specification covering uploads, jobs, logs, cancellation, and artifact retrieval.
