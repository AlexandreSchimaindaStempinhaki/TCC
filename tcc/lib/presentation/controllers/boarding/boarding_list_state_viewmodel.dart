import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/models/boarding_entity.dart';

class BoardingListState {
  final routeBoardings = signal<List<BoardingModel>>([]);
  final tripBoardings = signal<List<BoardingModel>>([]);
  final selectedDate = signal<DateTime>(DateTime.now());
  final isLoading = signal<bool>(false);
  final message = signal<String?>(null);

  late final confirmedOutboundList = computed(
    () => routeBoardings.value
        .where((b) => b.present && b.willGoOutbound)
        .toList(),
  );

  late final confirmedReturnList = computed(
    () => routeBoardings.value
        .where((b) => b.present && b.willGoReturn)
        .toList(),
  );

  late final readyAtStopList = computed(
    () => routeBoardings.value
        .where((b) => b.present && b.isReadyForBoarding)
        .toList(),
  );

  late final declinedList = computed(
    () => routeBoardings.value
        .where(
          (b) =>
              !b.present ||
              b.attendanceStatus == BoardingAttendanceStatus.declined,
        )
        .toList(),
  );

  void clearMessage() => message.value = null;
}