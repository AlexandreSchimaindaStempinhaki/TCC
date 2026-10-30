import 'package:go_router/go_router.dart';
import '../../presentation/views/welcome_view.dart';
import '../../presentation/views/login_view.dart';
import '../../presentation/views/signup_view.dart';
import '../../presentation/views/password_view.dart';

class AuthRouteNames {
  static const welcome = '/welcome';
  static const login = '/login';
  static const signup = '/signup';
  static const password = '/password';
}

class AuthPaths {
  static const welcome = '/welcome';
  static const login = '/login';
  static const signup = '/signup';
  static const password = '/password';
}

final List<RouteBase> authRoutes = [
  GoRoute(
    path: AuthPaths.welcome,
    name: AuthRouteNames.welcome,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: WelcomePage()),
  ),
  GoRoute(
    path: AuthPaths.login,
    name: AuthRouteNames.login,
    pageBuilder: (context, state) => const NoTransitionPage(child: LoginPage()),
  ),
  GoRoute(
    path: AuthPaths.signup,
    name: AuthRouteNames.signup,
    pageBuilder: (context, state) => NoTransitionPage(child: SignupPage()),
  ),
  GoRoute(
    path: AuthPaths.password,
    name: AuthRouteNames.password,
    pageBuilder: (context, state) => NoTransitionPage(child: ForgotPasswordPage()),
  ),
];
