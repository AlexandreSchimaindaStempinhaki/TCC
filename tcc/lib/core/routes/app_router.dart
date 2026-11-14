import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../presentation/views/authentication/splash_view.dart';
import 'auth_routes.dart';
import 'indigo_routes.dart';
import '../di/dependency_injection.dart';
import '../../presentation/controllers/authentication/auth_session_viewmodel.dart';

class RouterNotifier extends ChangeNotifier {
  late final VoidCallback _disposer;

  RouterNotifier() {
    final authController = injector.get<AuthViewModel>();

    _disposer = effect(() {
      authController.session.session.value;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposer();
    super.dispose();
  }
}

class AppRouter {
  AppRouter._();

  static const String splashPath = '/splash';

  static final GoRouter router = GoRouter(
    initialLocation: splashPath,
    refreshListenable: RouterNotifier(),
    redirect: (context, state) {
      // Permite que a tela de carregamento inicial rode até o fim sem redirecionamento precoce
      if (state.matchedLocation == splashPath) {
        return null;
      }

      final authController = injector.get<AuthViewModel>();

      final firebaseUser = FirebaseAuth.instance.currentUser;
      final isLoggedIn =
          authController.session.session.value != null || firebaseUser != null;

      final isPureAuthRoute =
          state.matchedLocation.startsWith('/welcome') ||
          state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/signup') ||
          state.matchedLocation.startsWith('/password') ||
          state.matchedLocation.startsWith('/signup-password');

      final isVerificationRoute = state.matchedLocation.startsWith(
        '/email-verification',
      );

      if (!isLoggedIn && !isPureAuthRoute && !isVerificationRoute) {
        return AuthPaths.login;
      }

      if (isLoggedIn && firebaseUser != null && !firebaseUser.emailVerified) {
        if (!isVerificationRoute) {
          return '/email-verification';
        }
        return null;
      }

      if (isLoggedIn &&
          firebaseUser != null &&
          firebaseUser.emailVerified &&
          (isPureAuthRoute || isVerificationRoute)) {
        return IndigoPaths.home;
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: splashPath,
        name: 'splash',
        builder: (context, state) => const SplashView(),
      ),
      ...authRoutes,
      ...indigoRoutes,
    ],
  );
}