# Storage Configuration

The BuildEngine Server supports two storage backends:

## Local Storage (Default)

When running locally, files are stored in the local filesystem.

### Configuration

Set the following environment variables:

```bash
STORAGE_TYPE=local
LOCAL_STORAGE_PATH=storage  # Optional, defaults to 'storage'
BASE_URL=http://localhost:8788
```

### Directory Structure

```
storage/
├── uploads/          # Temporary upload files
└── artifacts/        # Build artifacts
```

## Google Cloud Storage

When running on Google Cloud Platform, files are stored in Google Cloud Storage.

### Configuration

Set the following environment variables:

```bash
STORAGE_TYPE=gcp
GCP_PROJECT_ID=your-project-id
GCP_BUCKET_NAME=buildengine-storage
GCP_SERVICE_ACCOUNT_PATH=/path/to/service-account.json
# OR
GCP_SERVICE_ACCOUNT_JSON={"type":"service_account","project_id":"..."}
BASE_URL=https://your-domain.com
ENVIRONMENT=production
```

### Authentication

The service supports multiple authentication methods:

1. **Service Account JSON File**: Set `GCP_SERVICE_ACCOUNT_PATH` to the path of your service account JSON file
2. **Service Account JSON Content**: Set `GCP_SERVICE_ACCOUNT_JSON` to the JSON content directly
3. **Default Credentials**: If running on GCP (App Engine, Compute Engine, etc.), the service will use default credentials

### Required Permissions

Your service account needs the following IAM roles:
- `Storage Object Admin` or `Storage Admin`
- `Storage Legacy Bucket Reader` (for bucket access)

## Running the Server

### Local Development

```bash
# Using local storage (default)
dart run bin/buildengine_server.dart

# Or explicitly set local storage
STORAGE_TYPE=local dart run bin/buildengine_server.dart
```

### Google Cloud Platform

```bash
# Using Google Cloud Storage
STORAGE_TYPE=gcp \
GCP_PROJECT_ID=my-project \
GCP_BUCKET_NAME=my-bucket \
GCP_SERVICE_ACCOUNT_PATH=/path/to/service-account.json \
dart run bin/buildengine_server.dart
```

### Docker

```bash
# Local storage
docker run -e STORAGE_TYPE=local buildengine-server

# Google Cloud Storage
docker run \
  -e STORAGE_TYPE=gcp \
  -e GCP_PROJECT_ID=my-project \
  -e GCP_BUCKET_NAME=my-bucket \
  -v /path/to/service-account.json:/app/service-account.json \
  -e GCP_SERVICE_ACCOUNT_PATH=/app/service-account.json \
  buildengine-server
```

## Environment Variables Reference

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `STORAGE_TYPE` | Storage backend (`local` or `gcp`) | `local` | No |
| `LOCAL_STORAGE_PATH` | Local storage directory | `storage` | No |
| `GCP_PROJECT_ID` | Google Cloud project ID | - | Yes (for GCP) |
| `GCP_BUCKET_NAME` | Google Cloud Storage bucket name | `buildengine-storage` | No |
| `GCP_SERVICE_ACCOUNT_PATH` | Path to service account JSON file | - | No |
| `GCP_SERVICE_ACCOUNT_JSON` | Service account JSON content | - | No |
| `BASE_URL` | Base URL for the server | `http://localhost:8788` | No |
| `ENVIRONMENT` | Environment (`development` or `production`) | `development` | No |

## Migration

To migrate from local storage to Google Cloud Storage:

1. Set up your GCP project and bucket
2. Create a service account with appropriate permissions
3. Update your environment variables
4. Restart the server

The server will automatically use the configured storage backend without requiring code changes.
