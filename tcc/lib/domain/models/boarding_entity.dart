import 'package:cloud_firestore/cloud_firestore.dart';

class BoardingModel {
  final int id;
  final int viagemId;
  final String cpfPessoa;
  final DateTime data;
  final DateTime horario;
  final bool presente;

  const BoardingModel({
    required this.id,
    required this.viagemId,
    required this.cpfPessoa,
    required this.data,
    required this.horario,
    this.presente = false,
  });

  BoardingModel copyWith({
    int? id,
    int? viagemId,
    String? cpfPessoa,
    DateTime? data,
    DateTime? horario,
    bool? presente,
  }) {
    return BoardingModel(
      id: id ?? this.id,
      viagemId: viagemId ?? this.viagemId,
      cpfPessoa: cpfPessoa ?? this.cpfPessoa,
      data: data ?? this.data,
      horario: horario ?? this.horario,
      presente: presente ?? this.presente,
    );
  }

  factory BoardingModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return DateTime.now();
    }

    return BoardingModel(
      id: (map['id'] as num?)?.toInt() ?? 0,
      viagemId: (map['viagem_id'] as num?)?.toInt() ?? 0,
      cpfPessoa: map['cpf_pessoa'] as String? ?? '',
      data: parseDate(map['data']),
      horario: parseDate(map['horario']),
      presente: map['presente'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'viagem_id': viagemId,
      'cpf_pessoa': cpfPessoa,
      'data': Timestamp.fromDate(data),
      'horario': Timestamp.fromDate(horario),
      'presente': presente,
    };
  }
}