import 'package:flutter/material.dart';

class CompanyMemberCard extends StatelessWidget {
  final String name;
  final String photoUrl;
  final VoidCallback onTap;
  final double maxFontSize;
  final double minFontSize;

  const CompanyMemberCard({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.onTap,
    this.maxFontSize = 15.5,
    this.minFontSize = 11.0,
  });

  double _calculateResponsiveFontSize({
    required BuildContext context,
    required String text,
    required double maxWidth,
    required TextStyle baseStyle,
  }) {
    if (text.trim().isEmpty || maxWidth <= 0) return maxFontSize;

    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);

    for (double size = maxFontSize; size >= minFontSize; size -= 0.5) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: baseStyle.copyWith(fontSize: size),
        ),
        maxLines: 1,
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout(maxWidth: maxWidth);

      if (!painter.didExceedMaxLines) {
        return size;
      }
    }

    return minFontSize;
  }

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

    final baseTextStyle = TextStyle(
      fontSize: maxFontSize,
      fontWeight: FontWeight.w600,
      color: inverseColor,
      letterSpacing: -0.2,
    );

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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final fittedFontSize = _calculateResponsiveFontSize(
                        context: context,
                        text: name,
                        maxWidth: constraints.maxWidth,
                        baseStyle: baseTextStyle,
                      );

                      return Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: baseTextStyle.copyWith(fontSize: fittedFontSize),
                      );
                    },
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
      ],
    );
  }
}