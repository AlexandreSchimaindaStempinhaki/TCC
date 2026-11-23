import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/network/network_status_service.dart';
import '../../../../core/routes/home_routes.dart';

class NoInternetView extends StatefulWidget {
  final String? returnTo;

  const NoInternetView({super.key, this.returnTo});

  @override
  State<NoInternetView> createState() => _NoInternetViewState();
}

class _NoInternetViewState extends State<NoInternetView> {
  bool _isChecking = false;

  Future<void> _retryConnection() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    final online = await NetworkStatusService.checkConnection(force: true);

    if (!mounted) return;
    setState(() => _isChecking = false);

    if (online) {
      final destination =
          (widget.returnTo != null &&
              widget.returnTo!.isNotEmpty &&
              widget.returnTo != '/no-internet')
          ? widget.returnTo!
          : HomePaths.home;
      context.go(destination);
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Você continua off-line. Verifique sua conexão e tente novamente.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Color(0xFFDC2626),
            behavior: SnackBarBehavior.fixed,
            duration: Duration(seconds: 3),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    AppAssets.noInternet,
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Conecte-se à Internet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Você está off-line. Verifique sua conexão.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15.5,
                      height: 1.4,
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _isChecking ? null : _retryConnection,
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: _isChecking
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: colorScheme.primary,
                            ),
                          )
                        : Text(
                            'TENTAR NOVAMENTE',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: colorScheme.primary,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}