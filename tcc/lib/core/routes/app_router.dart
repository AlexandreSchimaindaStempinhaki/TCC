import 'package:go_router/go_router.dart';
import 'auth_routes.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AuthPaths.welcome,
    routes: <RouteBase>[
      ...authRoutes,
    ],
  );
}