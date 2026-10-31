import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/indigo_routes.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

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
    final List navItems = [
      {'icon': Icons.explore_rounded, 'label': 'Explorar'},
      {'icon': Icons.bookmark_rounded, 'label': 'Salvas'},
      {'icon': Icons.alt_route_rounded, 'label': 'Minhas Rotas'},
      {'icon': Icons.person_rounded, 'label': 'Conta'},
    ];

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 36, right: 36, bottom: 36),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(navItems.length, (index) {
                final isSelected = currentIndex == index;
                final item = navItems[index];

                return InkWell(
                  onTap: () => _onTap(context, index),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pílula compacta do ícone
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1E3A8A)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF64748B),
                          size: 18, // Ícone reduzido
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Rótulo da aba
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 10, // Texto reduzido
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF1E3A8A)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
