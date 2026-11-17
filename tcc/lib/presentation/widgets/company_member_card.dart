import 'package:flutter/material.dart';

class CompanyMemberCard extends StatelessWidget {
  final String name;
  final String photoUrl;
  final VoidCallback onTap;
  final VoidCallback? onManageRoleTap;
  final bool showDivider;

  const CompanyMemberCard({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.onTap,
    this.onManageRoleTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final inverseColor = colorScheme.onSurface;

    final Color avatarSurface = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);
    final Color dividerColor = isDark
        ? inverseColor.withOpacity(0.12)
        : inverseColor.withOpacity(0.08);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: avatarSurface,
                  backgroundImage: photoUrl.trim().isNotEmpty
                      ? NetworkImage(photoUrl.trim())
                      : null,
                  child: photoUrl.trim().isEmpty
                      ? Icon(
                          Icons.person_rounded,
                          color: inverseColor,
                          size: 22,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: inverseColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.secondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 72,
            endIndent: 16,
            color: dividerColor,
          ),
      ],
    );
  }
}