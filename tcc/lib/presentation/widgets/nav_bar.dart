import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/indigo_routes.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _previousIndex;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex.toDouble();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = Tween<double>(
      begin: widget.currentIndex.toDouble(),
      end: widget.currentIndex.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant BottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex.toDouble();
      
      _animation = Tween<double>(
        begin: _previousIndex,
        end: widget.currentIndex.toDouble(),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap(BuildContext context, int index) {
    if (index == widget.currentIndex) return;

    switch (index) {
      case 0:
        context.goNamed(IndigoRouteNames.home);
        break;
      case 1:
        context.goNamed(IndigoRouteNames.saved);
        break;
      case 2:
        context.goNamed(IndigoRouteNames.myRoutes);
        break;
      case 3:
        context.goNamed(IndigoRouteNames.account);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final cardBgColor = theme.cardColor;
    final borderColor = theme.dividerColor;
    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.secondary;

    final List<IconData> navIcons = [
      Icons.explore_rounded,
      Icons.bookmark_rounded,
      Icons.alt_route_rounded,
      Icons.settings_rounded,
    ];

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 36, right: 36, bottom: 36),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    theme.brightness == Brightness.dark ? 0.3 : 0.05,
                  ),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final double currentValue = _animation.value;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(navIcons.length, (index) {
                    final double distance = (currentValue - index).abs();
                    final double t = (1.0 - distance.clamp(0.0, 1.0));

                    final iconColor = Color.lerp(inactiveColor, activeColor, t);
                    final pillColor = activeColor.withOpacity((0.25) * t,
                    );

                    return InkWell(
                      onTap: () => _onTap(context, index),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 70,
                        height: 42,
                        decoration: BoxDecoration(
                          color: pillColor,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Center(
                          child: Icon(
                            navIcons[index],
                            color: iconColor,
                            size: 24, // Ícone maior sem alterar o tamanho geral da navbar
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}