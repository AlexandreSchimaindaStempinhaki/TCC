import 'package:go_router/go_router.dart';
import '../../presentation/views/welcome_view.dart';
import '../../presentation/views/login_view.dart';

class AuthRouteNames {
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
}

class AuthPaths {
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
}

final List<RouteBase> authRoutes = [
  GoRoute(
    path: AuthPaths.welcome,
    name: AuthRouteNames.welcome,
    pageBuilder: (context, state) => const NoTransitionPage(
      child: WelcomePage(),
    ),
  ),
  GoRoute(
    path: AuthPaths.login,
    name: AuthRouteNames.login,
    pageBuilder: (context, state) => const NoTransitionPage(
      child: LoginPage(),
    ),
  ),
];