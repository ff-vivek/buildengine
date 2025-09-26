import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buildbeacon/theme.dart';
import 'package:buildbeacon/app/router.dart';

void main() {
  runApp(const ProviderScope(child: BuildEngineApp()));
}

class BuildEngineApp extends StatelessWidget {
  const BuildEngineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BuildEngine',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
