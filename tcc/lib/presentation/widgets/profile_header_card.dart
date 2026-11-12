import 'dart:io';
import 'package:flutter/material.dart';

// import 'package:go_router/go_router.dart';

class ProfileHeaderCard extends StatelessWidget {
  final String name;
  final String email;
  final String? photoUrl;
  final File? localImage;
  final VoidCallback? onTap;

  const ProfileHeaderCard({
    super.key,
    required this.name,
    required this.email,
    this.photoUrl,
    this.localImage,
    this.onTap,
  });

  String _getInitials(String name) {
    if (name.isEmpty) return 'US';
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return 'US';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    // Invertendo a lógica: fundo com a cor de superfície principal (mais sólida)
    // e elementos com contraste invertido para destacar bem.
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap:
              onTap ??
              () {
                // context.push('/profile');
              },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar sem borda externa colorida, limpo e direto
                CircleAvatar(
                  radius: 34,
                  backgroundColor: colorScheme.primary,
                  backgroundImage: localImage != null
                      ? FileImage(localImage!)
                      : (photoUrl != null && photoUrl!.isNotEmpty
                            ? NetworkImage(photoUrl!) as ImageProvider
                            : null),
                  child:
                      (localImage == null &&
                          (photoUrl == null || photoUrl!.isEmpty))
                      ? Text(
                          _getInitials(name),
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          name.isEmpty ? 'Usuário' : name,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          email.isEmpty ? 'Nenhum e-mail cadastrado' : email,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Botão à direita invertido (fundo sólido com ícone contrastante)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: colorScheme.onPrimary,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
