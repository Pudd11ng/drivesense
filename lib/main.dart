import 'package:flutter/material.dart';
import 'package:drivesense/routing/router.dart';
import 'package:provider/provider.dart';
import 'package:drivesense/ui/core/themes/theme.dart';
import 'package:drivesense/ui/user_management/view_model/user_management_view_model.dart';
import 'package:drivesense/ui/monitoring_detection/view_model/monitoring_view_model.dart';
import 'package:drivesense/ui/alert_notification/view_model/alert_view_model.dart';
import 'package:drivesense/ui/driving_history_analysis/view_model/analysis_view_model.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserManagementViewModel()),
        ChangeNotifierProvider(create: (context) => MonitoringViewModel()),
        ChangeNotifierProvider(create: (context) => AlertViewModel()),
        ChangeNotifierProvider(create: (context) => AnalysisViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
