import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/network/network_status_service.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/routes/auth_routes.dart';
import '../../../../core/routes/home_routes.dart';
import '../../controllers/authentication/auth_session_viewmodel.dart';
import '../../widgets/feedback/indigo_splash_loader.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  Future<void> _navigateAfterSplash(BuildContext context) async {
    final online = await NetworkStatusService.checkConnection(force: true);
    if (!context.mounted) return;

    if (!online) {
      context.go('${AppRouter.noInternetPath}?from=${HomePaths.home}');
      return;
    }

    final authController = injector.get<AuthViewModel>();
    User? firebaseUser;
    try {
      firebaseUser = FirebaseAuth.instance.currentUser;
    } catch (_) {}

    final isLoggedIn =
        authController.session.session.value != null || firebaseUser != null;

    if (!isLoggedIn) {
      context.go(AuthPaths.welcome);
    } else if (firebaseUser != null && !firebaseUser.emailVerified) {
      context.go(AuthPaths.emailVerification);
    } else {
      context.go(HomePaths.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: IndigoSplashLoader(
          onCompleted: () => _navigateAfterSplash(context),
        ),
      ),
    );
  }
}