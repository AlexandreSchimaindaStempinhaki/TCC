import 'package:flutter/material.dart';

class RouteItineraryCard extends StatelessWidget {
  final String origin;
  final String destination;
  final String operatingDays;
  final List<String> shifts;

  const RouteItineraryCard({
    super.key,
    required this.origin,
    required this.destination,
    required this.operatingDays,
    required this.shifts,
  });

  /// Extrai apenas o horário caso a string venha no formato "Manhã (07:00)"
  String _extractTime(String rawShift) {
    final match = RegExp(r'\((.*?)\)').firstMatch(rawShift);
    if (match != null && match.group(1) != null) {
      return match.group(1)!.trim();
    }
    return rawShift.trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final subtleSurface = isDark
        ? colorScheme.onSurface.withOpacity(0.05)
        : theme.scaffoldBackgroundColor.withOpacity(0.7);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =========================================================
          //   LINHA DO TEMPO: ORIGEM -> DESTINO
          // =========================================================
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Coluna de ícones e linha conectora
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.trip_origin_rounded,
                        size: 18,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: CustomPaint(
                          size: const Size(2, double.infinity),
                          painter: _DashedLinePainter(
                            color: colorScheme.secondary.withOpacity(0.35),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 18,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Coluna com os cards de Origem e Destino
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStopBox(
                        label: 'PONTO DE PARTIDA',
                        placeName: origin.isNotEmpty
                            ? origin
                            : 'Origem não informada',
                        accentColor: colorScheme.primary,
                        backgroundColor: subtleSurface,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                      SizedBox(height: 12),
                      _buildStopBox(
                        label: 'DESTINO FINAL',
                        placeName: destination.isNotEmpty
                            ? destination
                            : 'Destino não informado',
                        accentColor: colorScheme.primary,
                        backgroundColor: subtleSurface,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Divider(
              height: 1,
              color: theme.dividerColor.withOpacity(0.5),
            ),
          ),

          // =========================================================
          //   DIAS DE OPERAÇÃO
          // =========================================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: subtleSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dias de Operação',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        operatingDays,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // =========================================================
          //   HORÁRIOS DE SAÍDA
          // =========================================================
          if (shifts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'Horários de Saída',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.secondary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: shifts.map((shift) {
                final cleanTime = _extractTime(shift);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: subtleSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_filled_rounded,
                        size: 15,
                        color: colorScheme.onSurface,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        cleanTime,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStopBox({
    required String label,
    required String placeName,
    required Color accentColor,
    required Color backgroundColor,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: accentColor,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            placeName,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double dashHeight = 4;
    const double dashSpace = 4;
    double startY = 0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(centerX, startY),
        Offset(centerX, (startY + dashHeight).clamp(0.0, size.height)),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}