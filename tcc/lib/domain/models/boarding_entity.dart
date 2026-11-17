enum BoardingAttendanceStatus {
  confirmed, // Vai embarcar (padrão diário)
  declined, // Avisou que não vai no dia
  readyAtStop, // "Estou pronto para o embarque"
  boarded, // Embarcou de fato (histórico)
  missed, // Faltou (histórico)
}

class BoardingModel {
  final String id;
  final String routeId;
  final String? tripId;
  final String userId;

  // Atributos do Diagrama de Classes
  final DateTime date; // data
  final DateTime timestamp; // horario
  final bool present; // presente

  // Controle de Trecho (Ida/Volta), Horários e Prontidão
  final bool willGoOutbound;
  final bool willGoReturn;
  final String? selectedDepartureTime;
  final String? selectedReturnTime;
  final bool isReadyForBoarding;
  final BoardingAttendanceStatus attendanceStatus;
  final bool isDefaultDaily;

  // Estado de notificações recebidas nesta data/viagem
  final bool wasTripStartNotified;
  final List<int> notifiedEtaThresholds;

  const BoardingModel({
    required this.id,
    required this.routeId,
    this.tripId,
    required this.userId,
    required this.date,
    required this.timestamp,
    this.present = true,
    this.willGoOutbound = true,
    this.willGoReturn = true,
    this.selectedDepartureTime,
    this.selectedReturnTime,
    this.isReadyForBoarding = false,
    this.attendanceStatus = BoardingAttendanceStatus.confirmed,
    this.isDefaultDaily = true,
    this.wasTripStartNotified = false,
    this.notifiedEtaThresholds = const [],
  });

  bool get isGoingToday => present && (willGoOutbound || willGoReturn);

  BoardingModel copyWith({
    String? id,
    String? routeId,
    String? tripId,
    String? userId,
    DateTime? date,
    DateTime? timestamp,
    bool? present,
    bool? willGoOutbound,
    bool? willGoReturn,
    String? selectedDepartureTime,
    String? selectedReturnTime,
    bool? isReadyForBoarding,
    BoardingAttendanceStatus? attendanceStatus,
    bool? isDefaultDaily,
    bool? wasTripStartNotified,
    List<int>? notifiedEtaThresholds,
  }) {
    return BoardingModel(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      tripId: tripId ?? this.tripId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      timestamp: timestamp ?? this.timestamp,
      present: present ?? this.present,
      willGoOutbound: willGoOutbound ?? this.willGoOutbound,
      willGoReturn: willGoReturn ?? this.willGoReturn,
      selectedDepartureTime:
          selectedDepartureTime ?? this.selectedDepartureTime,
      selectedReturnTime: selectedReturnTime ?? this.selectedReturnTime,
      isReadyForBoarding: isReadyForBoarding ?? this.isReadyForBoarding,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      isDefaultDaily: isDefaultDaily ?? this.isDefaultDaily,
      wasTripStartNotified: wasTripStartNotified ?? this.wasTripStartNotified,
      notifiedEtaThresholds:
          notifiedEtaThresholds ?? this.notifiedEtaThresholds,
    );
  }
}