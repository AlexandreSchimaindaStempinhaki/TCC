import 'dart:io';
import 'package:flutter/material.dart';

class ProfileHeaderCard extends StatelessWidget {
  final String name;
  final String email;
  final String? photoUrl;
  final File? localImage;

  const ProfileHeaderCard({
    super.key,
    required this.name,
    required this.email,
    this.photoUrl,
    this.localImage,
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor, // Mesmo padrão de cor do container de baixo
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: colorScheme.primary.withOpacity(0.1),
            backgroundImage: localImage != null
                ? FileImage(localImage!)
                : (photoUrl != null && photoUrl!.isNotEmpty
                    ? NetworkImage(photoUrl!) as ImageProvider
                    : null),
            child: (localImage == null && (photoUrl == null || photoUrl!.isEmpty))
                ? Text(
                    _getInitials(name),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 24,
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
                // FittedBox faz a fonte diminuir automaticamente se o nome for muito grande
                // O fontSize: 22 atua como o limite MAIOR (Max limit).
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    name.isEmpty ? 'Usuário' : name,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email.isEmpty ? 'Nenhum e-mail cadastrado' : email,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}