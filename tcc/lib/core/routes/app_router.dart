import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'auth_routes.dart';
import 'indigo_routes.dart';
import '../di/dependency_injection.dart';
import '../../presentation/controllers/authentication/auth_session_viewmodel.dart';
import 'package:signals_flutter/signals_flutter.dart';

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

  static final GoRouter router = GoRouter(
    initialLocation: AuthPaths.welcome,
    
    refreshListenable: RouterNotifier(),

    redirect: (context, state) {
      final authController = injector.get<AuthViewModel>();
      
      final isLoggedIn = authController.session.session.value != null;

      final isAuthRoute = state.matchedLocation.startsWith('/welcome') ||
                          state.matchedLocation.startsWith('/login') ||
                          state.matchedLocation.startsWith('/signup') ||
                          state.matchedLocation.startsWith('/password');

      if (!isLoggedIn && !isAuthRoute) {
        return AuthPaths.login;
      }

      if (isLoggedIn && isAuthRoute) {
        return IndigoPaths.home;
      }

      return null;
    },

    routes: <RouteBase>[
      ...authRoutes,
      ...indigoRoutes,
    ],
  );
}