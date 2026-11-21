import 'dart:math' as math;

import '../../../domain/models/route_entity.dart';

class ScheduleSlot {
  final int index;
  final String time; // 'HH:mm'
  final int minutesFromMidnight;
  final bool isOutbound;
  final bool isApproximate;

  const ScheduleSlot({
    required this.index,
    required this.time,
    required this.minutesFromMidnight,
    required this.isOutbound,
    this.isApproximate = false,
  });

  String get shortLabel =>
      isOutbound ? '${index}ª ida • $time' : '${index}ª volta • $time';

  String get displayTime => time;
}

class ResolvedRouteSchedules {
  final int estimatedOneWayMinutes;
  final List<ScheduleSlot> outboundSlots;
  final List<ScheduleSlot> returnSlots;
  final Set<int> operatingWeekdays; // 1 = Seg ... 7 = Dom (DateTime.weekday)

  const ResolvedRouteSchedules({
    required this.estimatedOneWayMinutes,
    required this.outboundSlots,
    required this.returnSlots,
    required this.operatingWeekdays,
  });

  bool isOperatingDay(DateTime date) =>
      operatingWeekdays.contains(date.weekday);

  /// Se a data informada não tiver operação, avança até o próximo dia válido da rota.
  DateTime nextOperatingDate(DateTime from) {
    final base = DateTime(from.year, from.month, from.day);
    if (operatingWeekdays.isEmpty || isOperatingDay(base)) return base;

    for (int offset = 1; offset <= 7; offset++) {
      final candidate = base.add(Duration(days: offset));
      if (isOperatingDay(candidate)) return candidate;
    }
    return base;
  }

  /// Retorna todos os horários de volta compatíveis com o horário de ida escolhido.
  List<ScheduleSlot> validReturnsForOutbound(String? outboundTime) {
    if (outboundTime == null || outboundSlots.isEmpty) return returnSlots;
    final outMin = RouteScheduleResolver.parseMinutes(outboundTime);
    if (outMin == null) return returnSlots;

    final minArrivalPlusStay = outMin + estimatedOneWayMinutes + 30;
    final valid = returnSlots
        .where((slot) => slot.minutesFromMidnight >= minArrivalPlusStay)
        .toList();

    return valid.isNotEmpty ? valid : [returnSlots.last];
  }

  /// Volta padrão correspondente ao mesmo turno da ida selecionada.
  String? defaultReturnForOutbound(String? outboundTime) {
    if (returnSlots.isEmpty) return null;
    if (outboundTime == null) return returnSlots.first.time;

    final outIdx = outboundSlots.indexWhere((s) => s.time == outboundTime);
    if (outIdx >= 0 && outIdx < returnSlots.length) {
      return returnSlots[outIdx].time;
    }

    final valid = validReturnsForOutbound(outboundTime);
    return valid.isNotEmpty ? valid.first.time : returnSlots.last.time;
  }
}

class RouteScheduleResolver {
  RouteScheduleResolver._();

  static ResolvedRouteSchedules resolve(RouteModel route) {
    final oneWayMinutes = _estimateOneWayMinutes(route);
    final outboundMinutes = _extractSortedOutboundMinutes(route);
    final operatingWeekdays = parseOperatingWeekdays(route.operatingDaysLabel);

    final outboundSlots = <ScheduleSlot>[];
    for (int i = 0; i < outboundMinutes.length; i++) {
      outboundSlots.add(
        ScheduleSlot(
          index: i + 1,
          time: formatMinutes(outboundMinutes[i]),
          minutesFromMidnight: outboundMinutes[i],
          isOutbound: true,
        ),
      );
    }

    final returnMinutes = _approximateReturnMinutes(
      outboundMinutes: outboundMinutes,
      oneWayMinutes: oneWayMinutes,
    );

    final returnSlots = <ScheduleSlot>[];
    for (int i = 0; i < returnMinutes.length; i++) {
      returnSlots.add(
        ScheduleSlot(
          index: i + 1,
          time: formatMinutes(returnMinutes[i]),
          minutesFromMidnight: returnMinutes[i],
          isOutbound: false,
          isApproximate: true,
        ),
      );
    }

    return ResolvedRouteSchedules(
      estimatedOneWayMinutes: oneWayMinutes,
      outboundSlots: outboundSlots,
      returnSlots: returnSlots,
      operatingWeekdays: operatingWeekdays,
    );
  }

