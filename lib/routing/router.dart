import 'package:go_router/go_router.dart';
import '../ui/user_management/registration/register_view.dart';
import '../ui/user_management/login/login_view.dart';
import 'routes.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: Routes.login, builder: (context, state) => LoginScreen()),
    GoRoute(path: Routes.register, builder: (context, state) => RegisterScreen()),
  ],
);
