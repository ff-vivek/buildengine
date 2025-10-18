# BuildEngine Server

A production-ready Dart implementation of the BuildEngine Server API that manages real Flutter app builds. This server provides comprehensive REST API endpoints for uploading source code, creating and monitoring build jobs, streaming real-time logs, and retrieving build artifacts.

## 🚀 Features

- **🔄 Real Flutter Builds**: Execute actual Flutter builds (web, APK) with complete build pipeline
- **📦 Upload Management**: Initialize uploads and handle ZIP file uploads with validation
- **⚡ Job Management**: Create, monitor, cancel, and queue Flutter build jobs
- **📊 Real-time Logs**: Stream build logs with pagination and real-time updates
- **📁 Artifact Retrieval**: Download build artifacts with secure time-limited URLs
- **🔌 Multiple Source Types**: Support for ZIP uploads, FlutterFlow projects, and Git repositories
- **🌐 CORS Support**: Web-friendly with proper CORS headers for frontend integration
- **🛡️ Error Handling**: Comprehensive error responses with proper HTTP status codes
- **💾 Storage Options**: Local storage and Google Cloud Storage support
- **🗄️ Database Integration**: SQLite database for job tracking and metadata

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

## 📋 Prerequisites

- **Dart SDK**: 3.0.0 or higher
- **Flutter SDK**: 3.22.0 or higher (required for building Flutter projects)
- **Git**: For cloning repositories and version control
- **Operating System**: Linux, macOS, or Windows

## 🛠️ Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd buildengine_server/server
   ```

2. **Install dependencies**
   ```bash
   dart pub get
   ```

3. **Set up environment (optional)**
   ```bash
   cp env.example .env
   # Edit .env file with your configuration
   ```

4. **Run the server**
   ```bash
   # Development mode
   dart run bin/buildengine_server.dart
   
   # Or using executable
   dart pub run buildengine_server
   
   # Production mode (compile first)
   dart compile exe bin/buildengine_server.dart -o buildengine_server
   ./buildengine_server
   ```

The server will start on `http://127.0.0.1:8788` by default and create necessary directories automatically.

## ⚙️ Configuration

### Environment Variables
Create a `.env` file in the server directory:

```env
# Server Configuration
PORT=8788
HOST=127.0.0.1
BASE_URL=http://127.0.0.1:8788

# Storage Configuration
STORAGE_TYPE=local  # or "gcp" for Google Cloud Storage
LOCAL_STORAGE_PATH=./storage

# Google Cloud Storage (if using GCP)
GCP_PROJECT_ID=your-project-id
GCP_BUCKET_NAME=your-bucket-name
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json

# Environment
ENVIRONMENT=development  # or "production"
```

### Storage Options

#### Local Storage (Default)
- **Uploads**: `storage/uploads/` directory
- **Artifacts**: `storage/artifacts/` directory
- **Workspace**: `workspace/` directory for build operations

#### Google Cloud Storage
- Configure GCP credentials and bucket
- Automatic signed URL generation for downloads
- Scalable for production deployments

## 📖 Usage Examples

### 1. Initialize Upload
```bash
curl -X POST http://127.0.0.1:8788/v1/uploads \
  -H "Accept: application/json"
```

**Response:**
```json
{
  "uploadId": "upl_abc123",
  "uploadUrl": "http://127.0.0.1:8788/v1/uploads/upl_abc123"
}
```

### 2. Upload ZIP File
```bash
curl -X POST http://127.0.0.1:8788/v1/uploads/upl_abc123 \
  -F "file=@my_flutter_app.zip"
```

### 3. Create Build Job
```bash
curl -X POST http://127.0.0.1:8788/v1/jobs \
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
      "targetFile": "lib/main.dart",
      "platforms": ["web"]
    }
  }'
```

**Response:**
```json
{
  "jobId": "job_xyz789",
  "status": "created",
  "createdAt": "2024-01-15T10:30:00Z"
}
```

### 4. Monitor Job Progress
```bash
# Get job status
curl http://127.0.0.1:8788/v1/jobs/job_xyz789 \
  -H "Accept: application/json"

# Get real-time logs
curl http://127.0.0.1:8788/v1/jobs/job_xyz789/logs \
  -H "Accept: application/json"
```

