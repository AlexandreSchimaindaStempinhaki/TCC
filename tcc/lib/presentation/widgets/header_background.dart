import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tcc/core/constants/app_assets.dart';
import '../../core/extensions/context_extensions.dart';

class HeaderBackground extends StatefulWidget {
  final double? height;

  const HeaderBackground({super.key, this.height});

  @override
  State<HeaderBackground> createState() => _HeaderBackgroundState();
}

class _HeaderBackgroundState extends State<HeaderBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Ciclo contínuo infinito (ida sempre para a frente)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final effectiveHeight = widget.height ?? context.screenHeight * 0.5;

    return SizedBox(
      height: effectiveHeight,
      width: double.infinity,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return ClipPath(
                clipper: SingleFluidWaveClipper(_controller.value),
                child: Container(
                  height: effectiveHeight,
                  width: double.infinity,
                  color: const Color(0xFF1E3A8A),
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.center,
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      AppAssets.logo,
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),

                  Text(
                    'Índigo',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SingleFluidWaveClipper extends CustomClipper<Path> {
  final double animValue;

  SingleFluidWaveClipper(this.animValue);

  @override
  Path getClip(Size size) {
    final path = Path();
    final double phase = animValue * 2 * pi;

    final double baseY = size.height * 0.9;
    final double amplitude = size.height * 0.05;

    path.moveTo(0, 0);

    for (double x = 0; x <= size.width; x += 1.5) {
      final double progress = x / size.width;
      final double angle = (2 * pi * progress) - phase;

      final double wave = sin(angle) + 0.18 * sin(2 * angle - phase);
      final double y = baseY + (wave * amplitude);

      path.lineTo(x, y);
    }

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(SingleFluidWaveClipper oldClipper) {
    return oldClipper.animValue != animValue;
  }
}
