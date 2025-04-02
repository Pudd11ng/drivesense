import 'package:flutter/material.dart';
import 'routing/router.dart';
import 'package:provider/provider.dart';
import 'package:drivesense/ui/user_management/view_model/user_management_view_model.dart';
import 'package:drivesense/ui/monitoring_detection/view_model/monitoring_view_model.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserManagementViewModel()),
        ChangeNotifierProvider(create: (context) => MonitoringViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: router);
  }
}
