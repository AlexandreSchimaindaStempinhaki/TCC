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
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _animation = Tween<double>(
      begin: widget.currentIndex.toDouble(),
      end: widget.currentIndex.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap(BuildContext context, int index) async {
    if (index == widget.currentIndex || _isNavigating) return;

    setState(() {
      _isNavigating = true;
      _animation = Tween<double>(
        begin: widget.currentIndex.toDouble(),
        end: index.toDouble(),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    });

    _controller.reset();
    
    await _controller.forward();

    if (!context.mounted) return;

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

    if (mounted) {
      setState(() => _isNavigating = false);
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double itemWidth = constraints.maxWidth / navIcons.length;
                const double pillWidth = 70.0;
                const double pillHeight = 42.0;

                return SizedBox(
                  height: pillHeight,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      final double currentValue = _animation.value;
                      
                      final double pillLeft = (currentValue * itemWidth) + (itemWidth / 2) - (pillWidth / 2);

                      return Stack(
                        children: [
                          Positioned(
                            left: pillLeft,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: pillWidth,
                              decoration: BoxDecoration(
                                color: activeColor.withOpacity(
                                  theme.brightness == Brightness.dark ? 0.25 : 0.12,
                                ),
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                          ),
                          
                          // 2. OS ÍCONES
                          Row(
                            children: List.generate(navIcons.length, (index) {
                              final double distance = (currentValue - index).abs();
                              final double t = (1.0 - distance.clamp(0.0, 1.0));
                              final Color? iconColor = Color.lerp(inactiveColor, activeColor, t);

                              return SizedBox(
                                width: itemWidth,
                                height: pillHeight,
                                child: InkWell(
                                  onTap: () => _onTap(context, index),
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  borderRadius: BorderRadius.circular(22),
                                  child: Center(
                                    child: Icon(
                                      navIcons[index],
                                      color: iconColor,
                                      size: 24, // Ícone num tamanho bom e visível
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}