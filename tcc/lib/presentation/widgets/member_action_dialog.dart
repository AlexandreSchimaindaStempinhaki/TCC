import 'package:flutter/material.dart';

class MemberActionDialog extends StatelessWidget {
  final String name;
  final String photoUrl;
  final bool canEditRole;
  final VoidCallback onViewProfile;
  final VoidCallback onEditRole;

  const MemberActionDialog({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.canEditRole,
    required this.onViewProfile,
    required this.onEditRole,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFCBD5E1);
    final Color surfaceColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);

    return Dialog(
      backgroundColor: theme.cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: borderColor, width: 1.6),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: surfaceColor,
              backgroundImage: photoUrl.trim().isNotEmpty
                  ? NetworkImage(photoUrl.trim())
                  : null,
              child: photoUrl.trim().isEmpty
                  ? Icon(
                      Icons.person_rounded,
                      color: colorScheme.onSurface,
                      size: 30,
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Escolha uma ação para este membro',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onViewProfile();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: surfaceColor,
                  foregroundColor: colorScheme.onSurface,
                  elevation: 0,
                  side: BorderSide(color: borderColor, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(
                  Icons.person_search_rounded,
                  size: 20,
                  color: colorScheme.onSurface,
                ),
                label: const Text(
                  'Visualizar Perfil',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (canEditRole) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onEditRole();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons.manage_accounts_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Editar Cargo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}