# BuildBeacon 🚀

**BuildEngine is your personal Flutter web build factory!** Upload your project, pick your settings, and get a perfectly packaged web build ready for deployment – all with a friendly, intuitive interface.

BuildBeacon is the official Flutter frontend for the BuildEngine Server, providing a modern web interface for creating, monitoring, and downloading Flutter builds.

## ✨ Features

- **🎯 4-Step Build Wizard**: Intuitive stepper interface for creating builds
- **📁 Multiple Source Types**: Support for ZIP uploads, FlutterFlow projects, and Git repositories
- **⚡ Real-time Monitoring**: Live build progress tracking with status updates
- **📊 Build Logs**: Real-time log streaming with filtering and search
- **🎨 Modern UI**: Clean, responsive design with excellent UX
- **📱 Multi-platform**: Runs on web, desktop, and mobile
- **🌙 Theme Support**: Light and dark mode themes
- **📈 Build History**: Complete job history with filtering and pagination
- **⬬ Artifact Downloads**: Direct download links for completed builds
- **🔧 Flexible Configuration**: Support for custom pre/post-build steps

## 🛠️ Tech Stack

- **Framework**: Flutter 3.6+
- **State Management**: Riverpod 3.0
- **Navigation**: GoRouter 16.0
- **HTTP Client**: Dio 5.0
- **File Upload**: FilePicker 8.1+
- **Real-time Updates**: WebSocket Channel 3.0
- **UI Components**: Material Design with custom theming
- **Architecture**: Clean architecture with data/domain/presentation layers

## 📋 Prerequisites

- **Flutter SDK**: 3.6.0 or higher
- **Dart SDK**: 3.6.0 or higher
- **BuildEngine Server**: Running instance for API connectivity

## 🚀 Getting Started

### 1. Clone and Setup

```bash
cd buildengine_server/frontend/buildbeacon
flutter pub get
```

### 2. Configure API Endpoint

Update the API endpoint in `lib/utils/constants.dart`:

```dart
class AppConstants {
  static const String baseUrl = 'http://127.0.0.1:8788'; // Your server URL
  // ... other constants
}
```

### 3. Run the Application

```bash
# Development mode
flutter run -d chrome

# Or for web with specific port
flutter run -d web-server --web-port 3000

# Build for production
flutter build web
```

## 🏗️ Project Structure

```
lib/
├── main.dart                    # Application entry point
├── theme.dart                   # Light/dark theme definitions
├── app/
│   ├── router.dart             # GoRouter configuration
│   └── providers.dart          # Global Riverpod providers
├── data/
│   ├── api/
│   │   └── build_api_client.dart    # HTTP API client
│   ├── models/
│   │   ├── build_models_simple.dart # Data models
│   │   └── api_response.dart        # API response models
│   └── repositories/
│       └── build_repository.dart    # Data access layer
├── presentation/
│   ├── screens/
│   │   ├── dashboard_screen.dart    # Main job list screen
│   │   ├── new_build_screen.dart    # Build creation wizard
│   │   ├── job_detail_screen.dart   # Job monitoring screen
│   │   └── settings_screen.dart     # App settings
│   └── widgets/
│       ├── step_indicator.dart      # Stepper progress indicator
│       ├── status_chip.dart         # Job status indicators
│       ├── build_logs_viewer.dart   # Real-time log viewer
│       ├── jobs_filter_bar.dart     # Job filtering controls
│       └── source_selection_step.dart # Source type selection
└── utils/
    ├── constants.dart          # App-wide constants
    ├── validators.dart         # Form validation helpers
    └── artifact_readiness.dart # Build artifact helpers
```

## 🎯 User Journey

### 1. Dashboard Overview
- View all build jobs with status indicators
- Filter jobs by status, date, or source type
- Quick access to job details and logs
- Create new builds with floating action button

### 2. Build Creation (4-Step Wizard)

#### Step 1: Source Selection
- **ZIP Upload**: Drag & drop or select Flutter project ZIP files
- **FlutterFlow**: Import directly from FlutterFlow with project URL and token
- **Git Repository**: Clone from public/private Git repositories

#### Step 2: Build Configuration
- Select Flutter version (default or specific version)
- Choose build type (release, debug, profile)
- Configure target platforms (web, APK, iOS, etc.)
- Set entry point file (`lib/main.dart`)

#### Step 3: Custom Steps
- Define pre-build commands (`flutter clean`, `pub get`)
- Set post-build commands for custom processing
- Validate command safety (Flutter/Dart commands only)

#### Step 4: Review & Submit
- Review all configuration settings
- Preview build commands that will be executed
- Submit job and redirect to monitoring

### 3. Real-time Monitoring
- Live job status updates with progress indicators
- Real-time log streaming with automatic scrolling
- Build pipeline visualization
- Artifact download when build completes
- Option to cancel running builds

## 📡 API Integration

BuildBeacon connects to the BuildEngine Server API with the following capabilities:

