import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../presentation/controllers/authentication/auth_session_viewmodel.dart';
import '../../presentation/views/application/common/no_internet_view.dart';
import '../../presentation/views/application/home/home_view.dart';
import '../../presentation/views/authentication/splash_view.dart';
import '../di/dependency_injection.dart';
import '../network/network_status_service.dart';
import 'account_routes.dart';
import 'auth_routes.dart';
import 'company_routes.dart';
import 'home_routes.dart';
import 'route_operation_routes.dart';

class RouterNotifier extends ChangeNotifier {
  late final VoidCallback _disposer;

  RouterNotifier() {
    final authController = injector.get<AuthViewModel>();

    _disposer = effect(() {
      authController.session.session.value;
      NetworkStatusService.isConnected.value;
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
  static const String noInternetPath = '/no-internet';

  static final GoRouter router = GoRouter(
    initialLocation: splashPath,
    refreshListenable: RouterNotifier(),
    redirect: (context, state) {
      // Dispara verificação em segundo plano para manter o signal atualizado
      NetworkStatusService.checkInBackground();

      final online = NetworkStatusService.isConnected.value;
      final isNoInternetRoute = state.matchedLocation == noInternetPath;

      // 1. Sem internet: manda direto para a tela de sem conexão (sem passar por loading)
      if (!online) {
        if (isNoInternetRoute) return null;
        final from = Uri.encodeQueryComponent(state.uri.toString());
        return '$noInternetPath?from=$from';
      }

      // 2. Voltou a ter internet enquanto estava na tela de sem conexão
      if (online && isNoInternetRoute) {
        final from = state.uri.queryParameters['from'];
        if (from != null &&
            from.isNotEmpty &&
            !from.startsWith(noInternetPath)) {
          return from;
        }
        return HomePaths.home;
      }

      if (state.matchedLocation == splashPath) {
        return null;
      }

      final authController = injector.get<AuthViewModel>();
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final isLoggedIn =
          authController.session.session.value != null || firebaseUser != null;

      final isPureAuthRoute =
          state.matchedLocation.startsWith(AuthPaths.welcome) ||
          state.matchedLocation.startsWith(AuthPaths.login) ||
          state.matchedLocation.startsWith(AuthPaths.signup) ||
          state.matchedLocation.startsWith(AuthPaths.password) ||
          state.matchedLocation.startsWith(AuthPaths.signupPassword);

      final isVerificationRoute = state.matchedLocation.startsWith(
        AuthPaths.emailVerification,
      );

      if (!isLoggedIn && !isPureAuthRoute && !isVerificationRoute) {
        return AuthPaths.login;
      }

      if (isLoggedIn && firebaseUser != null && !firebaseUser.emailVerified) {
        if (!isVerificationRoute) {
          return AuthPaths.emailVerification;
        }
        return null;
      }

      if (isLoggedIn &&
          firebaseUser != null &&
          firebaseUser.emailVerified &&
          (isPureAuthRoute || isVerificationRoute)) {
        return HomePaths.home;
      }

      return null;
    },
    errorBuilder: (context, state) => const HomeView(),
    routes: <RouteBase>[
      GoRoute(
        path: splashPath,
        name: 'splash',
        builder: (context, state) => const SplashView(),
      ),
      GoRoute(
        path: noInternetPath,
        name: 'no_internet',
        pageBuilder: (context, state) => NoTransitionPage(
          child: NoInternetView(
            returnTo: state.uri.queryParameters['from'],
          ),
        ),
      ),
      ...authRoutes,
      ...homeRoutes,
      ...accountRoutes,
      ...companyRoutes,
      ...routeOperationRoutes,
    ],
  );
}