import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/error_handler.dart';
import 'core/utils/logger_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure services
  LoggerService.configure(isProduction: false);
  ErrorHandler.instance.setupGlobalErrorHandling();
  
  runApp(const Orbit3DApp());
}

class Orbit3DApp extends StatelessWidget {
  const Orbit3DApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.public,
              size: 100,
              color: AppConstants.primaryColor,
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome to ${AppConstants.appName}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              AppConstants.appDescription,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}