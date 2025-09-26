# Real Job Processing Implementation

## Overview

The BuildEngine Server now performs real Flutter app builds instead of simulated processing. The system handles the complete build pipeline from source download to artifact packaging.

## Architecture

### Core Services

1. **`SourceDownloader`** - Downloads and extracts source code from various sources
2. **`FlutterBuildService`** - Executes Flutter builds and custom steps
3. **`ArtifactPackagingService`** - Packages build artifacts for distribution
4. **`JobService`** - Orchestrates the entire build process

### Build Pipeline

The real job processing follows these steps:

```
1. Queue Job
   ↓
2. Download Source Code
   ↓
3. Execute Pre-Steps
   ↓
4. Build Flutter App
   ↓
5. Execute Post-Steps
   ↓
6. Package Artifacts
   ↓
7. Store Artifacts
   ↓
8. Complete Job
```

## Source Download

### Supported Source Types

#### 1. Upload ZIP (`SourceType.uploadZip`)
- Downloads uploaded ZIP files from storage
- Extracts source code to workspace directory
- Validates upload exists before processing

#### 2. FlutterFlow (`SourceType.flutterFlow`)
- Downloads source from FlutterFlow API
- Supports authentication via token
- Extracts ZIP content to workspace

#### 3. Git Repository (`SourceType.gitRepo`)
- Clones Git repositories using `git clone`
- Supports branch specification
- Creates local workspace copy

### Implementation Details

```dart
// Example usage
final source = BuildSource(
  type: SourceType.gitRepo,
  gitUrl: 'https://github.com/user/repo.git',
  branch: 'main',
);

final workspaceDir = await sourceDownloader.downloadSource(source, jobId);
```

## Flutter Build Process

### Build Types

- **Release**: `flutter build apk --release`
- **Debug**: `flutter build apk --debug`
- **Profile**: `flutter build apk --profile`

### Build Steps

1. **Dependency Resolution**: `flutter pub get`
2. **Pre-Steps**: Custom commands before build
3. **Flutter Build**: Platform-specific build command
4. **Post-Steps**: Custom commands after build

### Custom Steps

Pre and post steps support arbitrary shell commands:

```dart
final config = BuildConfig(
  buildType: BuildType.release,
  preSteps: [
    'npm install',
    'flutter clean',
  ],
  postSteps: [
    'flutter test',
    'cp build/app/outputs/flutter-apk/app-release.apk dist/',
  ],
);
```

## Artifact Packaging

### Package Contents

The artifact package includes:

- **Main Build Output**: APK file
- **Build Logs**: Flutter build logs and errors
- **Project Files**: pubspec.yaml, README.md, etc.
- **Build Metadata**: Job ID, build time, file sizes
- **Additional Artifacts**: Any files from build directory

### Package Structure

```
artifact.zip
├── app.apk                    # Main build output
├── pubspec.yaml              # Project configuration
├── README.md                 # Project documentation
├── build_metadata.txt        # Build information
├── logs/                     # Build logs
│   ├── build.log
│   └── flutter_build.log
└── project/                  # Additional project files
    └── lib/
        └── main.dart
```

## Error Handling

### Comprehensive Error Management

- **Source Download Errors**: Network failures, invalid URLs, authentication issues
- **Build Errors**: Flutter installation issues, dependency conflicts, build failures
- **Packaging Errors**: File system issues, storage failures
- **Cleanup Errors**: Workspace cleanup failures (logged but non-fatal)

### Error Recovery

- Automatic cleanup on failure
- Detailed error logging
- Job status updates with error messages
- Graceful degradation

## Workspace Management

### Directory Structure

```
workspace/
├── job_12345678/             # Job-specific workspace
│   ├── lib/                  # Source code
│   ├── pubspec.yaml          # Dependencies
│   ├── build/                # Build artifacts
│   │   └── app/
│   │       └── outputs/
│   │           └── flutter-apk/
│   │               └── app-release.apk
│   └── temp_artifacts/       # Temporary files
```

### Cleanup Process

- **Automatic Cleanup**: After job completion or failure
- **Workspace Cleanup**: Removes job-specific directories
- **Build Cleanup**: Removes build artifacts
- **Temporary Cleanup**: Removes temporary files

## Requirements

### System Requirements

- **Flutter SDK**: Must be installed and in PATH
- **Git**: Required for Git repository cloning
- **Dart SDK**: Required for Flutter builds
- **Storage**: Sufficient disk space for builds and artifacts

### Environment Setup

```bash
# Install Flutter
flutter --version

# Verify Git
git --version

# Check Dart
dart --version
```

## Configuration

### Build Configuration

```dart
final config = BuildConfig(
  flutterVersion: '3.16.0',           // Flutter version
  buildType: BuildType.release,        // Build type
  targetFile: 'lib/main.dart',        // Entry point
  preSteps: ['flutter clean'],         // Pre-build commands
  postSteps: ['flutter test'],         // Post-build commands
);
```

### Environment Variables

- `STORAGE_TYPE`: Storage backend (local/gcp)
- `LOCAL_STORAGE_PATH`: Local storage directory
- `GCP_PROJECT_ID`: Google Cloud project ID
- `GCP_BUCKET_NAME`: Google Cloud Storage bucket

## Monitoring and Logging

### Log Levels

- **INFO**: Normal operation messages
- **WARNING**: Non-fatal issues
- **SEVERE**: Critical errors
- **ERROR**: Job failures

### Log Structure

```json
{
  "timestamp": "2024-01-15T10:30:00.000Z",
  "level": "INFO",
  "message": "Flutter app built successfully: /workspace/job_12345678/build/app/outputs/flutter-apk/app-release.apk"
}
```

## Performance Considerations

### Build Optimization

- **Parallel Processing**: Multiple jobs can run simultaneously
- **Workspace Isolation**: Each job has its own workspace
- **Efficient Cleanup**: Automatic cleanup prevents disk space issues
- **Caching**: Flutter's built-in caching for dependencies

### Resource Management

- **Memory Usage**: Monitored during builds
- **Disk Space**: Automatic cleanup prevents accumulation
- **CPU Usage**: Build processes are resource-intensive
- **Network**: Source downloads and artifact uploads

## Security Considerations

### Source Security

- **Authentication**: Support for Git tokens and API keys
- **Validation**: Source validation before processing
- **Isolation**: Workspace isolation prevents cross-contamination

### Build Security

- **Sandboxing**: Each job runs in isolated workspace
- **Cleanup**: Sensitive data removed after build
- **Logging**: No sensitive data in logs

## Future Enhancements

### Planned Features

- **Multi-Platform Builds**: iOS, Web, Desktop support
- **Build Caching**: Shared dependency cache
- **Build Optimization**: Incremental builds
- **Custom Build Tools**: Support for additional build tools
- **Build Metrics**: Performance monitoring and analytics
- **Parallel Builds**: Multiple platform builds simultaneously

### Integration Opportunities

- **CI/CD Integration**: GitHub Actions, GitLab CI
- **Cloud Build Services**: Google Cloud Build, AWS CodeBuild
- **Container Support**: Docker-based builds
- **Kubernetes**: Container orchestration for builds