  /// Converte `operatingDaysLabel` (ex.: "Segunda a Sexta", "Seg, Qua e Sex", "Todos os dias")
  /// em um conjunto de `DateTime.weekday` (1..7).
  static Set<int> parseOperatingWeekdays(String rawLabel) {
    final normalized = _normalizePortuguese(
      rawLabel,
    ).replaceAll('-feira', '').replaceAll(' feira', '').trim();

    if (normalized.isEmpty) {
      return const {1, 2, 3, 4, 5};
    }

    if (normalized.contains('todos os dias') ||
        normalized.contains('diario') ||
        normalized.contains('diariamente')) {
      return const {1, 2, 3, 4, 5, 6, 7};
    }

    final days = <int>{};

    if (normalized.contains('dias uteis')) {
      days.addAll(const [1, 2, 3, 4, 5]);
    }
    if (normalized.contains('fim de semana') ||
        normalized.contains('finais de semana')) {
      days.addAll(const [6, 7]);
    }

    const tokenPattern =
        r'(segunda|seg|terca|ter|quarta|qua|quinta|qui|sexta|sex|sabado|sab|domingo|dom)';

    // 1. Intervalos: "segunda a sexta", "seg a sab", "ter - qui"
    final rangeRegex = RegExp(
      r'\b' + tokenPattern + r'\b\s*(?:a|ate|-|–)\s*\b' + tokenPattern + r'\b',
    );
    for (final match in rangeRegex.allMatches(normalized)) {
      final start = _weekdayFromToken(match.group(1)!);
      final end = _weekdayFromToken(match.group(2)!);
      if (start != null && end != null) {
        int cur = start;
        for (int step = 0; step < 7; step++) {
          days.add(cur);
          if (cur == end) break;
          cur = (cur % 7) + 1;
        }
      }
    }

    // 2. Dias individuais: "seg, qua e sex"
    final singleRegex = RegExp(r'\b' + tokenPattern + r'\b');
    for (final match in singleRegex.allMatches(normalized)) {
      final day = _weekdayFromToken(match.group(1)!);
      if (day != null) days.add(day);
    }

    return days.isNotEmpty ? days : const {1, 2, 3, 4, 5};
  }

  static String _normalizePortuguese(String input) {
    return input
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }

  static int? _weekdayFromToken(String token) {
    switch (token) {
      case 'seg':
      case 'segunda':
        return DateTime.monday;
      case 'ter':
      case 'terca':
        return DateTime.tuesday;
      case 'qua':
      case 'quarta':
        return DateTime.wednesday;
      case 'qui':
      case 'quinta':
        return DateTime.thursday;
      case 'sex':
      case 'sexta':
        return DateTime.friday;
      case 'sab':
      case 'sabado':
        return DateTime.saturday;
      case 'dom':
      case 'domingo':
        return DateTime.sunday;
      default:
        return null;
    }
  }

  static List<int> _extractSortedOutboundMinutes(RouteModel route) {
    if (route.schedules.isEmpty) {
      return const [5 * 60 + 30, 11 * 60];
    }

    final unique = <int>{};
    for (final dt in route.schedules) {
      unique.add(dt.hour * 60 + dt.minute);
    }
    final sorted = unique.toList()..sort();
    return sorted;
  }

  static List<int> _approximateReturnMinutes({
    required List<int> outboundMinutes,
    required int oneWayMinutes,
  }) {
    final results = <int>[];
    const maxDayMinute = 23 * 60 + 30;

    for (int i = 0; i < outboundMinutes.length; i++) {
      final dep = outboundMinutes[i];
      int estimatedReturn;

      if (i + 1 < outboundMinutes.length) {
        final nextDep = outboundMinutes[i + 1];
        final afterNextArrival = nextDep + oneWayMinutes + 15;
        final int minStayReturn =
            dep + math.max<int>(240, oneWayMinutes * 2 + 90);
        estimatedReturn = math.max<int>(afterNextArrival, minStayReturn);
      } else if (results.isNotEmpty) {
        final prevCycle = results.last - outboundMinutes[i - 1];
        if (dep >= 17 * 60) {
          estimatedReturn = dep + 270;
        } else {
          final int cycle = (prevCycle - 15).clamp(300, 450).toInt();
          estimatedReturn = dep + cycle;
        }
      } else {
        if (dep >= 17 * 60) {
          estimatedReturn = dep + 270;
        } else {
          estimatedReturn = dep + math.max<int>(330, oneWayMinutes + 270);
        }
      }

      final int rounded = _roundToNearest5(
        estimatedReturn,
      ).clamp(dep + 60, maxDayMinute).toInt();
      if (!results.contains(rounded)) {
        results.add(rounded);
      }
    }

    results.sort();
    return results;
  }

  static int _estimateOneWayMinutes(RouteModel route) {
    final lat1 = route.origin.latitude;
    final lon1 = route.origin.longitude;
    final lat2 = route.destination.latitude;
    final lon2 = route.destination.longitude;

    if (lat1.abs() < 0.01 && lon1.abs() < 0.01) return 120;

    final straightKm = _haversineKm(lat1, lon1, lat2, lon2);
    if (straightKm < 1.0) return 90;

    final roadKm = straightKm * 1.28;
    final minutes = ((roadKm / 52.0) * 60.0 + 25.0).round();
    return minutes.clamp(45, 150).toInt();
  }

  static double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = (lat2 - lat1) * (math.pi / 180.0);
    final dLon = (lon2 - lon1) * (math.pi / 180.0);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180.0)) *
            math.cos(lat2 * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static int _roundToNearest5(int minutes) => ((minutes + 2) ~/ 5) * 5;

  static String formatMinutes(int totalMinutes) {
    final int safe = totalMinutes.clamp(0, 23 * 60 + 59).toInt();
    final h = (safe ~/ 60).toString().padLeft(2, '0');
    final m = (safe % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  static int? parseMinutes(String? hhmm) {
    if (hhmm == null) return null;
    final clean = hhmm.replaceAll('~', '').trim();
    final parts = clean.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  static bool hasSlotPassedForDate(String hhmm, DateTime selectedDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    if (target.isBefore(today)) return true;
    if (target.isAfter(today)) return false;

    final slotMin = parseMinutes(hhmm);
    if (slotMin == null) return false;
    final nowMin = now.hour * 60 + now.minute;
    return nowMin >= slotMin;
  }
}
