import 'package:flutter/material.dart';

class AccountOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? iconColor;
  final Color? textColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AccountOption({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
    this.textColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final effectiveIconColor = iconColor ?? colorScheme.onSurfaceVariant;
    final effectiveTextColor = textColor ?? colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56, 
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: effectiveIconColor,
                  size: 28,
                ),
                const SizedBox(width: 12), 
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13, 
                      fontWeight: FontWeight.w500,
                      color: effectiveTextColor,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}