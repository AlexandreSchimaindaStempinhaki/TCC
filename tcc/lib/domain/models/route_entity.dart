import 'package:cloud_firestore/cloud_firestore.dart';
import 'company_entity.dart';

class RouteModel {
  final int id;
  final String companyCnpj;
  final GeoPoint origin;
  final GeoPoint destination;
  final List<DateTime> schedules;
  final String? imageUrl;

  // Hydrated company data for direct display in CompanyRouteCard
  final CompanyModel? company;

  const RouteModel({
    required this.id,
    required this.companyCnpj,
    required this.origin,
    required this.destination,
    required this.schedules,
    this.imageUrl,
    this.company,
  });

  RouteModel copyWith({
    int? id,
    String? companyCnpj,
    GeoPoint? origin,
    GeoPoint? destination,
    List<DateTime>? schedules,
    String? imageUrl,
    CompanyModel? company,
  }) {
    return RouteModel(
      id: id ?? this.id,
      companyCnpj: companyCnpj ?? this.companyCnpj,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      schedules: schedules ?? this.schedules,
      imageUrl: imageUrl ?? this.imageUrl,
      company: company ?? this.company,
    );
  }

  factory RouteModel.fromMap(
    Map<String, dynamic> map, {
    CompanyModel? company,
  }) {
    final rawSchedules =
        (map['schedules'] ?? map['horarios']) as List<dynamic>? ?? [];
    final parsedSchedules = rawSchedules.map((item) {
      if (item is Timestamp) return item.toDate();
      if (item is DateTime) return item;
      if (item is String) return DateTime.tryParse(item) ?? DateTime.now();
      return DateTime.now();
    }).toList();

    final rawOrigin = map['origin'] ?? map['pontoPartida'];
    final rawDestination = map['destination'] ?? map['destino'];

    return RouteModel(
      id: (map['id'] as num?)?.toInt() ?? 0,
      companyCnpj:
          (map['companyCnpj'] ?? map['cnpj_empresa'] ?? '') as String,
      origin: rawOrigin is GeoPoint
          ? rawOrigin
          : const GeoPoint(-25.5204, -48.5095),
      destination: rawDestination is GeoPoint
          ? rawDestination
          : const GeoPoint(-25.5855, -48.5630),
      schedules: parsedSchedules.isNotEmpty ? parsedSchedules : [DateTime.now()],
      imageUrl:
          (map['imageUrl'] ?? map['fotoRota'] ?? map['image']) as String?,
      company: company,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyCnpj': companyCnpj,
      'origin': origin,
      'destination': destination,
      'schedules': schedules.map((dt) => Timestamp.fromDate(dt)).toList(),
      'imageUrl': imageUrl,
    };
  }
}