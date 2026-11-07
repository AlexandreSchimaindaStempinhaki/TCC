import 'package:go_router/go_router.dart';
import '../../presentation/views/authentication/welcome_view.dart';
import '../../presentation/views/authentication/login_view.dart';
import '../../presentation/views/authentication/signup_view.dart';
import '../../presentation/views/authentication/password_view.dart';
import '../../presentation/views/authentication/signup_view_password.dart';
import '../../presentation/views/authentication/email_verification_view.dart';

class AuthRouteNames {
  static const welcome = '/welcome';
  static const login = '/login';
  static const signup = '/signup';
  static const password = '/password';
  static const signupPassword = '/signup-password';
  static const emailVerification = '/email-verification';
}

class AuthPaths {
  static const welcome = '/welcome';
  static const login = '/login';
  static const signup = '/signup';
  static const password = '/password';
  static const signupPassword = '/signup-password';
  static const emailVerification = '/email-verification';
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
    pageBuilder: (context, state) =>
        NoTransitionPage(child: ForgotPasswordPage()),
  ),
  GoRoute(
    path: AuthPaths.signupPassword,
    name: AuthRouteNames.signupPassword,
    pageBuilder: (context, state) => NoTransitionPage(
      child: SignupPasswordPage(userData: state.extra as Map<String, dynamic>?),
    ),
  ),
  GoRoute(
    path: AuthPaths.emailVerification,
    name: AuthRouteNames.emailVerification,
    pageBuilder: (context, state) => NoTransitionPage(
      child: EmailVerificationPage(
        userData: state.extra as Map<String, dynamic>?,
      ),
    ),
  ),
];
