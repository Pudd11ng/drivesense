import 'package:go_router/go_router.dart';
import 'package:drivesense/ui/user_management/registration/register_view.dart';
import 'package:drivesense/ui/user_management/login/login_view.dart';
import 'package:drivesense/ui/user_management/home/home_view.dart';
import 'package:drivesense/ui/user_management/profile/profile_view.dart';
import 'routes.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: Routes.login, builder: (context, state) => LoginView()),
    GoRoute(path: Routes.register, builder: (context, state) => RegisterView()),
    GoRoute(path: Routes.home, builder: (context, state) => HomeView()),
    GoRoute(path: Routes.profile, builder: (context, state) => ProfileView()),
  ],
);