### HTTP Endpoints
```dart
// Job management
GET  /v1/jobs              // List jobs with pagination
POST /v1/jobs              // Create new build job
GET  /v1/jobs/{id}         // Get job details
POST /v1/jobs/{id}/cancel  // Cancel running job

// Upload management
POST /v1/uploads           // Initialize file upload
POST /v1/uploads/{id}      // Upload ZIP file

// Logs and artifacts
GET  /v1/jobs/{id}/logs    // Get build logs
GET  /v1/jobs/{id}/artifact // Get artifact download URL

// Health check
GET  /health               // Server status
```

### Real-time Features
- **WebSocket Logs**: Live log streaming during builds
- **Auto-refresh**: Periodic job status updates
- **Optimistic UI**: Immediate feedback for better UX

## 🎨 UI/UX Design

### Design Principles
- **Modern & Clean**: Avoids heavy Material Design in favor of custom styling
- **Generous Spacing**: Comfortable padding and margins throughout
- **Clear Hierarchy**: Logical information organization
- **Responsive Layout**: Works on mobile, tablet, and desktop
- **Progressive Disclosure**: Show details when needed

### Color Scheme
```dart
// Light Mode
Primary: #2196F3 (Blue)
Secondary: #FF9800 (Orange)
Surface: #FFFFFF (White)
Background: #F5F5F5 (Light Gray)

// Dark Mode
Primary: #1976D2 (Dark Blue)
Secondary: #F57C00 (Dark Orange)
Surface: #1E1E1E (Dark Gray)
Background: #121212 (Black)
```

### Status Indicators
- 🟢 **Success**: Completed builds
- 🔵 **In Progress**: Currently building
- 🟡 **Queued**: Waiting to start
- 🔴 **Failed**: Build errors
- ⚫ **Cancelled**: User cancelled

## 🔧 Configuration

### Environment Setup

Create environment-specific configuration in `lib/utils/constants.dart`:

```dart
class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://127.0.0.1:8788';
  static const Duration requestTimeout = Duration(seconds: 30);
  
  // Upload Configuration
  static const int maxFileSize = 100 * 1024 * 1024; // 100MB
  static const List<String> allowedExtensions = ['.zip'];
  
  // Build Configuration
  static const String defaultFlutterVersion = 'default';
  static const String defaultTargetFile = 'lib/main.dart';
  static const String defaultBranch = 'main';
  
  // UI Configuration
  static const int jobsPerPage = 20;
  static const Duration refreshInterval = Duration(seconds: 10);
}
```

### Feature Flags

Enable/disable features in `lib/utils/constants.dart`:

```dart
class FeatureFlags {
  static const bool enableDarkMode = true;
  static const bool enableGitSource = true;
  static const bool enableFlutterFlowSource = true;
  static const bool enableRealTimeLogs = true;
  static const bool enableJobCancellation = true;
}
```

## 🚀 Deployment

### Web Deployment

```bash
# Build for production
flutter build web --release

# Deploy to static hosting
# The build output will be in `build/web/`
```

### Desktop Apps

```bash
# Build for current platform
flutter build windows  # Windows
flutter build macos    # macOS
flutter build linux    # Linux
```

### Mobile Apps

```bash
# Build for mobile
flutter build apk      # Android
flutter build ios      # iOS (macOS only)
```

### Docker Deployment

Create a `Dockerfile`:

```dockerfile
FROM nginx:alpine

# Copy built web app
COPY build/web /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

## 🧪 Testing

### Run Tests

```bash
# Unit tests
flutter test

# Widget tests
flutter test test/widget_test.dart

# Integration tests
flutter test integration_test/
```

### Test Structure

```
test/
├── unit/
│   ├── models/         # Model tests
│   ├── services/       # Service tests
│   └── utils/          # Utility tests
├── widget/
│   ├── screens/        # Screen widget tests
│   └── widgets/        # Component widget tests
└── integration/
    └── app_test.dart   # End-to-end tests
```

## 🔍 Debugging

### Development Tools

```bash
# Run with debugging
flutter run --debug

# Enable DevTools
flutter run --debug --observatory-port=9999

# Analyze code
flutter analyze

# Format code
flutter format .
```

### Common Issues

1. **API Connection**: Check server URL in constants
2. **CORS Errors**: Ensure server has CORS headers enabled
3. **File Upload**: Verify file size limits and formats
4. **Build Failures**: Check Flutter/Dart installation

## 📚 Documentation

### API Documentation
- Complete API reference available in `docs/api_prd.md`
- Server implementation details in server's README

### Architecture Documentation
- See `architecture.md` for detailed technical design
- UI/UX principles and component library

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow Flutter style guide
- Add tests for new features
- Update documentation
- Ensure responsive design
- Test on multiple platforms

## 📄 License

This project is provided as-is for development and testing purposes.

## 🌟 Screenshots

### Dashboard
![Dashboard showing job list with filtering options]

### Build Wizard
![4-step build creation wizard with source selection]

### Job Monitoring
![Real-time job monitoring with live logs]

## 🔗 Related Links

- [BuildEngine Server](../../../server/README.md) - Backend API server
- [Flutter Documentation](https://docs.flutter.dev/) - Flutter framework docs
- [Riverpod Guide](https://riverpod.dev/) - State management documentation
- [GoRouter Documentation](https://pub.dev/packages/go_router) - Navigation library

---

Built with ❤️ using Flutter • [Report Issues](../../issues) • [Request Features](../../issues/new)