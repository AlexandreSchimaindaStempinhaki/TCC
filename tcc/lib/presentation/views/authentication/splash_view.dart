import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/routes/auth_routes.dart';
import '../../../../core/routes/indigo_routes.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../controllers/authentication/auth_session_viewmodel.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _logoScale;
  late final Animation<double> _spacingWidth;
  late final Animation<double> _barWidth;
  late final Animation<double> _barHeight;
  late final Animation<double> _progressFill;
  late final Animation<double> _tailSweep;
  late final Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2700),
    );

    // 1. Logo surge no centro da tela com efeito elástico (0% a 24%)
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.24, curve: Curves.easeOutBack),
      ),
    );

    // 2. Espaçamento entre a logo e a barra abre suavemente (14% a 35%)
    _spacingWidth = Tween<double>(begin: 0.0, end: 18.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.14, 0.35, curve: Curves.easeOutCubic),
      ),
    );

    // 3. A barra CRESCE de tamanho continuamente durante todo o loading (14% a 88%)
    _barWidth = TweenSequence<double>([
      // Nasce da logo até um tamanho inicial compacto
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 85.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 22,
      ),
      // Continua crescendo enquanto carrega o primeiro estágio
      TweenSequenceItem(
        tween: Tween<double>(begin: 85.0, end: 135.0)
            .chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 33,
      ),
      // Estica ainda mais no segundo impulso de carregamento
      TweenSequenceItem(
        tween: Tween<double>(begin: 135.0, end: 195.0)
            .chain(CurveTween(curve: Curves.easeOutQuart)),
        weight: 30,
      ),
      // Expansão máxima no disparo final
      TweenSequenceItem(
        tween: Tween<double>(begin: 195.0, end: 215.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 15,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.14, 0.88),
      ),
    );

    // 4. A espessura da barra também reage aos impulsos (começa fina e encorpa)
    _barHeight = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 2.0, end: 5.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 5.0, end: 4.5),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 4.5, end: 6.5)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 6.5, end: 5.5),
        weight: 15,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.14, 0.90),
      ),
    );

    // 5. Preenchimento em múltiplos estágios reais estilo YouTube (18% a 90%)
    _progressFill = TweenSequence<double>([
      // Arranque rápido inicial
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.34)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 24,
      ),
      // Pausa dramática (carregando dados pesados)
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.34, end: 0.46)
            .chain(CurveTween(curve: Curves.linear)),
        weight: 26,
      ),
      // Segundo salto rápido
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.46, end: 0.78)
            .chain(CurveTween(curve: Curves.easeOutQuart)),
        weight: 24,
      ),
      // Breve desaceleração antes dos 100%
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.78, end: 0.85)
            .chain(CurveTween(curve: Curves.linear)),
        weight: 10,
      ),
      // Disparo final até 100%
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInExpo)),
        weight: 16,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.90),
      ),
    );

    // 6. Efeito de varredura final na barra ao completar 100% (88% a 97%)
    _tailSweep = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.88, 0.97, curve: Curves.easeInOutCubic),
      ),
    );

    // 7. Fade out de saída (93% a 100%)
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.93, 1.0, curve: Curves.easeOut),
      ),
    );

    _startAppInitialization();
  }

  Future<void> _startAppInitialization() async {
    await _controller.forward();

    if (!mounted) return;

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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = injector.get<ThemeController>();

    return Watch((context) {
      final isDark = themeController.isDarkMode;
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;

      final logoAsset = isDark ? AppAssets.logo : AppAssets.logoBlack;
      final trackColor = isDark
          ? Colors.white.withOpacity(0.18)
          : Colors.black.withOpacity(0.12);

      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final currentBarWidth = _barWidth.value.clamp(0.0, 220.0);
              final currentBarHeight = _barHeight.value.clamp(2.0, 8.0);
              final fillStart = _tailSweep.value.clamp(0.0, 1.0);
              final fillEnd = _progressFill.value.clamp(0.0, 1.0);
              final activeFillFraction = (fillEnd - fillStart).clamp(0.0, 1.0);

              return Opacity(
                opacity: _exitOpacity.value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // LOGO (Começa no centro exato e desliza para a esquerda conforme a barra cresce)
                      Transform.scale(
                        scale: _logoScale.value,
                        child: Image.asset(
                          logoAsset,
                          width: 44,
                          height: 44,
                          fit: BoxFit.contain,
                        ),
                      ),

                      SizedBox(width: _spacingWidth.value),

                      // BARRA QUE CRESCE EM LARGURA E ESPESSURA DURANTE O LOADING
                      if (currentBarWidth > 0)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: SizedBox(
                            width: currentBarWidth,
                            height: currentBarHeight,
                            child: Stack(
                              children: [
                                // Trilho de fundo que cresce junto
                                Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  color: trackColor,
                                ),
                                // Preenchimento com aceleração dinâmica e recolhimento final
                                Positioned(
                                  left: currentBarWidth * fillStart,
                                  top: 0,
                                  bottom: 0,
                                  width: currentBarWidth * activeFillFraction,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }
}