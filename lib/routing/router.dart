import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'routes.dart';
import 'package:drivesense/utils/auth_service.dart';
import 'package:drivesense/ui/user_management/registration/register_view.dart';
import 'package:drivesense/ui/user_management/login/login_view.dart';
import 'package:drivesense/ui/user_management/home/home_view.dart';
import 'package:drivesense/ui/user_management/home/settings_view.dart';
import 'package:drivesense/ui/user_management/forgot_password/forgot_password_view.dart';
import 'package:drivesense/ui/user_management/reset_password/reset_password_view.dart';
import 'package:drivesense/ui/alert_notification/manage_alert/manage_alert_view.dart';
import 'package:drivesense/ui/alert_notification/alert/extra_config_view.dart';
import 'package:drivesense/ui/driving_history_analysis/driving_history/driving_history_view.dart';
import 'package:drivesense/ui/driving_history_analysis/analysis/driving_analysis_view.dart';
import 'package:drivesense/ui/monitoring_detection/connect_device/connect_device_view.dart';
import 'package:drivesense/ui/monitoring_detection/device/device_view.dart';
import 'package:drivesense/ui/user_management/profile/profile_completion_view.dart';
import 'package:drivesense/ui/user_management/profile/profile_view.dart';
import 'package:drivesense/ui/user_management/emergency_contact/emergency_contact_view.dart';
import 'package:drivesense/ui/user_management/emergency_contact/invitation_process_view.dart';
import 'package:drivesense/ui/user_management/notification/notification_view.dart';

// Create a custom GoRouter observer
class GoRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('New route pushed: ${route.settings.name}');
  }
}

final rootNavigatorKey = GlobalKey<NavigatorState>();
final AuthService _authService = AuthService();

final GoRouter router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: Routes.home,
  observers: [GoRouterObserver()],

  redirect: (BuildContext context, GoRouterState state) async {
    final isAuth = await _authService.isAuthenticated();

    // Define patterns for public routes (replace parameters with wildcards)
    final publicPatterns = [
      RegExp(r'^/login$'),
      RegExp(r'^/register$'),
      RegExp(r'^/forgot_password$'),
      RegExp(r'^/reset-password$'),
      RegExp(r'^/emergency-invite$'),
    ];

    // Define patterns for public routes (replace parameters with wildcards)
    final homePatterns = [
      RegExp(r'^/login$'),
      RegExp(r'^/register$'),
      RegExp(r'^/$'),
    ];

    final currentPath = state.uri.path;

    final isPublicRoute = publicPatterns.any(
      (pattern) => pattern.hasMatch(currentPath),
    );

    final isHomeRoute = homePatterns.any(
      (pattern) => pattern.hasMatch(currentPath),
    );

    debugPrint('Path: $currentPath, isAuth: $isAuth, isPublic: $isPublicRoute');

    if (!isAuth && !isPublicRoute) {
      return Routes.login;
    } 

    return null;
  },
  routes: [
    GoRoute(path: Routes.login, builder: (context, state) => LoginView()),
    GoRoute(path: Routes.register, builder: (context, state) => RegisterView()),
    GoRoute(path: Routes.home, builder: (context, state) => HomeView()),
    GoRoute(
      path: Routes.forgotPassword,
      builder: (context, state) => const ForgotPasswordView(),
    ),
    GoRoute(
      path: Routes.resetPassword,
      builder: (context, state) {
        final token = state.uri.queryParameters['token'];
        if (token != null) {
          return ResetPasswordView(token: token);
        } else {
          return const Scaffold(
            body: Center(child: Text('Invalid reset password link')),
          );
        }
      },

      // ResetPasswordView(
      //   token: state.pathParameters['token'] ?? '',
      // ),

      //           builder: (context, state) {
      //   final code = state.uri.queryParameters['code'];

      //   if (code != null) {
      //     return InvitationProcessView(inviteCode: code);
      //   }
      //   return const Scaffold(
      //     body: Center(child: Text('Invalid invitation link')),
      //   );
      // },
    ),
    GoRoute(path: Routes.settings, builder: (context, state) => SettingsView()),
    GoRoute(
      path: Routes.connectDevice,
      builder: (context, state) => ConnectDeviceView(),
    ),
    GoRoute(
      path: Routes.device,
      builder:
          (context, state) =>
              DeviceView(deviceId: state.pathParameters['deviceId']),
    ),
    GoRoute(path: Routes.profile, builder: (context, state) => ProfileView()),
    GoRoute(
      path: Routes.profileCompletion,
      builder: (context, state) => ProfileCompletionView(),
    ),
    GoRoute(
      path: Routes.manageAlert,
      builder: (context, state) => ManageAlertView(),
    ),
    GoRoute(
      path: Routes.extraConfig,
      builder:
          (context, state) => ExtraConfigView(
            alertTypeName: state.pathParameters['alertTypeName']!,
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
            drivingHistoryId: state.pathParameters['drivingHistoryId']!,
          ),
    ),
    GoRoute(
      path: Routes.emergencyContact,
      builder: (context, state) => const EmergencyContactView(),
    ),

    GoRoute(
      path: Routes.emergencyContactInvitation,
      builder: (context, state) {
        final code = state.uri.queryParameters['code'];

        if (code != null) {
          return InvitationProcessView(inviteCode: code);
        }
        return const Scaffold(
          body: Center(child: Text('Invalid invitation link')),
        );
      },
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationView(),
    ),
  ],
);