### 5. Download Build Artifact
```bash
# Get artifact download URL
curl http://127.0.0.1:8788/v1/jobs/job_xyz789/artifact \
  -H "Accept: application/json"

# Download the artifact
wget "$(curl -s http://127.0.0.1:8788/v1/jobs/job_xyz789/artifact | jq -r '.artifactUrl')"
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

## 🔧 Build Configuration

### Build Types & Platforms
```json
{
  "config": {
    "flutterVersion": "default",        // or specific version like "3.22.2"
    "buildType": "release",             // "release", "debug", or "profile"
    "targetFile": "lib/main.dart",      // Entry point file
    "platforms": ["web", "apk"],       // Target platforms
    "preSteps": [                       // Commands before build
      "flutter clean",
      "flutter pub get"
    ],
    "postSteps": [                      // Commands after build
      "echo 'Build completed successfully'"
    ]
  }
}
```

### Supported Platforms
- **`web`**: Flutter web build (default)
- **`apk`**: Android APK build
- **`ios`**: iOS build (macOS only)
- **`macos`**: macOS app build (macOS only)
- **`windows`**: Windows executable (Windows only)
- **`linux`**: Linux executable (Linux only)

### Custom Steps
Pre and post-build steps support:
- Flutter/Dart commands: `flutter clean`, `dart analyze`
- Shell commands: `echo`, `cp`, `mkdir`
- Package management: `flutter pub get`, `flutter pub upgrade`

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

## 🔨 Development

### Project Structure
```
server/
├── lib/
│   ├── config/
│   │   └── environment_config.dart    # Environment configuration
│   ├── handlers/
│   │   ├── artifact_handler.dart      # Artifact download endpoints
│   │   ├── job_handler.dart           # Job management endpoints
│   │   ├── log_handler.dart           # Log streaming endpoints
│   │   └── upload_handler.dart        # File upload endpoints
│   ├── models/
│   │   ├── build_config.dart          # Build configuration models
│   │   ├── build_job.dart             # Job status and metadata
│   │   ├── build_source.dart          # Source type definitions
│   │   ├── enums.dart                 # Shared enumerations
│   │   ├── log_entry.dart             # Log entry structure
│   │   ├── requests.dart              # API request models
│   │   └── upload_record.dart         # Upload tracking
│   ├── services/
│   │   ├── artifact_packaging_service.dart  # Build artifact packaging
│   │   ├── database_service.dart            # SQLite database operations
│   │   ├── flutter_build_service.dart       # Real Flutter build execution
│   │   ├── google_cloud_storage_service.dart # GCS integration
│   │   ├── job_service.dart                 # Job orchestration
│   │   ├── local_storage_service.dart       # Local file operations
│   │   ├── log_service.dart                 # Build log management
│   │   ├── source_downloader.dart           # Source code retrieval
│   │   ├── storage_interface.dart           # Storage abstraction
│   │   └── storage_service.dart             # Storage service factory
│   └── server.dart                    # Main server and routing
├── bin/
│   └── buildengine_server.dart        # Application entry point
├── test/
│   └── server_test.dart               # Unit tests
├── storage/                           # Local storage directory
├── workspace/                         # Build workspace
├── pubspec.yaml                       # Dependencies
└── README.md                          # This file
```

### Adding New Features

1. **Models**: Add data models in `lib/models/` with proper JSON serialization
2. **Services**: Implement business logic in `lib/services/` following existing patterns
3. **Handlers**: Create HTTP handlers in `lib/handlers/` with proper error handling
4. **Routes**: Register new routes in `lib/server.dart`
5. **Tests**: Add corresponding tests in `test/` directory

### Running Tests

```bash
# Run all tests
dart test

# Run specific test file
dart test test/server_test.dart

# Run tests with coverage
dart test --coverage=coverage
dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
```

### Code Quality

```bash
# Analyze code
dart analyze

# Format code
dart format .

