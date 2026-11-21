import 'package:flutter/material.dart';

enum DayAttendanceStatus {
  none,
  both,
  outboundOnly,
  returnOnly,
  absent,
}

class DayAttendanceDraft {
  final DayAttendanceStatus status;
  final String? departureTime;
  final String? returnTime;

  const DayAttendanceDraft({
    required this.status,
    this.departureTime,
    this.returnTime,
  });

  DayAttendanceDraft copyWith({
    DayAttendanceStatus? status,
    String? departureTime,
    String? returnTime,
    bool clearDeparture = false,
    bool clearReturn = false,
  }) {
    return DayAttendanceDraft(
      status: status ?? this.status,
      departureTime:
          clearDeparture ? null : (departureTime ?? this.departureTime),
      returnTime: clearReturn ? null : (returnTime ?? this.returnTime),
    );
  }
}

class StaffPassengerSlotEntry {
  final String passengerId;
  final String passengerName;
  final String? departureTime;
  final String? returnTime;
  final bool willGoOutbound;
  final bool willGoReturn;
  final bool isReady;

  const StaffPassengerSlotEntry({
    required this.passengerId,
    required this.passengerName,
    required this.departureTime,
    required this.returnTime,
    required this.willGoOutbound,
    required this.willGoReturn,
    required this.isReady,
  });
}

extension DayAttendanceStatusX on DayAttendanceStatus {
  Color color(ColorScheme colorScheme) {
    switch (this) {
      case DayAttendanceStatus.both:
        return const Color(0xFF16A34A);
      case DayAttendanceStatus.outboundOnly:
        return colorScheme.primary;
      case DayAttendanceStatus.returnOnly:
        return const Color(0xFFF59E0B);
      case DayAttendanceStatus.absent:
        return const Color(0xFFDC2626);
      case DayAttendanceStatus.none:
        return Colors.transparent;
    }
  }

  String get label {
    switch (this) {
      case DayAttendanceStatus.both:
        return 'Ida e Volta';
      case DayAttendanceStatus.outboundOnly:
        return 'Somente Ida';
      case DayAttendanceStatus.returnOnly:
        return 'Somente Volta';
      case DayAttendanceStatus.absent:
        return 'Ausente';
      case DayAttendanceStatus.none:
        return 'Não definido';
    }
  }
}

BoxDecoration calendarCardDecoration(ThemeData theme, {bool highlighted = true}) {
  final colorScheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;
  return BoxDecoration(
    color: theme.cardColor,
    borderRadius: BorderRadius.circular(20),
    border: highlighted
        ? Border.all(
            color: isDark
                ? colorScheme.onSurface.withOpacity(0.24)
                : colorScheme.onSurface.withOpacity(0.16),
            width: 1.8,
          )
        : null,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.30 : 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}