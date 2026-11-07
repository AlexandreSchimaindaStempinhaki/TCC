import 'package:flutter/material.dart';

class AnimatedThreeDots extends StatefulWidget {
  final Color color;
  
  const AnimatedThreeDots({
    super.key, 
    required this.color,
  });

  @override
  State<AnimatedThreeDots> createState() => _AnimatedThreeDotsState();
}

class _AnimatedThreeDotsState extends State<AnimatedThreeDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            double value = (_controller.value - delay) % 1.0;
            if (value < 0) value += 1.0;

            final isHighlight = value >= 0.0 && value < 0.4;
            
            // Faz o pontinho subir e descer suavemente
            double y = 0;
            if (isHighlight) {
              y = -4.0 * (0.2 - (0.2 - value).abs()) / 0.2; 
            }

            return Transform.translate(
              offset: Offset(0, y),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isHighlight ? widget.color : widget.color.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}