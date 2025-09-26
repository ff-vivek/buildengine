import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:buildbeacon/presentation/screens/dashboard_screen.dart';
import 'package:buildbeacon/presentation/screens/new_build_screen.dart';
import 'package:buildbeacon/presentation/screens/job_detail_screen.dart';
import 'package:buildbeacon/presentation/screens/settings_screen.dart';

/// Application router configuration
final appRouter = GoRouter(
  initialLocation: '/',
  errorPageBuilder: (context, state) => MaterialPage(
    key: state.pageKey,
    child: ErrorScreen(error: state.error.toString()),
  ),
  routes: [
    // Dashboard / Jobs List
    GoRoute(
      path: '/',
      name: 'dashboard',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const DashboardScreen(),
      ),
    ),

    // New Build Wizard
    GoRoute(
      path: '/new-build',
      name: 'newBuild',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const NewBuildScreen(),
      ),
    ),

    // Job Detail
    GoRoute(
      path: '/jobs/:jobId',
      name: 'jobDetail',
      pageBuilder: (context, state) {
        final jobId = state.pathParameters['jobId']!;
        return MaterialPage(
          key: state.pageKey,
          child: JobDetailScreen(jobId: jobId),
        );
      },
    ),

    // Settings
    GoRoute(
      path: '/settings',
      name: 'settings',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: const SettingsScreen(),
      ),
    ),
  ],
);

/// Error screen for routing errors
class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Page Not Found',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'The page you are looking for does not exist.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extension for easy navigation
extension AppRouterExtension on BuildContext {
  void goToDashboard() => go('/');
  void goToNewBuild() => go('/new-build');
  void goToJobDetail(String jobId) => go('/jobs/$jobId');
  void goToSettings() => go('/settings');
}