import 'dart:async';
import 'package:flutter/material.dart';
import 'package:drivesense/routing/router.dart';
import 'package:provider/provider.dart';
import 'package:drivesense/ui/core/themes/theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';
import 'package:drivesense/ui/user_management/view_model/user_management_view_model.dart';
import 'package:drivesense/ui/monitoring_detection/view_model/monitoring_view_model.dart';
import 'package:drivesense/ui/alert_notification/view_model/alert_view_model.dart';
import 'package:drivesense/ui/driving_history_analysis/view_model/analysis_view_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:drivesense/utils/fcm_service.dart';
import 'package:drivesense/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await dotenv.load(fileName: ".env");

  final userViewModel = UserManagementViewModel();
  await userViewModel.checkAuthStatus();

  final fcmService = FcmService();

  fcmService.onTokenChanged = (token) async {
    // Use the cached token instead of the getter
    if (userViewModel.isAuthenticated) {
      await userViewModel.updateFcmToken(token);
    }
  };

  await fcmService.init();

  runApp(
    MultiProvider(
      providers: [
        // Add FCM service provider
        Provider<FcmService>.value(value: fcmService),
        ChangeNotifierProvider.value(value: userViewModel),
        ChangeNotifierProvider(create: (context) => MonitoringViewModel()),
        ChangeNotifierProvider(create: (context) => AlertViewModel()),
        ChangeNotifierProvider(create: (context) => AnalysisViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinkHandling();
  }

  Future<void> _initDeepLinkHandling() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('Initial link: $initialUri');
        _handleDeepLink(initialUri);
      }

      _linkSubscription = _appLinks.uriLinkStream.listen(
        (uri) {
          debugPrint('Link received: $uri');
          _handleDeepLink(uri);
        },
        onError: (error) {
          debugPrint('Error with deep link: $error');
        },
      );
    } catch (e) {
      debugPrint('Exception handling deep link: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Processing deep link: $uri');

    if (uri.scheme == 'https') {
      final path = uri.path.isEmpty ? uri.host : uri.path;

      debugPrint('Deep link path: $path');

      if (path == 'drivesense.my/reset-password' ||
          path.contains('reset-password')) {
        if (uri.queryParameters.containsKey('token')) {
          final token = uri.queryParameters['token']!;
          debugPrint('Reset password token: $token');

          // Navigate to reset password screen with a slight delay
          // Future.delayed(const Duration(milliseconds: 500), () {
          //   router.go('/reset_password/$token');
          // });
        }
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
