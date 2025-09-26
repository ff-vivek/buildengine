# BuildEngine Server

A Dart implementation of the BuildEngine Server API that manages Flutter web build jobs. This server provides REST API endpoints for uploading source code, creating build jobs, monitoring progress, and retrieving build artifacts.

## Features

- **Upload Management**: Initialize uploads and handle ZIP file uploads
- **Job Management**: Create, monitor, and cancel Flutter build jobs
- **Real-time Logs**: Stream build logs with pagination support
- **Artifact Retrieval**: Download build artifacts with time-limited URLs
- **Multiple Source Types**: Support for ZIP uploads, FlutterFlow, and Git repositories
- **CORS Support**: Web-friendly with proper CORS headers
- **Error Handling**: Comprehensive error responses with proper HTTP status codes

## API Endpoints

### Upload Endpoints
- `POST /v1/uploads` - Initialize an upload
- `POST /v1/uploads/{uploadId}` - Upload ZIP file

### Job Management
- `POST /v1/jobs` - Create a new build job
- `GET /v1/jobs` - List jobs with filtering and pagination
- `GET /v1/jobs/{jobId}` - Get job details
- `POST /v1/jobs/{jobId}/cancel` - Cancel a job

### Logs and Artifacts
- `GET /v1/jobs/{jobId}/logs` - Get job logs
- `GET /v1/jobs/{jobId}/artifact` - Get artifact download URL

### Health Check
- `GET /health` - Server health status

## Prerequisites

- Dart SDK 3.0.0 or higher
- Flutter SDK (for development)

## Installation

1. **Clone or download the project**
   ```bash
   cd buildengine_server
   ```

2. **Install dependencies**
   ```bash
   dart pub get
   ```

3. **Run the server**
   ```bash
   dart run bin/buildengine_server.dart
   ```

   Or using the executable:
   ```bash
   dart pub run buildengine_server
   ```

The server will start on `http://127.0.0.1:8787` by default.

## Configuration

### Environment Variables
- `PORT`: Server port (default: 8787)
- `HOST`: Server host (default: 127.0.0.1)

### File Storage
The server uses local file storage by default:
- Uploads are stored in `uploads/` directory
- Artifacts are stored in `artifacts/` directory

## Usage Examples

### 1. Initialize Upload
```bash
curl -X POST http://127.0.0.1:8787/v1/uploads \
  -H "Accept: application/json"
```

Response:
```json
{
  "uploadId": "upl_abc123",
  "uploadUrl": "https://storage.example.com/upl_abc123?..."
}
```

### 2. Upload ZIP File
```bash
curl -X POST http://127.0.0.1:8787/v1/uploads/upl_abc123 \
  -F "file=@my_flutter_app.zip"
```

### 3. Create Build Job
```bash
curl -X POST http://127.0.0.1:8787/v1/jobs \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "source": {
      "type": "uploadZip",
      "uploadId": "upl_abc123"
    },
    "config": {
      "flutterVersion": "default",
      "buildType": "release",
      "targetFile": "lib/main.dart"
    }
  }'
```

### 4. Get Job Status
```bash
curl http://127.0.0.1:8787/v1/jobs/job_xyz789 \
  -H "Accept: application/json"
```

### 5. Get Job Logs
```bash
curl http://127.0.0.1:8787/v1/jobs/job_xyz789/logs \
  -H "Accept: application/json"
```

### 6. Get Artifact URL
```bash
curl http://127.0.0.1:8787/v1/jobs/job_xyz789/artifact \
  -H "Accept: application/json"
```

## Source Types

### Upload ZIP
```json
{
  "source": {
    "type": "uploadZip",
    "uploadId": "upl_123"
  }
}
```

### FlutterFlow
```json
{
  "source": {
    "type": "flutterFlow",
    "ffUrl": "https://app.flutterflow.io/project/...",
    "ffToken": "optional_token"
  }
}
```

### Git Repository
```json
{
  "source": {
    "type": "gitRepo",
    "gitUrl": "https://github.com/user/repo.git",
    "branch": "main"
  }
}
```

## Build Configuration

```json
{
  "config": {
    "flutterVersion": "default", // or "3.22.2"
    "buildType": "release",      // "release", "debug", or "profile"
    "targetFile": "lib/main.dart",
    "preSteps": ["echo 'Pre-build step'"],
    "postSteps": ["echo 'Post-build step'"]
  }
}
```

## Error Handling

The server returns appropriate HTTP status codes with JSON error messages:

- `400 Bad Request`: Invalid request data
- `401 Unauthorized`: Authentication required
- `404 Not Found`: Resource not found
- `409 Conflict`: Operation conflict (e.g., cannot cancel completed job)
- `413 Payload Too Large`: File too large
- `422 Unprocessable Entity`: Validation error
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error

Example error response:
```json
{
  "message": "Validation failed: uploadId is required"
}
```

## Development

### Project Structure
```
lib/
├── models/           # Data models and enums
├── services/         # Business logic services
├── handlers/         # HTTP request handlers
└── server.dart      # Main server setup

bin/
└── buildengine_server.dart  # Entry point
```

### Adding New Features

1. **Models**: Add new data models in `lib/models/`
2. **Services**: Implement business logic in `lib/services/`
3. **Handlers**: Create HTTP handlers in `lib/handlers/`
4. **Routes**: Add routes in `lib/server.dart`

### Testing

Run tests with:
```bash
dart test
```

## Production Deployment

### Docker (Optional)
Create a `Dockerfile`:
```dockerfile
FROM dart:stable AS build
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/buildengine_server.dart -o buildengine_server

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=build /app/buildengine_server /app/buildengine_server
WORKDIR /app
EXPOSE 8787
CMD ["./buildengine_server"]
```

### Environment Setup
1. Set up proper file storage (S3, GCS, etc.)
2. Configure authentication if needed
3. Set up monitoring and logging
4. Configure reverse proxy (nginx, etc.)

## API Compliance

This implementation follows the BuildEngine Server API PRD v1 specification:
- All endpoints are versioned under `/v1`
- Proper HTTP status codes and error responses
- CORS headers for web compatibility
- JSON request/response format
- Multipart file upload support
- Pagination support for job listings
- Time-limited artifact URLs

## License

This project is provided as-is for development and testing purposes.

## Support

For issues or questions, please refer to the BuildEngine API documentation or create an issue in the project repository.
