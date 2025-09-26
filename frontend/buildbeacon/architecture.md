# BuildEngine - Architecture & Implementation Plan

## Overview
BuildEngine is a production-ready Flutter frontend for creating, monitoring, and downloading Flutter web builds. Users can upload projects, configure build settings, and track build progress with real-time status updates and logs.

## Information Architecture

### Core Screens
1. **Dashboard/Jobs List** - Main screen with job history and filters
2. **New Build Stepper** - 4-step wizard for creating builds
3. **Job Detail** - Real-time build monitoring with logs
4. **Settings** (optional) - API configuration

### User Flow
1. User lands on Dashboard → sees job history
2. User clicks "New Build" → enters 4-step wizard
3. User submits build → redirected to Job Detail
4. User monitors progress → downloads artifact on success

## Technical Stack

### Dependencies
- `riverpod` - State management
- `go_router` - Navigation
- `dio` - HTTP client
- `file_picker` - File upload
- `freezed` - Data classes
- `json_annotation` - JSON serialization
- `web_socket_channel` - Real-time logs

### Architecture Layers
- **Data Layer** - API clients, models, repositories
- **Domain Layer** - Entities, use cases, repositories
- **Presentation Layer** - Screens, widgets, providers

### State Management
- Riverpod providers for API state
- Local state for form management
- Async providers for build jobs and logs

## Data Models

### Source Types
- Upload ZIP file
- FlutterFlow import (URL + token)
- Git repository (optional)

### Build Lifecycle
`created` → `queued` → `downloading_source` → `pre_steps` → `building` → `post_steps` → `packaging` → `success`/`failed`

### Security
- Mask tokens in UI and logs
- Validate command inputs (flutter/dart only)
- HTTPS-only endpoints
- Secure token storage

## Implementation Plan

### Phase 1: Core Infrastructure
1. Setup dependencies and project structure
2. Create data models and API client
3. Implement routing and theme updates

### Phase 2: Main Screens
1. Dashboard with job list and filters
2. Job detail screen with real-time updates
3. Status tracking and progress indicators

### Phase 3: Build Creation
1. New build stepper wizard
2. File upload handling
3. Form validation and submission

### Phase 4: Polish & Testing
1. Error handling and edge cases
2. Accessibility improvements
3. Unit and widget tests
4. Performance optimizations

## File Structure
```
lib/
├── main.dart
├── theme.dart (updated)
├── app/
│   ├── router.dart
│   └── providers.dart
├── data/
│   ├── models/
│   ├── repositories/
│   └── api/
├── domain/
│   ├── entities/
│   └── repositories/
├── presentation/
│   ├── screens/
│   ├── widgets/
│   └── providers/
└── utils/
    ├── validators.dart
    └── constants.dart
```

## API Integration
- RESTful API with JWT/Bearer authentication
- Real-time logs via WebSocket/SSE
- Multipart file uploads
- Signed URLs for artifact downloads

## UI/UX Principles
- Modern, clean design avoiding Material Design
- Generous spacing and elegant typography
- Responsive layout for mobile/tablet/desktop
- Progressive disclosure and clear information hierarchy
- Optimistic UI patterns for better perceived performance