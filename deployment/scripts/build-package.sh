#!/bin/bash

# BuildEngine Server Build and Package Script
# This script compiles the server and creates a distributable package

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="/home/vivek/Documents/projects/buildengine"
SERVER_DIR="$PROJECT_ROOT/server"
DEPLOYMENT_DIR="$PROJECT_ROOT/deployment"
BUILD_DIR="$PROJECT_ROOT/build"
PACKAGE_NAME="buildengine-server-linux"
VERSION="1.0.0"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check dependencies
check_dependencies() {
    print_status "Checking dependencies..."
    
    if ! command -v dart &> /dev/null; then
        print_error "Dart SDK not found. Please install Dart SDK first."
        exit 1
    fi
    
    if ! command -v tar &> /dev/null; then
        print_error "tar not found. Please install tar."
        exit 1
    fi
    
    print_success "Dependencies check passed"
}

# Function to clean build directory
clean_build() {
    print_status "Cleaning build directory..."
    
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
    fi
    
    mkdir -p "$BUILD_DIR"
    print_success "Build directory cleaned"
}

# Function to compile the server
compile_server() {
    print_status "Compiling BuildEngine server..."
    
    cd "$SERVER_DIR"
    
    # Get dependencies
    print_status "Getting Dart dependencies..."
    dart pub get
    
    # Compile to executable
    print_status "Compiling to native executable..."
    dart compile exe bin/buildengine_server.dart -o buildengine_server
    
    if [ ! -f "buildengine_server" ]; then
        print_error "Failed to compile server executable"
        exit 1
    fi
    
    print_success "Server compiled successfully"
}

