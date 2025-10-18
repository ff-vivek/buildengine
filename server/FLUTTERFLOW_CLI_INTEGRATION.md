# FlutterFlow CLI Integration Example

This document shows how to use the new FlutterFlow CLI integration feature.

## API Request Example

To create a build job using FlutterFlow CLI, send a POST request to `/api/jobs` with the following JSON payload:

```json
{
  "source": {
    "type": "flutterFlow",
    "ffProjectId": "error-prone-app-hcoay3",
    "ffEndpoint": "https://api-enterprise-india.flutterflow.io/v2",
    "ffProjectEnvironment": "Production",
    "ffToken": "4027b429-9b14-48cf-a865-bf5202ebd61c",
    "ffIncludeAssets": true
  },
  "config": {
    "buildType": "release",
    "platform": "web",
    "flutterVersion": "3.24.0",
    "targetFile": "lib/main.dart",
    "preSteps": [],
    "postSteps": []
  }
}
```

## FlutterFlow CLI Command Generated

The system will automatically generate and execute the following FlutterFlow CLI command:

```bash
flutterflow export-code \
  --project error-prone-app-hcoay3 \
  --endpoint https://api-enterprise-india.flutterflow.io/v2 \
  --project-environment Production \
  --token 4027b429-9b14-48cf-a865-bf5202ebd61c \
  --include-assets
```

## Workspace Structure Handling

The build system automatically handles different workspace structures:

### Direct Project Structure
```
workspace/job_id/
├── pubspec.yaml
├── lib/
│   └── main.dart
└── ...
```

### Nested Project Structure (FlutterFlow CLI)
```
workspace/job_id/
└── project_folder/
    ├── pubspec.yaml
    ├── lib/
    │   └── main.dart
    └── ...
```

The system automatically detects the correct Flutter project directory by looking for `pubspec.yaml` files, ensuring builds work regardless of the project structure.

## Required Fields

- `ffProjectId`: The FlutterFlow project ID
- `ffToken`: Authentication token for FlutterFlow API
- `ffEndpoint`: FlutterFlow API endpoint URL

## Optional Fields

- `ffProjectEnvironment`: Project environment (defaults to "Production")
- `ffIncludeAssets`: Whether to include assets (defaults to true)

## Prerequisites

The FlutterFlow CLI will be automatically installed if not available. The system requires:

- Dart SDK installed on the server
- The system will automatically run: `dart pub global activate flutterflow_cli`

If automatic installation fails, you can manually install it:

```bash
dart pub global activate flutterflow_cli
```

## Error Handling

The system will automatically attempt to install FlutterFlow CLI if it's not available. If automatic installation fails, the build will fail with a clear error message:

```
Failed to install FlutterFlow CLI. Please install it manually using: dart pub global activate flutterflow_cli
```

If no Flutter project is found in the workspace, the build will fail with:

```
No Flutter project found in workspace: /path/to/workspace
```
