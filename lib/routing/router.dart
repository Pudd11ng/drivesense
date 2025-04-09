import 'package:drivesense/ui/driving_history_analysis/analysis/driving_analysis_view.dart';
import 'package:drivesense/ui/monitoring_detection/connect_device/connect_device_view.dart';
import 'package:go_router/go_router.dart';
import 'routes.dart';
import 'package:drivesense/ui/user_management/registration/register_view.dart';
import 'package:drivesense/ui/user_management/login/login_view.dart';
import 'package:drivesense/ui/user_management/home/home_view.dart';
import 'package:drivesense/ui/user_management/profile/profile_view.dart';
import 'package:drivesense/ui/alert_notification/manage_alert/manage_alert_view.dart';
import 'package:drivesense/ui/alert_notification/alert/extra_config_view.dart';
import 'package:drivesense/ui/driving_history_analysis/driving_history/driving_history_view.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: Routes.login, builder: (context, state) => LoginView()),
    GoRoute(path: Routes.register, builder: (context, state) => RegisterView()),
    GoRoute(path: Routes.home, builder: (context, state) => HomeView()),
    GoRoute(path: Routes.connectDevice, builder: (context, state) => ConnectDeviceView()),
    GoRoute(path: Routes.profile, builder: (context, state) => ProfileView()),
    GoRoute(
      path: Routes.manageAlert,
      builder: (context, state) => ManageAlertView(),
    ),
    GoRoute(
      path: Routes.extraConfig,
      builder:
          (context, state) => ExtraConfigView(
            alertTypeName: state.uri.queryParameters['alertTypeName']!,
          ),
    ),
    GoRoute(
      path: Routes.drivingHistory,
      builder: (context, state) => DrivingHistoryView(),
    ),
    GoRoute(
      path: Routes.drivingAnalysis,
      builder:
          (context, state) => DrivingAnalysisView(
            drivingHistoryId: state.uri.queryParameters['id']!,
          ),
    ),
  ],
);