# Function to create package structure
create_package_structure() {
    print_status "Creating package structure..."
    
    PACKAGE_DIR="$BUILD_DIR/$PACKAGE_NAME"
    mkdir -p "$PACKAGE_DIR"
    
    # Copy server executable
    cp "$SERVER_DIR/buildengine_server" "$PACKAGE_DIR/"
    
    # Copy deployment files
    cp -r "$DEPLOYMENT_DIR"/* "$PACKAGE_DIR/"
    
    # Create additional directories
    mkdir -p "$PACKAGE_DIR/examples"
    mkdir -p "$PACKAGE_DIR/docs"
    
    print_success "Package structure created"
}

# Function to create example configurations
create_examples() {
    print_status "Creating example configurations..."
    
    PACKAGE_DIR="$BUILD_DIR/$PACKAGE_NAME"
    
    # Create development configuration
    cat > "$PACKAGE_DIR/examples/config-dev.yaml" << 'EOF'
# Development Configuration
server:
  host: "127.0.0.1"
  port: 8080
  
database:
  path: "./buildengine-dev.db"
  
storage:
  local_path: "./storage"
  workspace_path: "./workspace"
  
logging:
  level: "DEBUG"
  file: "./buildengine-dev.log"
  enable_console: true
  
build:
  max_concurrent_jobs: 2
  build_timeout: 600
  
security:
  enable_cors: true
  allowed_origins: ["*"]
EOF

    # Create production configuration
    cat > "$PACKAGE_DIR/examples/config-prod.yaml" << 'EOF'
# Production Configuration
server:
  host: "0.0.0.0"
  port: 8080
  
database:
  path: "/var/lib/buildengine/buildengine.db"
  
storage:
  local_path: "/var/lib/buildengine/storage"
  workspace_path: "/var/lib/buildengine/workspace"
  max_storage_size: 10737418240  # 10GB
  cleanup_after_days: 30
  
logging:
  level: "INFO"
  file: "/var/log/buildengine/buildengine.log"
  max_file_size: 104857600  # 100MB
  max_files: 5
  enable_console: false
  
build:
  max_concurrent_jobs: 5
  build_timeout: 1800  # 30 minutes
  enable_caching: true
  
security:
  enable_cors: true
  allowed_origins: ["https://yourdomain.com"]
  enable_api_key: true
  api_key: "your-secure-api-key"
  
rate_limiting:
  enabled: true
  requests_per_minute: 60
  burst_limit: 10
EOF

    # Create Docker configuration
    cat > "$PACKAGE_DIR/examples/Dockerfile" << 'EOF'
FROM ubuntu:22.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Dart SDK
RUN curl -fsSL https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-linux-x64-release.zip -o dart-sdk.zip \
    && unzip dart-sdk.zip \
    && mv dart-sdk /opt/dart-sdk \
    && rm dart-sdk.zip

# Add Dart to PATH
ENV PATH="/opt/dart-sdk/bin:$PATH"

# Create app directory
WORKDIR /app

# Copy server executable
COPY buildengine_server /app/

# Create directories
RUN mkdir -p /app/storage /app/workspace /app/logs

# Create non-root user
RUN groupadd -r buildengine && useradd -r -g buildengine buildengine
RUN chown -R buildengine:buildengine /app

# Switch to non-root user
USER buildengine

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Run the server
CMD ["./buildengine_server", "--config", "/app/config.yaml"]
EOF

    # Create docker-compose configuration
    cat > "$PACKAGE_DIR/examples/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  buildengine:
    build: .
    ports:
      - "8080:8080"
    volumes:
      - ./config.yaml:/app/config.yaml:ro
      - buildengine-storage:/app/storage
      - buildengine-workspace:/app/workspace
      - buildengine-logs:/app/logs
    environment:
      - BUILDENGINE_CONFIG=/app/config.yaml
      - BUILDENGINE_DATA=/app
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  buildengine-storage:
  buildengine-workspace:
  buildengine-logs:
EOF

    print_success "Example configurations created"
}

# Function to create API documentation
create_api_docs() {
    print_status "Creating API documentation..."
    
    PACKAGE_DIR="$BUILD_DIR/$PACKAGE_NAME"
    
    cat > "$PACKAGE_DIR/docs/API.md" << 'EOF'
# BuildEngine API Documentation

## Base URL
```
http://localhost:8080/api
```

## Authentication
Currently, the API does not require authentication. For production deployments, consider enabling API key authentication.

## Endpoints

### Health Check
```http
GET /health
```

### Jobs

#### Create Job
```http
POST /api/jobs
Content-Type: application/json

{
  "source": {
    "type": "uploadZip|gitRepo|flutterFlow",
    "uploadId": "string",           // For uploadZip
    "gitUrl": "string",             // For gitRepo
    "branch": "string",             // For gitRepo
    "ffProjectId": "string",        // For flutterFlow
    "ffEndpoint": "string",         // For flutterFlow
    "ffToken": "string",            // For flutterFlow
    "ffProjectEnvironment": "string", // For flutterFlow
    "ffIncludeAssets": boolean      // For flutterFlow
  },
  "config": {
    "buildType": "debug|release",
    "platform": "web|android|ios",
    "flutterVersion": "string",
    "targetFile": "string",
    "preSteps": ["string"],
    "postSteps": ["string"]
  }
}
```

#### Get Job Status
```http
GET /api/jobs/{jobId}
```

#### List Jobs
```http
GET /api/jobs?limit=10&offset=0
```

### Uploads

#### Upload File
```http
POST /api/uploads
Content-Type: multipart/form-data

file: <binary data>
```

#### Get Upload Info
```http
GET /api/uploads/{uploadId}
```

### Artifacts

#### Download Artifact
```http
GET /api/artifacts/{jobId}/download
```

#### Get Artifact Info
```http
GET /api/artifacts/{jobId}
```

### Logs

#### Get Job Logs
```http
GET /api/logs/{jobId}
```

### Feedback

#### Submit Feedback
```http
POST /api/feedback
Content-Type: application/json

{
  "jobId": "string",
  "rating": 1-5,
  "comments": "string",
  "contactEmail": "string"
}
```

## Response Formats

### Success Response
```json
{
  "success": true,
  "data": { ... },
  "message": "string"
}
```

### Error Response
```json
{
  "success": false,
  "error": "string",
  "message": "string"
}
```

### Job Status
```json
{
  "id": "string",
  "status": "pending|running|completed|failed",
  "createdAt": "ISO 8601 timestamp",
  "updatedAt": "ISO 8601 timestamp",
  "source": { ... },
  "config": { ... },
  "result": {
    "artifactPath": "string",
    "buildLog": "string",
    "error": "string"
  }
}
```

## Example Usage

### Upload and Build a Flutter Project

1. **Upload ZIP file**:
```bash
curl -X POST http://localhost:8080/api/uploads \
  -F "file=@my-flutter-app.zip"
```

2. **Create build job**:
```bash
curl -X POST http://localhost:8080/api/jobs \
  -H "Content-Type: application/json" \
  -d '{
    "source": {
      "type": "uploadZip",
      "uploadId": "upload-id-from-step-1"
    },
    "config": {
      "buildType": "release",
      "platform": "web",
      "flutterVersion": "3.24.0"
    }
  }'
```

3. **Check job status**:
```bash
curl http://localhost:8080/api/jobs/job-id
```

4. **Download artifact**:
```bash
curl -O http://localhost:8080/api/artifacts/job-id/download
```

### Build from Git Repository

```bash
curl -X POST http://localhost:8080/api/jobs \
  -H "Content-Type: application/json" \
  -d '{
    "source": {
      "type": "gitRepo",
      "gitUrl": "https://github.com/user/flutter-app.git",
      "branch": "main"
    },
    "config": {
      "buildType": "release",
      "platform": "android",
      "flutterVersion": "3.24.0"
    }
  }'
```

### Build FlutterFlow Project

```bash
curl -X POST http://localhost:8080/api/jobs \
  -H "Content-Type: application/json" \
  -d '{
    "source": {
      "type": "flutterFlow",
      "ffProjectId": "your-project-id",
      "ffEndpoint": "https://api.flutterflow.io/v2",
      "ffToken": "your-api-token",
      "ffProjectEnvironment": "Production",
      "ffIncludeAssets": true
    },
    "config": {
      "buildType": "release",
      "platform": "web",
      "flutterVersion": "3.24.0"
    }
  }'
```
EOF

    print_success "API documentation created"
}

# Function to create package manifest
create_manifest() {
    print_status "Creating package manifest..."
    
    PACKAGE_DIR="$BUILD_DIR/$PACKAGE_NAME"
    
    cat > "$PACKAGE_DIR/MANIFEST.txt" << EOF
BuildEngine Server Linux Package
Version: $VERSION
Build Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Build Host: $(hostname)

Contents:
- buildengine_server: Main server executable
- scripts/install.sh: Automated installation script
- config/: Configuration files and systemd service
- docs/: Documentation and API reference
- examples/: Example configurations and Docker files

Installation:
1. Extract this package
2. Run: sudo ./scripts/install.sh

Manual Installation:
1. Copy buildengine_server to /opt/buildengine/bin/
2. Copy config files to /etc/buildengine/
3. Create systemd service
4. Start service

For more information, see docs/README.md
EOF

    print_success "Package manifest created"
}

# Function to create final package
create_package() {
    print_status "Creating final package..."
    
    cd "$BUILD_DIR"
    
    # Create tar.gz package
    tar -czf "${PACKAGE_NAME}-${VERSION}.tar.gz" "$PACKAGE_NAME"
    
    # Create checksum
    sha256sum "${PACKAGE_NAME}-${VERSION}.tar.gz" > "${PACKAGE_NAME}-${VERSION}.tar.gz.sha256"
    
    # Get package info
    PACKAGE_SIZE=$(du -h "${PACKAGE_NAME}-${VERSION}.tar.gz" | cut -f1)
    
    print_success "Package created: ${PACKAGE_NAME}-${VERSION}.tar.gz"
    print_success "Package size: $PACKAGE_SIZE"
    print_success "Checksum: ${PACKAGE_NAME}-${VERSION}.tar.gz.sha256"
}

# Function to display summary
show_summary() {
    print_success "BuildEngine Server package created successfully!"
    echo
    echo "Package Information:"
    echo "===================="
    echo "Package Name: ${PACKAGE_NAME}-${VERSION}.tar.gz"
    echo "Package Size: $(du -h "$BUILD_DIR/${PACKAGE_NAME}-${VERSION}.tar.gz" | cut -f1)"
    echo "Build Directory: $BUILD_DIR"
    echo
    echo "Package Contents:"
    echo "================="
    echo "- buildengine_server: Compiled server executable"
    echo "- scripts/install.sh: Automated installation script"
    echo "- config/: Configuration files and systemd service"
    echo "- docs/: Complete documentation"
    echo "- examples/: Example configurations and Docker files"
    echo
    echo "Installation Instructions:"
    echo "========================="
    echo "1. Extract the package:"
    echo "   tar -xzf ${PACKAGE_NAME}-${VERSION}.tar.gz"
    echo
    echo "2. Run the installer:"
    echo "   cd ${PACKAGE_NAME}"
    echo "   sudo ./scripts/install.sh"
    echo
    echo "3. Verify installation:"
    echo "   sudo systemctl status buildengine"
    echo "   curl http://localhost:8080/health"
    echo
    print_success "Package is ready for distribution!"
}

# Main build function
main() {
    echo "BuildEngine Server Build Script"
    echo "================================="
    echo
    
    check_dependencies
    clean_build
    compile_server
    create_package_structure
    create_examples
    create_api_docs
    create_manifest
    create_package
    show_summary
}

# Run main function
main "$@"