# Fix common issues
dart fix --apply
```

## 🚀 Production Deployment

### Docker Deployment
Create a `Dockerfile`:
```dockerfile
FROM dart:stable AS build
WORKDIR /app

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 /flutter
ENV PATH="/flutter/bin:${PATH}"
RUN flutter doctor

# Copy and build application
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart compile exe bin/buildengine_server.dart -o buildengine_server

FROM ubuntu:22.04
RUN apt-get update && apt-get install -y \
    ca-certificates \
    git \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter in production image
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 /flutter
ENV PATH="/flutter/bin:${PATH}"
RUN flutter doctor

COPY --from=build /app/buildengine_server /app/buildengine_server
WORKDIR /app

# Create storage directories
RUN mkdir -p storage/uploads storage/artifacts workspace

EXPOSE 8788
CMD ["./buildengine_server"]
```

### Docker Compose
```yaml
version: '3.8'
services:
  buildengine:
    build: .
    ports:
      - "8788:8788"
    environment:
      - PORT=8788
      - HOST=0.0.0.0
      - STORAGE_TYPE=local
      - ENVIRONMENT=production
    volumes:
      - ./storage:/app/storage
      - ./workspace:/app/workspace
    restart: unless-stopped
```

### Environment Setup
1. **Storage**: Configure Google Cloud Storage for production scalability
2. **Monitoring**: Set up logging and health checks
3. **Reverse Proxy**: Use nginx or load balancer for SSL termination
4. **Security**: Implement rate limiting and authentication if needed
5. **Scaling**: Consider horizontal scaling for high-traffic scenarios

### Health Monitoring
```bash
# Check server health
curl http://your-domain.com/health

# Monitor build queue
curl http://your-domain.com/v1/jobs?status=queued
```

## 📋 API Compliance

This implementation follows the BuildEngine Server API PRD v1 specification:
- ✅ All endpoints versioned under `/v1`
- ✅ Proper HTTP status codes and error responses
- ✅ CORS headers for web compatibility
- ✅ JSON request/response format
- ✅ Multipart file upload support
- ✅ Pagination support for job listings
- ✅ Time-limited artifact URLs
- ✅ Real-time build execution
- ✅ Comprehensive logging system

## 🔄 Build Pipeline Status

The server executes real Flutter builds through the following pipeline:

1. **Source Download** → Extract source code from uploads/git/FlutterFlow
2. **Pre-Build Steps** → Execute custom commands (flutter pub get, etc.)
3. **Flutter Build** → Run platform-specific Flutter build commands
4. **Post-Build Steps** → Execute custom post-processing commands
5. **Artifact Packaging** → Create downloadable ZIP archives
6. **Storage** → Save artifacts with secure access URLs

## 🔧 Troubleshooting

### SQLite Library Issues

If you encounter the error `Failed to load dynamic library 'libsqlite3.so'`, this is a common issue on Linux systems where the SQLite library has a different name.

**Solution 1: Use the provided startup script**
```bash
# From the project root directory
./start_server.sh
```

**Solution 2: Manual fix**
```bash
cd server
mkdir -p lib
ln -sf /usr/lib/aarch64-linux-gnu/libsqlite3.so.0 lib/libsqlite3.so
LD_LIBRARY_PATH=./lib:$LD_LIBRARY_PATH dart run bin/buildengine_server.dart
```

**Solution 3: System-wide fix (requires sudo)**
```bash
sudo ln -sf /usr/lib/aarch64-linux-gnu/libsqlite3.so.0 /usr/lib/aarch64-linux-gnu/libsqlite3.so
```

## 📞 Support & Documentation

- **API Documentation**: Refer to `docs/api_prd.md` for complete API specification
- **Implementation Details**: Check `IMPLEMENTATION_SUMMARY.md` for architecture overview
- **Real Job Processing**: See `REAL_JOB_PROCESSING.md` for build pipeline details
- **Storage Configuration**: Review `STORAGE_CONFIG.md` for storage setup
- **FlutterFlow Integration**: See `FLUTTERFLOW_CLI_INTEGRATION.md` for FlutterFlow support

## 📄 License

This project is provided as-is for development and testing purposes.

## 🐛 Issues & Contributions

For issues, feature requests, or contributions, please refer to the project repository.
