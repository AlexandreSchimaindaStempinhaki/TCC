import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/models/boarding_entity.dart';

class BoardingState {
  final selectedDate = signal<DateTime>(DateTime.now());
  final currentBoarding = signal<BoardingModel?>(null);
  final userHistory = signal<List<BoardingModel>>([]);
  final isLoading = signal<bool>(false);
  final message = signal<String?>(null);

  static String formatDateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  late final calendarMap = computed(() {
    final map = <String, BoardingModel>{};
    for (final item in userHistory.value) {
      map[formatDateKey(item.date)] = item;
    }
    final active = currentBoarding.value;
    if (active != null) {
      map[formatDateKey(active.date)] = active;
    }
    return map;
  });

  late final isGoingOutbound = computed(
    () => currentBoarding.value?.willGoOutbound ?? true,
  );

  late final isGoingReturn = computed(
    () => currentBoarding.value?.willGoReturn ?? true,
  );

  late final isReadyForBoarding = computed(
    () => currentBoarding.value?.isReadyForBoarding ?? false,
  );

  BoardingAttendanceStatus resolveStatusForCalendarDate(
    DateTime date, {
    List<int> operatingDays = const [1, 2, 3, 4, 5],
  }) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (!operatingDays.contains(normalized.weekday)) {
      return BoardingAttendanceStatus.declined;
    }

    final key = formatDateKey(normalized);
    final recorded = calendarMap.value[key];
    if (recorded != null) {
      return recorded.attendanceStatus;
    }

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    if (normalized.isBefore(normalizedToday)) {
      return BoardingAttendanceStatus.boarded;
    }
    return BoardingAttendanceStatus.confirmed;
  }

  void upsertInHistory(BoardingModel boarding) {
    final key = formatDateKey(boarding.date);
    final list = userHistory.value;
    final exists = list.any((b) => formatDateKey(b.date) == key);
    if (exists) {
      userHistory.value = list
          .map((b) => formatDateKey(b.date) == key ? boarding : b)
          .toList();
    } else {
      userHistory.value = [boarding, ...list];
    }
  }

  void clearMessage() => message.value = null;
}