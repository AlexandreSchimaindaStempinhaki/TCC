import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../../../domain/models/company_entity.dart';
import '../../../domain/models/route_entity.dart';
import 'i_route_service.dart';

class RouteRemoteServiceImpl implements IRouteRemoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _cloudName = 'db37erprw';
  static const String _uploadPreset = 'tcc_pics';

  RouteRemoteServiceImpl();

  CollectionReference get _routesCollection => _firestore.collection('routes');

  CollectionReference get _companiesCollection =>
      _firestore.collection('companies');

  Map<String, dynamic>? _asMap(Object? rawData) {
    if (rawData == null) return null;
    if (rawData is Map<String, dynamic>) return rawData;
    if (rawData is Map) return Map<String, dynamic>.from(rawData);
    return null;
  }

  String _cleanDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  CompanyModel _parseCompanyModel(Map<String, dynamic> data, String docId) {
    final dynamic parser = CompanyModel.fromMap;
    try {
      return parser(data, docId) as CompanyModel;
    } on NoSuchMethodError {
      return parser(data) as CompanyModel;
    }
  }

  Future<CompanyModel?> _fetchCompanyData(
    String companyCnpj, {
    Map<String, CompanyModel?>? cache,
  }) async {
    if (companyCnpj.trim().isEmpty) return null;
    final cleanCnpj = _cleanDigits(companyCnpj);

    if (cache != null && cache.containsKey(cleanCnpj)) {
      return cache[cleanCnpj];
    }

    try {
      final directDoc = await _companiesCollection.doc(cleanCnpj).get();
      final directData = _asMap(directDoc.data());
      if (directDoc.exists && directData != null) {
        final company = _parseCompanyModel(directData, directDoc.id);
        if (cache != null) cache[cleanCnpj] = company;
        return company;
      }

      final queryValues = <String>{
        if (companyCnpj.trim().isNotEmpty) companyCnpj.trim(),
        if (cleanCnpj.isNotEmpty) cleanCnpj,
      }.toList();

      if (queryValues.isNotEmpty) {
        final query = await _companiesCollection
            .where('cnpj', whereIn: queryValues)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final doc = query.docs.first;
          final docData = _asMap(doc.data());
          if (docData != null) {
            final company = _parseCompanyModel(docData, doc.id);
            if (cache != null) cache[cleanCnpj] = company;
            return company;
          }
        }
      }
    } catch (_) {}

    if (cache != null) cache[cleanCnpj] = null;
    return null;
  }

  Future<String> _uploadImageToCloudinary(File imageFile, int routeId) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = 'routes'
      ..fields['public_id'] =
          'route_${routeId}_${DateTime.now().millisecondsSinceEpoch}'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to upload route image to Cloudinary (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map && decoded['secure_url'] != null) {
      return decoded['secure_url'].toString();
    }

    throw Exception('Secure URL not returned by Cloudinary.');
  }

  @override
  Future<List<RouteModel>> fetchAllRoutes() async {
    final snapshot = await _routesCollection.get();
    final List<RouteModel> routes = [];
    final Map<String, CompanyModel?> companyCache = {};

    for (final doc in snapshot.docs) {
      final data = _asMap(doc.data());
      if (data == null) continue;

      final cnpj =
          (data['companyCnpj'] ?? data['cnpj_empresa'] ?? '') as String;
      final company = await _fetchCompanyData(cnpj, cache: companyCache);

      routes.add(RouteModel.fromMap(data, company: company));
    }

    return routes;
  }

  @override
  Future<List<RouteModel>> fetchRoutesByCompany(String companyCnpj) async {
    final cleanCnpj = _cleanDigits(companyCnpj);
    final queryValues = <String>{
      if (companyCnpj.trim().isNotEmpty) companyCnpj.trim(),
      if (cleanCnpj.isNotEmpty) cleanCnpj,
    }.toList();

    if (queryValues.isEmpty) return [];

    final snapshot = await _routesCollection
        .where('companyCnpj', whereIn: queryValues)
        .get();

    final company = await _fetchCompanyData(companyCnpj);
    final List<RouteModel> routes = [];

    for (final doc in snapshot.docs) {
      final data = _asMap(doc.data());
      if (data == null) continue;

      routes.add(RouteModel.fromMap(data, company: company));
    }

    return routes;
  }

  @override
  Future<RouteModel?> getRouteById(int routeId) async {
    final doc = await _routesCollection.doc(routeId.toString()).get();
    final directData = _asMap(doc.data());

    if (doc.exists && directData != null) {
      final cnpj =
          (directData['companyCnpj'] ?? directData['cnpj_empresa'] ?? '')
              as String;
      final company = await _fetchCompanyData(cnpj);
      return RouteModel.fromMap(directData, company: company);
    }

    final query = await _routesCollection
        .where('id', isEqualTo: routeId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final foundDoc = query.docs.first;
      final foundData = _asMap(foundDoc.data());
      if (foundData != null) {
        final cnpj =
            (foundData['companyCnpj'] ?? foundData['cnpj_empresa'] ?? '')
                as String;
        final company = await _fetchCompanyData(cnpj);
        return RouteModel.fromMap(foundData, company: company);
      }
    }

    return null;
  }

  @override
  Future<RouteModel> createRoute(RouteModel route, {File? imageFile}) async {
    final int routeId = route.id != 0
        ? route.id
        : DateTime.now().millisecondsSinceEpoch;

    String? uploadedImageUrl = route.imageUrl;
    if (imageFile != null) {
      uploadedImageUrl = await _uploadImageToCloudinary(imageFile, routeId);
    }

    final company =
        route.company ?? await _fetchCompanyData(route.companyCnpj);

    final modelToSave = route.copyWith(
      id: routeId,
      imageUrl: uploadedImageUrl ?? company?.logoUrl,
      company: company,
    );

    await _routesCollection.doc(routeId.toString()).set(modelToSave.toMap());
    return modelToSave;
  }

  @override
  Future<RouteModel> updateRoute(RouteModel route, {File? imageFile}) async {
    String? uploadedImageUrl = route.imageUrl;
    if (imageFile != null) {
      uploadedImageUrl = await _uploadImageToCloudinary(imageFile, route.id);
    }

    final company =
        route.company ?? await _fetchCompanyData(route.companyCnpj);

    final updatedModel = route.copyWith(
      imageUrl: uploadedImageUrl,
      company: company,
    );

    final docRef = _routesCollection.doc(route.id.toString());
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      await docRef.update(updatedModel.toMap());
    } else {
      final query = await _routesCollection
          .where('id', isEqualTo: route.id)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update(updatedModel.toMap());
      } else {
        await docRef.set(updatedModel.toMap());
      }
    }

    return updatedModel;
  }

  @override
  Future<String> updateRouteImage(int routeId, File imageFile) async {
    final imageUrl = await _uploadImageToCloudinary(imageFile, routeId);
    final docRef = _routesCollection.doc(routeId.toString());
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      await docRef.update({'imageUrl': imageUrl});
    } else {
      final query = await _routesCollection
          .where('id', isEqualTo: routeId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({'imageUrl': imageUrl});
      }
    }

    return imageUrl;
  }

  @override
  Future<void> deleteRoute(int routeId) async {
    final docRef = _routesCollection.doc(routeId.toString());
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      await docRef.delete();
      return;
    }

    final query = await _routesCollection
        .where('id', isEqualTo: routeId)
        .get();

    for (final doc in query.docs) {
      await doc.reference.delete();
    }
  }
}