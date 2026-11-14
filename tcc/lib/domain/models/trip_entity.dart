import 'package:cloud_firestore/cloud_firestore.dart';

class TripModel {
  final int id;
  final int rotaId;
  final int veiculoId;
  final String? cpfMotorista;
  final DateTime data;
  final DateTime horarioSaida;
  final DateTime? horarioChegada;
  final String status; // Ex: 'Agendada', 'Em Andamento', 'Concluída', 'Cancelada'
  final int numeroPassageiros;

  const TripModel({
    required this.id,
    required this.rotaId,
    required this.veiculoId,
    this.cpfMotorista,
    required this.data,
    required this.horarioSaida,
    this.horarioChegada,
    this.status = 'Agendada',
    this.numeroPassageiros = 0,
  });

  TripModel copyWith({
    int? id,
    int? rotaId,
    int? veiculoId,
    String? cpfMotorista,
    DateTime? data,
    DateTime? horarioSaida,
    DateTime? horarioChegada,
    String? status,
    int? numeroPassageiros,
  }) {
    return TripModel(
      id: id ?? this.id,
      rotaId: rotaId ?? this.rotaId,
      veiculoId: veiculoId ?? this.veiculoId,
      cpfMotorista: cpfMotorista ?? this.cpfMotorista,
      data: data ?? this.data,
      horarioSaida: horarioSaida ?? this.horarioSaida,
      horarioChegada: horarioChegada ?? this.horarioChegada,
      status: status ?? this.status,
      numeroPassageiros: numeroPassageiros ?? this.numeroPassageiros,
    );
  }

  factory TripModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return DateTime.now();
    }

    return TripModel(
      id: (map['id'] as num?)?.toInt() ?? 0,
      rotaId: (map['rota_id'] as num?)?.toInt() ?? 0,
      veiculoId: (map['veiculo_id'] as num?)?.toInt() ?? 0,
      cpfMotorista: map['cpf_motorista'] as String?,
      data: parseDate(map['data']),
      horarioSaida: parseDate(map['horarioSaida']),
      horarioChegada: map['horarioChegada'] != null
          ? parseDate(map['horarioChegada'])
          : null,
      status: map['status'] as String? ?? 'Agendada',
      numeroPassageiros: (map['numeroPassageiros'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rota_id': rotaId,
      'veiculo_id': veiculoId,
      'cpf_motorista': cpfMotorista,
      'data': Timestamp.fromDate(data),
      'horarioSaida': Timestamp.fromDate(horarioSaida),
      'horarioChegada':
          horarioChegada != null ? Timestamp.fromDate(horarioChegada!) : null,
      'status': status,
      'numeroPassageiros': numeroPassageiros,
    };
  }
}