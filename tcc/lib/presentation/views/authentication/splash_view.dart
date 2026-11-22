import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/routes/auth_routes.dart';
import '../../../../core/routes/indigo_routes.dart';
import '../../controllers/authentication/auth_session_viewmodel.dart';
import '../../widgets/indigo_splash_loader.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  void _navigateAfterSplash(BuildContext context) {
    if (!context.mounted) return;

    final authController = injector.get<AuthViewModel>();
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final isLoggedIn =
        authController.session.session.value != null || firebaseUser != null;

    if (!isLoggedIn) {
      context.go(AuthPaths.welcome);
    } else if (firebaseUser != null && !firebaseUser.emailVerified) {
      context.go('/email-verification');
    } else {
      context.go(IndigoPaths.home);
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