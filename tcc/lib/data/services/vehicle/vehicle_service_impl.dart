import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tcc/data/services/firestore_cascade_delete_helper.dart';

import '../../../domain/models/vehicle_entity.dart';
import 'i_vehicle_service.dart';

class VehicleServiceImpl implements IVehicleService {
  final FirebaseFirestore _firestore;

  VehicleServiceImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _collection => _firestore.collection('vehicles');

  String _cleanDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  String _normalizePlate(String plate) =>
      plate.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();

  Map<String, dynamic> _toMap(VehicleModel vehicle) {
    final cleanCnpj = _cleanDigits(vehicle.companyCnpj);
    final normalizedPlate = _normalizePlate(vehicle.plate);

    return {
      'id': vehicle.id,
      'companyCnpj': cleanCnpj,
      'cnpjEmpresa': cleanCnpj,
      'plate': normalizedPlate,
      'placa': normalizedPlate,
      'model': vehicle.model.trim(),
      'modelo': vehicle.model.trim(),
      'brand': vehicle.brand.trim(),
      'marca': vehicle.brand.trim(),
      'capacity': vehicle.capacity,
      'capacidade': vehicle.capacity,
      'color': vehicle.color?.trim(),
      'cor': vehicle.color?.trim(),
      'photoUrl': vehicle.photoUrl?.trim(),
      'fotoVeiculo': vehicle.photoUrl?.trim(),
      'defaultDriverId': vehicle.defaultDriverId?.trim(),
      'isActive': vehicle.isActive,
      'ativo': vehicle.isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  VehicleModel? _fromDoc(DocumentSnapshot doc) {
    if (!doc.exists) return null;
    final rawData = doc.data();
    if (rawData is! Map) return null;

    final map = Map<String, dynamic>.from(rawData);
    return _fromMap(map, doc.id);
  }

  VehicleModel _fromMap(Map<String, dynamic> map, String docId) {
    final rawActive = map['isActive'] ?? map['ativo'];
    final bool isActive = rawActive is bool
        ? rawActive
        : (rawActive?.toString().toLowerCase() != 'false');

    return VehicleModel(
      id: (docId.trim().isNotEmpty ? docId : (map['id'] ?? '')).toString(),
      companyCnpj: (map['companyCnpj'] ?? map['cnpjEmpresa'] ?? '').toString(),
      plate: (map['plate'] ?? map['placa'] ?? '').toString(),
      model: (map['model'] ?? map['modelo'] ?? '').toString(),
      brand: (map['brand'] ?? map['marca'] ?? '').toString(),
      capacity:
          int.tryParse(
            (map['capacity'] ?? map['capacidade'] ?? '15').toString(),
          ) ??
          15,
      color: (map['color'] ?? map['cor'])?.toString(),
      photoUrl: (map['photoUrl'] ?? map['fotoVeiculo'])?.toString(),
      defaultDriverId: map['defaultDriverId']?.toString(),
      isActive: isActive,
    );
  }

  @override
  Future<List<VehicleModel>> fetchVehiclesByCompany(String companyCnpj) async {
    final cleanCnpj = _cleanDigits(companyCnpj);
    if (cleanCnpj.isEmpty) return [];

    final snapshot = await _collection
        .where('companyCnpj', isEqualTo: cleanCnpj)
        .get();

    final vehicles = snapshot.docs
        .map(_fromDoc)
        .whereType<VehicleModel>()
        .toList();

    vehicles.sort(
      (a, b) => a.model.toLowerCase().compareTo(b.model.toLowerCase()),
    );
    return vehicles;
  }

  @override
  Future<VehicleModel?> getVehicleById(String vehicleId) async {
    final trimmedId = vehicleId.trim();
    if (trimmedId.isEmpty) return null;

    final doc = await _collection.doc(trimmedId).get();
    return _fromDoc(doc);
  }

  @override
  Future<List<VehicleModel>> fetchVehiclesByDriver({
    required String companyCnpj,
    required String driverId,
  }) async {
    final cleanCnpj = _cleanDigits(companyCnpj);
    final trimmedDriver = driverId.trim();
    if (cleanCnpj.isEmpty || trimmedDriver.isEmpty) return [];

    final snapshot = await _collection
        .where('companyCnpj', isEqualTo: cleanCnpj)
        .where('defaultDriverId', isEqualTo: trimmedDriver)
        .get();

    return snapshot.docs.map(_fromDoc).whereType<VehicleModel>().toList();
  }

  @override
  Future<VehicleModel> createVehicle(VehicleModel vehicle) async {
    final cleanCnpj = _cleanDigits(vehicle.companyCnpj);
    final normalizedPlate = _normalizePlate(vehicle.plate);

    final docId = vehicle.id.trim().isNotEmpty
        ? vehicle.id.trim()
        : '${cleanCnpj}_$normalizedPlate';

    final existingDoc = await _collection.doc(docId).get();
    if (existingDoc.exists) {
      throw Exception(
        'Já existe um veículo cadastrado com a placa $normalizedPlate nesta empresa.',
      );
    }

    final vehicleToSave = vehicle.copyWith(
      id: docId,
      companyCnpj: cleanCnpj,
      plate: normalizedPlate,
    );

    final data = _toMap(vehicleToSave);
    data['createdAt'] = FieldValue.serverTimestamp();

    await _collection.doc(docId).set(data);
    return vehicleToSave;
  }

  @override
  Future<VehicleModel> updateVehicle(VehicleModel vehicle) async {
    final docId = vehicle.id.trim();
    if (docId.isEmpty) {
      throw Exception('ID do veículo inválido para atualização.');
    }

    final updatedVehicle = vehicle.copyWith(
      companyCnpj: _cleanDigits(vehicle.companyCnpj),
      plate: _normalizePlate(vehicle.plate),
    );

    await _collection
        .doc(docId)
        .set(_toMap(updatedVehicle), SetOptions(merge: true));

    return updatedVehicle;
  }

  @override
  Future<void> toggleVehicleActiveStatus({
    required String vehicleId,
    required bool isActive,
  }) async {
    await _collection.doc(vehicleId.trim()).update({
      'isActive': isActive,
      'ativo': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> assignDefaultDriver({
    required String vehicleId,
    String? driverId,
  }) async {
    await _collection.doc(vehicleId.trim()).update({
      'defaultDriverId': driverId?.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteVehicle(String vehicleId) async {
    final cascade = FirestoreCascadeDeleteHelper(_firestore);
    await cascade.deleteVehicle(vehicleId);
  }
}