# BuildEngine Server - Storage Configuration Implementation

## Overview

The BuildEngine Server now supports both local and cloud storage backends, automatically selecting the appropriate storage method based on environment configuration.

## Implementation Details

### Architecture

The storage system uses a strategy pattern with the following components:

1. **`StorageInterface`** - Abstract interface defining storage operations
2. **`LocalStorageService`** - Local filesystem storage implementation
3. **`GoogleCloudStorageService`** - Google Cloud Storage implementation
4. **`StorageService`** - Main service that delegates to the appropriate implementation
5. **`EnvironmentConfig`** - Environment-based configuration management

### Storage Backends

#### Local Storage (Default)
- Stores files in local filesystem directories
- Uses `storage/uploads/` and `storage/artifacts/` directories
- Generates local URLs for file access
- Automatic cleanup of expired files

#### Google Cloud Storage
- Stores files in Google Cloud Storage buckets
- Uses HTTP REST API for operations
- Supports service account authentication
- Automatic cleanup of expired files

### Environment Configuration

The system uses environment variables to configure storage:

```bash
# Storage type selection
STORAGE_TYPE=local  # or 'gcp'

# Local storage configuration
LOCAL_STORAGE_PATH=storage

# Google Cloud Storage configuration
GCP_PROJECT_ID=your-project-id
GCP_BUCKET_NAME=buildengine-storage
GCP_SERVICE_ACCOUNT_PATH=/path/to/service-account.json
# OR
GCP_SERVICE_ACCOUNT_JSON={"type":"service_account",...}

# Server configuration
BASE_URL=http://localhost:8788
ENVIRONMENT=development
```

### Usage Examples

#### Local Development
```bash
# Default (local storage)
dart run bin/buildengine_server.dart

# Explicit local storage
STORAGE_TYPE=local dart run bin/buildengine_server.dart
```

#### Google Cloud Platform
```bash
STORAGE_TYPE=gcp \
GCP_PROJECT_ID=my-project \
GCP_BUCKET_NAME=my-bucket \
GCP_SERVICE_ACCOUNT_PATH=/path/to/service-account.json \
dart run bin/buildengine_server.dart
```

### Features

- **Automatic Storage Selection**: Based on `STORAGE_TYPE` environment variable
- **Environment Logging**: Server logs which storage backend is being used
- **Unified Interface**: Same API regardless of storage backend
- **Error Handling**: Comprehensive error handling and logging
- **Cleanup**: Automatic cleanup of expired uploads
- **Authentication**: Multiple authentication methods for GCP

### File Structure

```
server/
├── lib/
│   ├── config/
│   │   └── environment_config.dart
│   └── services/
│       ├── storage_interface.dart
│       ├── storage_service.dart
│       ├── local_storage_service.dart
│       └── google_cloud_storage_service.dart
├── env.example
└── STORAGE_CONFIG.md
```

### Migration

To migrate from local to cloud storage:

1. Set up GCP project and bucket
2. Create service account with appropriate permissions
3. Update environment variables
4. Restart server

No code changes required - the system automatically switches storage backends based on configuration.

### Security Notes

- Service account credentials should be stored securely
- Use environment variables or secure credential management
- Consider using IAM roles with minimal required permissions
- Enable audit logging for production deployments

### Future Enhancements

- Signed URL generation for secure file access
- Additional cloud storage providers (AWS S3, Azure Blob)
- File compression and optimization
- Advanced cleanup policies
- Storage metrics and monitoring
