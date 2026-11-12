import 'package:flutter/material.dart';

class ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool canEdit;
  final bool isRequired;
  final bool reserveTrailingSpace;
  final int? maxLines;
  final VoidCallback? onTap;

  const ProfileInfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.canEdit = false,
    this.isRequired = false,
    this.reserveTrailingSpace = false,
    this.maxLines,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isEmpty = value.trim().isEmpty;
    final displayValue = isEmpty ? 'Não informado' : value;
    final showMissingAlert = isEmpty && isRequired && canEdit;
    final isInteractive = canEdit && onTap != null;

    return InkWell(
      onTap: isInteractive ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            Icon(
              icon,
              color: colorScheme.onSurfaceVariant,
              size: 26,
            ),
            const SizedBox(width: 14),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayValue,
                textAlign: TextAlign.end,
                softWrap: true,
                maxLines: maxLines,
                overflow: maxLines != null
                    ? TextOverflow.ellipsis
                    : TextOverflow.visible,
                style: TextStyle(
                  color: showMissingAlert
                      ? Colors.redAccent
                      : (isEmpty
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.primary),
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isInteractive) ...[
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                size: 16,
              ),
            ] else if (reserveTrailingSpace) ...[
              const SizedBox(width: 26),
            ],
          ],
        ),
      ),
    );
  }
}