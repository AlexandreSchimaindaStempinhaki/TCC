import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';

class IndigoSplashLoader extends StatefulWidget {
  final Duration duration;

  /// Se `null` (ex: SplashView), roda uma única vez de 0% a 100%.
  /// Se `true`, avança até ~85% e aguarda sem repetir.
  /// Quando muda para `false`, finaliza suavemente até 100%.
  final bool? isLoading;
  final bool fadeOutOnComplete;
  final VoidCallback? onCompleted;
  final String? message;

  const IndigoSplashLoader({
    super.key,
    this.duration = const Duration(milliseconds: 2700),
    this.isLoading,
    this.fadeOutOnComplete = true,
    this.onCompleted,
    this.message,
  });

  @override
  State<IndigoSplashLoader> createState() => _IndigoSplashLoaderState();
}

class _IndigoSplashLoaderState extends State<IndigoSplashLoader>
    with SingleTickerProviderStateMixin {
  static const double _holdTarget = 0.85;

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
      duration: widget.duration,
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

    // 3. A barra cresce de tamanho continuamente durante todo o loading (14% a 88%)
    _barWidth = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 85.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 22,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 85.0, end: 135.0)
            .chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 33,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 135.0, end: 195.0)
            .chain(CurveTween(curve: Curves.easeOutQuart)),
        weight: 30,
      ),
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

    // 4. A espessura da barra reage aos impulsos (começa fina e encorpa)
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

    // 5. Preenchimento em múltiplos estágios (18% a 90%)
    _progressFill = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.34)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 24,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.34, end: 0.46)
            .chain(CurveTween(curve: Curves.linear)),
        weight: 26,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.46, end: 0.78)
            .chain(CurveTween(curve: Curves.easeOutQuart)),
        weight: 24,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.78, end: 0.85)
            .chain(CurveTween(curve: Curves.linear)),
        weight: 10,
      ),
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

    if (widget.isLoading == null) {
      _controller.forward().whenComplete(() {
        if (mounted) widget.onCompleted?.call();
      });
    } else if (widget.isLoading == true) {
      _startHoldAnimation();
    }
  }

  void _startHoldAnimation() {
    _controller.value = 0.0;
    _controller.animateTo(
      _holdTarget,
      duration: Duration(
        milliseconds: (widget.duration.inMilliseconds * _holdTarget).round(),
      ),
      curve: Curves.linear,
    );
  }

  void _finishAnimation() {
    _controller
        .animateTo(
          1.0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        )
        .whenComplete(() {
      if (mounted) widget.onCompleted?.call();
    });
  }

  @override
  void didUpdateWidget(covariant IndigoSplashLoader oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading == true) {
        _startHoldAnimation();
      } else if (widget.isLoading == false && oldWidget.isLoading == true) {
        _finishAnimation();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final logoAsset = isDark ? AppAssets.logo : AppAssets.logoBlack;
    final trackColor = isDark
        ? Colors.white.withOpacity(0.18)
        : Colors.black.withOpacity(0.12);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final currentBarWidth = _barWidth.value.clamp(0.0, 220.0);
        final currentBarHeight = _barHeight.value.clamp(2.0, 8.0);
        final fillStart = _tailSweep.value.clamp(0.0, 1.0);
        final fillEnd = _progressFill.value.clamp(0.0, 1.0);
        final activeFillFraction = (fillEnd - fillStart).clamp(0.0, 1.0);
        final opacity = widget.fadeOutOnComplete ? _exitOpacity.value : 1.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: opacity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                    if (currentBarWidth > 0)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: SizedBox(
                          width: currentBarWidth,
                          height: currentBarHeight,
                          child: Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: trackColor,
                              ),
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
            ),
            if (widget.message != null && widget.message!.trim().isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                widget.message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}