import 'dart:math';
import 'package:flutter/material.dart';

class CleanHeaderBackground extends StatefulWidget {
  final double? height;
  final Widget? child;

  const CleanHeaderBackground({super.key, this.height, this.child});

  @override
  State<CleanHeaderBackground> createState() => _CleanHeaderBackgroundState();
}

class _CleanHeaderBackgroundState extends State<CleanHeaderBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8), // Mesma duração suave[cite: 4]
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Usa a altura fornecida ou 30% da tela como padrão
    final effectiveHeight = widget.height ?? MediaQuery.of(context).size.height * 0.3;

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
                  color: colorScheme.primary,
                ),
              );
            },
          ),
          if (widget.child != null) 
            widget.child!,
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