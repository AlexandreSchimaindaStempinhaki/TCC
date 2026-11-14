import 'package:cloud_firestore/cloud_firestore.dart';

class RouteModel {
  final int id;
  final String cnpjEmpresa;
  final GeoPoint pontoPartida;
  final GeoPoint destino;
  final List<DateTime> horarios;

  const RouteModel({
    required this.id,
    required this.cnpjEmpresa,
    required this.pontoPartida,
    required this.destino,
    required this.horarios,
  });

  RouteModel copyWith({
    int? id,
    String? cnpjEmpresa,
    GeoPoint? pontoPartida,
    GeoPoint? destino,
    List<DateTime>? horarios,
  }) {
    return RouteModel(
      id: id ?? this.id,
      cnpjEmpresa: cnpjEmpresa ?? this.cnpjEmpresa,
      pontoPartida: pontoPartida ?? this.pontoPartida,
      destino: destino ?? this.destino,
      horarios: horarios ?? this.horarios,
    );
  }

  factory RouteModel.fromMap(Map<String, dynamic> map) {
    final rawHorarios = map['horarios'] as List<dynamic>? ?? [];
    final parsedHorarios = rawHorarios.map((item) {
      if (item is Timestamp) return item.toDate();
      if (item is DateTime) return item;
      return DateTime.now();
    }).toList();

    return RouteModel(
      id: (map['id'] as num?)?.toInt() ?? 0,
      cnpjEmpresa: map['cnpj_empresa'] as String? ?? '',
      pontoPartida:
          map['pontoPartida'] as GeoPoint? ?? const GeoPoint(-25.5204, -48.5095),
      destino:
          map['destino'] as GeoPoint? ?? const GeoPoint(-25.5855, -48.5630),
      horarios: parsedHorarios.isNotEmpty ? parsedHorarios : [DateTime.now()],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cnpj_empresa': cnpjEmpresa,
      'pontoPartida': pontoPartida,
      'destino': destino,
      'horarios': horarios.map((dt) => Timestamp.fromDate(dt)).toList(),
    };
  }
}