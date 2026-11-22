import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreCascadeDeleteHelper {
  final FirebaseFirestore _firestore;

  static const int _whereInChunkSize = 10;
  static const int _batchLimit = 400;

  FirestoreCascadeDeleteHelper(this._firestore);

  CollectionReference get _users => _firestore.collection('users');
  CollectionReference get _companies => _firestore.collection('companies');
  CollectionReference get _routes => _firestore.collection('routes');
  CollectionReference get _vehicles => _firestore.collection('vehicles');
  CollectionReference get _trips => _firestore.collection('trips');
  CollectionReference get _boardings => _firestore.collection('boardings');
  CollectionReference get _notifications =>
      _firestore.collection('notifications');
  CollectionReference get _vinculosEmpresa =>
      _firestore.collection('vinculos_empresa');
  CollectionReference get _companyMembers =>
      _firestore.collection('company_members');

  String _cleanDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  Map<String, dynamic>? _asMap(Object? rawData) {
    if (rawData == null) return null;
    if (rawData is Map<String, dynamic>) return rawData;
    if (rawData is Map) return Map<String, dynamic>.from(rawData);
    return null;
  }

  List<List<T>> _chunk<T>(List<T> items, int size) {
    final chunks = <List<T>>[];
    for (int i = 0; i < items.length; i += size) {
      final end = (i + size > items.length) ? items.length : i + size;
      chunks.add(items.sublist(i, end));
    }
    return chunks;
  }

  Future<List<QueryDocumentSnapshot>> _queryWhereIn(
    CollectionReference col,
    String field,
    Iterable<Object> values,
  ) async {
    final uniqueValues = values.toSet().toList();
    if (uniqueValues.isEmpty) return [];

    final byPath = <String, QueryDocumentSnapshot>{};
    for (final part in _chunk(uniqueValues, _whereInChunkSize)) {
      try {
        final snap = await col.where(field, whereIn: part).get();
        for (final doc in snap.docs) {
          byPath[doc.reference.path] = doc;
        }
      } catch (_) {}
    }
    return byPath.values.toList();
  }

  Future<List<QueryDocumentSnapshot>> _queryArrayContainsAny(
    CollectionReference col,
    String field,
    Iterable<Object> values,
  ) async {
    final uniqueValues = values.toSet().toList();
    if (uniqueValues.isEmpty) return [];

    final byPath = <String, QueryDocumentSnapshot>{};
    for (final part in _chunk(uniqueValues, _whereInChunkSize)) {
      try {
        final snap = await col.where(field, arrayContainsAny: part).get();
        for (final doc in snap.docs) {
          byPath[doc.reference.path] = doc;
        }
      } catch (_) {}
    }
    return byPath.values.toList();
  }

  Future<void> _deleteRefs(Iterable<DocumentReference> refs) async {
    final uniqueByPath = <String, DocumentReference>{};
    for (final ref in refs) {
      uniqueByPath[ref.path] = ref;
    }
    final list = uniqueByPath.values.toList();
    if (list.isEmpty) return;

    for (final part in _chunk(list, _batchLimit)) {
      final batch = _firestore.batch();
      for (final ref in part) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }

  Future<void> _updateDocs(
    Map<DocumentReference, Map<String, dynamic>> updates,
  ) async {
    if (updates.isEmpty) return;
    final entries = updates.entries.toList();

    for (final part in _chunk(entries, _batchLimit)) {
      final batch = _firestore.batch();
      for (final entry in part) {
        batch.update(entry.key, entry.value);
      }
      await batch.commit();
    }
  }

  Set<String> _buildCnpjVariants(String cnpj) {
    final raw = cnpj.trim();
    final clean = _cleanDigits(raw);
    return {
      if (raw.isNotEmpty) raw,
      if (clean.isNotEmpty) clean,
    };
  }

  void _addIdentifierVariants(Set<String> target, dynamic raw) {
    if (raw == null) return;
    final str = raw.toString().trim();
    if (str.isEmpty) return;
    target.add(str);
    target.add(str.toLowerCase());
    final digits = _cleanDigits(str);
    if (digits.length == 11) {
      target.add(digits);
    }
  }

  bool _matchesAnyId(dynamic raw, Set<String> idSet) {
    if (raw == null) return false;
    final str = raw.toString().trim();
    if (str.isEmpty) return false;
    if (idSet.contains(str) || idSet.contains(str.toLowerCase())) return true;
    final digits = _cleanDigits(str);
    return digits.length == 11 && idSet.contains(digits);
  }

  bool _isActiveTripStatus(dynamic rawStatus) {
    final status = (rawStatus ?? '').toString().trim().toLowerCase();
    return status == 'in_progress' ||
        status == 'inprogress' ||
        status == 'em_andamento' ||
        status == 'boarding';
  }

  Future<({Set<String> ids, List<DocumentReference> userDocRefs})>
  _collectUserIdentifiers({
    String? uid,
    String? email,
    String? cpfOrAnyId,
  }) async {
    final ids = <String>{};
    final docRefsByPath = <String, DocumentReference>{};

    _addIdentifierVariants(ids, uid);
    _addIdentifierVariants(ids, email);
    _addIdentifierVariants(ids, cpfOrAnyId);

    void absorbUserDoc(DocumentSnapshot doc) {
      if (!doc.exists) return;
      docRefsByPath[doc.reference.path] = doc.reference;
      _addIdentifierVariants(ids, doc.id);
      final data = _asMap(doc.data());
      if (data == null) return;
      _addIdentifierVariants(ids, data['uid']);
      _addIdentifierVariants(ids, data['cpf']);
      _addIdentifierVariants(ids, data['email']);
    }

    if (uid != null && uid.trim().isNotEmpty) {
      try {
        final direct = await _users.doc(uid.trim()).get();
        absorbUserDoc(direct);
      } catch (_) {}

      final byUid = await _queryWhereIn(_users, 'uid', [uid.trim()]);
      for (final d in byUid) {
        absorbUserDoc(d);
      }
    }

    if (cpfOrAnyId != null && cpfOrAnyId.trim().isNotEmpty) {
      final raw = cpfOrAnyId.trim();
      try {
        final direct = await _users.doc(raw).get();
        absorbUserDoc(direct);
      } catch (_) {}

      final candidates = <String>{
        raw,
        if (_cleanDigits(raw).isNotEmpty) _cleanDigits(raw),
      };
      for (final field in ['cpf', 'uid', 'email']) {
        final found = await _queryWhereIn(_users, field, candidates);
        for (final d in found) {
          absorbUserDoc(d);
        }
      }
    }

    return (ids: ids, userDocRefs: docRefsByPath.values.toList());
  }

  Future<void> _syncRouteActiveFlagIfNoTrips(String routeIdStr) async {
    final trimmed = routeIdStr.trim();
    if (trimmed.isEmpty) return;

    final routeIdInt = int.tryParse(trimmed);
    final routeValues = <Object>[
      trimmed,
      if (routeIdInt != null) routeIdInt,
    ];

    final trips = await _queryWhereIn(_trips, 'routeId', routeValues);
    final hasActive = trips.any((doc) {
      final data = _asMap(doc.data());
      return data != null && _isActiveTripStatus(data['status']);
    });

    if (hasActive) return;

    final routeDocs = <String, DocumentReference>{};
    try {
      final direct = await _routes.doc(trimmed).get();
      if (direct.exists) routeDocs[direct.reference.path] = direct.reference;
    } catch (_) {}

    if (routeIdInt != null) {
      final byId = await _queryWhereIn(_routes, 'id', [routeIdInt]);
      for (final d in byId) {
        routeDocs[d.reference.path] = d.reference;
      }
    }

    if (routeDocs.isNotEmpty) {
      await _updateDocs({
        for (final ref in routeDocs.values)
          ref: {
            'isTripActive': false,
            'tripStartedAt': null,
          },
      });
    }
  }

  // =========================================================================
  //   1. EXCLUIR VIAGEM -> notificações + desvincular embarques + rota ativa
  // =========================================================================
  Future<void> deleteTrip(String tripId) async {
    final trimmed = tripId.trim();
    if (trimmed.isEmpty) return;

    String? affectedRouteId;
    bool wasActive = false;

    try {
      final snap = await _trips.doc(trimmed).get();
      final data = _asMap(snap.data());
      if (data != null) {
        affectedRouteId = data['routeId']?.toString();
        wasActive = _isActiveTripStatus(data['status']);
      }
    } catch (_) {}

    final notifDocs = await _queryWhereIn(_notifications, 'tripId', [trimmed]);
    await _deleteRefs(notifDocs.map((d) => d.reference));

    final boardingDocs = await _queryWhereIn(_boardings, 'tripId', [trimmed]);
    if (boardingDocs.isNotEmpty) {
      await _updateDocs({
        for (final doc in boardingDocs) doc.reference: {'tripId': null},
      });
    }

    await _trips.doc(trimmed).delete();

    if (wasActive && affectedRouteId != null && affectedRouteId.isNotEmpty) {
      await _syncRouteActiveFlagIfNoTrips(affectedRouteId);
    }
  }

  // =========================================================================
  //   2. EXCLUIR VEÍCULO -> cancela viagens ativas do veículo + limpa histórico
  // =========================================================================
  Future<void> deleteVehicle(String vehicleId) async {
    final trimmed = vehicleId.trim();
    if (trimmed.isEmpty) return;

    final trips = await _queryWhereIn(_trips, 'vehicleId', [trimmed]);
    final affectedActiveRoutes = <String>{};
    final tripUpdates = <DocumentReference, Map<String, dynamic>>{};

    for (final doc in trips) {
      final data = _asMap(doc.data()) ?? const {};
      final active = _isActiveTripStatus(data['status']);

      if (active) {
        final routeId = data['routeId']?.toString().trim() ?? '';
        if (routeId.isNotEmpty) affectedActiveRoutes.add(routeId);
        tripUpdates[doc.reference] = {
          'vehicleId': '',
          'status': 'cancelled',
          'isSharingLocation': false,
          'updatedAt': FieldValue.serverTimestamp(),
        };
      } else {
        tripUpdates[doc.reference] = {
          'vehicleId': '',
          'updatedAt': FieldValue.serverTimestamp(),
        };
      }
    }

    await _updateDocs(tripUpdates);
    await _vehicles.doc(trimmed).delete();

    for (final routeId in affectedActiveRoutes) {
      await _syncRouteActiveFlagIfNoTrips(routeId);
    }
  }

  // =========================================================================
  //   3. EXCLUIR ROTA -> embarques + viagens + notificações + rota
  // =========================================================================
  Future<void> deleteRoute(int routeId) async {
    await _deleteRouteInternal(
      routeIdStr: routeId.toString(),
      routeIdInt: routeId,
    );
  }

  Future<void> _deleteRouteInternal({
    required String routeIdStr,
    int? routeIdInt,
    DocumentReference? knownRouteRef,
  }) async {
    final routeValues = <Object>[
      if (routeIdStr.trim().isNotEmpty) routeIdStr.trim(),
      if (routeIdInt != null) routeIdInt,
    ];
    if (routeValues.isEmpty) return;

    // 1. Viagens e notificações da rota
    final tripDocs = await _queryWhereIn(_trips, 'routeId', routeValues);
    final tripIds = tripDocs.map((d) => d.id).where((id) => id.isNotEmpty).toList();

    final notifsByRoute =
        await _queryWhereIn(_notifications, 'routeId', routeValues);
    final notifsByTrip = tripIds.isNotEmpty
        ? await _queryWhereIn(_notifications, 'tripId', tripIds)
        : const <QueryDocumentSnapshot>[];

    await _deleteRefs([
      ...notifsByRoute.map((d) => d.reference),
      ...notifsByTrip.map((d) => d.reference),
    ]);

    await _deleteRefs(tripDocs.map((d) => d.reference));

    // 2. Embarques da rota
    final boardingDocs = await _queryWhereIn(_boardings, 'routeId', routeValues);
    await _deleteRefs(boardingDocs.map((d) => d.reference));

    // 3. Documento(s) da rota
    final routeRefs = <DocumentReference>[
      if (knownRouteRef != null) knownRouteRef,
    ];

    if (routeIdStr.trim().isNotEmpty) {
      try {
        final direct = await _routes.doc(routeIdStr.trim()).get();
        if (direct.exists) routeRefs.add(direct.reference);
      } catch (_) {}
    }

    if (routeIdInt != null) {
      final byId = await _queryWhereIn(_routes, 'id', [routeIdInt]);
      routeRefs.addAll(byId.map((d) => d.reference));
    }

    await _deleteRefs(routeRefs);
  }

  // =========================================================================
  //   4. REMOVER PASSAGEIRO DA ROTA -> listas da rota + embarques dele na rota
  // =========================================================================
  Future<void> removePassengerFromRoute({
    required int routeId,
    required String userId,
  }) async {
    final collected = await _collectUserIdentifiers(cpfOrAnyId: userId);
    final idList = collected.ids.toList();
    if (idList.isEmpty) return;

    final routeIdStr = routeId.toString();
    final routeValues = <Object>[routeIdStr, routeId];

    // Remove dos arrays da rota
    final routeRefs = <String, DocumentReference>{};
    try {
      final direct = await _routes.doc(routeIdStr).get();
      if (direct.exists) routeRefs[direct.reference.path] = direct.reference;
    } catch (_) {}
    final byId = await _queryWhereIn(_routes, 'id', [routeId]);
    for (final d in byId) {
      routeRefs[d.reference.path] = d.reference;
    }

    if (routeRefs.isNotEmpty) {
      await _updateDocs({
        for (final ref in routeRefs.values)
          ref: {
            'pendingPassengerIds': FieldValue.arrayRemove(idList),
            'passengerIds': FieldValue.arrayRemove(idList),
            'listaIdPassageiros': FieldValue.arrayRemove(idList),
            'confirmedPassengerIds': FieldValue.arrayRemove(idList),
            'listaIdConfirmados': FieldValue.arrayRemove(idList),
          },
      });
    }

    // Remove embarques desse passageiro nesta rota
    final routeBoardings =
        await _queryWhereIn(_boardings, 'routeId', routeValues);
    final toDelete = <DocumentReference>[];
    for (final doc in routeBoardings) {
      final data = _asMap(doc.data());
      if (data == null) continue;
      if (_matchesAnyId(data['userId'], collected.ids) ||
          _matchesAnyId(data['cpfPessoa'], collected.ids)) {
        toDelete.add(doc.reference);
      }
    }
    await _deleteRefs(toDelete);
  }

  // =========================================================================
  //   5. REMOVER MEMBRO DA EMPRESA -> vínculos + rotas da empresa + veículos
  // =========================================================================
  Future<void> removeCompanyMember({
    required String cnpjEmpresa,
    required String cpfPessoa,
  }) async {
    final cnpjVariants = _buildCnpjVariants(cnpjEmpresa);
    if (cnpjVariants.isEmpty) return;

    final collected = await _collectUserIdentifiers(cpfOrAnyId: cpfPessoa);
    final idSet = collected.ids;
    final idList = idSet.toList();
    if (idList.isEmpty) return;

    final cleanCnpj = _cleanDigits(cnpjEmpresa);

    // 1. Exclui vínculos em 'vinculos_empresa' e 'company_members'
    final linksToDelete = <DocumentReference>[];

    for (final uidOrCpf in idList) {
      final cleanUser = _cleanDigits(uidOrCpf).isNotEmpty
          ? _cleanDigits(uidOrCpf)
          : uidOrCpf.trim();
      if (cleanCnpj.isNotEmpty && cleanUser.isNotEmpty) {
        try {
          final direct =
              await _vinculosEmpresa.doc('${cleanCnpj}_$cleanUser').get();
          if (direct.exists) linksToDelete.add(direct.reference);
        } catch (_) {}
      }
    }

    for (final col in [_vinculosEmpresa, _companyMembers]) {
      for (final field in ['cnpj_empresa', 'cnpjEmpresa', 'companyCnpj']) {
        final docs = await _queryWhereIn(col, field, cnpjVariants);
        for (final doc in docs) {
          final data = _asMap(doc.data()) ?? const {};
          final matches =
              _matchesAnyId(data['cpf_pessoa'], idSet) ||
              _matchesAnyId(data['cpfPessoa'], idSet) ||
              _matchesAnyId(data['userId'], idSet) ||
              _matchesAnyId(data['cpf'], idSet) ||
              _matchesAnyId(data['uid'], idSet) ||
              _matchesAnyId(data['email'], idSet);
          if (matches) linksToDelete.add(doc.reference);
        }
      }
    }

    await _deleteRefs(linksToDelete);

    // 2. Remove do array de membros da empresa
    final companyRefs = await _findCompanyRefs(cnpjVariants, cleanCnpj);
    if (companyRefs.isNotEmpty) {
      await _updateDocs({
        for (final ref in companyRefs)
          ref: {
            'memberIds': FieldValue.arrayRemove(idList),
            'listaIdMembros': FieldValue.arrayRemove(idList),
          },
      });
    }

    // 3. Remove das rotas da empresa + embarques nessas rotas
    final companyRoutes = await _findCompanyRoutes(cnpjVariants);
    final routeUpdates = <DocumentReference, Map<String, dynamic>>{};
    final boardingsToDelete = <DocumentReference>[];

    for (final routeDoc in companyRoutes) {
      final data = _asMap(routeDoc.data()) ?? const {};
      final update = <String, dynamic>{
        'pendingPassengerIds': FieldValue.arrayRemove(idList),
        'passengerIds': FieldValue.arrayRemove(idList),
        'listaIdPassageiros': FieldValue.arrayRemove(idList),
        'confirmedPassengerIds': FieldValue.arrayRemove(idList),
        'listaIdConfirmados': FieldValue.arrayRemove(idList),
      };

      if (_matchesAnyId(data['driverId'], idSet)) {
        update['driverId'] = null;
      }
      if (_matchesAnyId(data['cpfMotorista'], idSet)) {
        update['cpfMotorista'] = null;
      }
      routeUpdates[routeDoc.reference] = update;

      final routeIdInt = int.tryParse((data['id'] ?? routeDoc.id).toString());
      final routeValues = <Object>[
        routeDoc.id,
        if (routeIdInt != null) routeIdInt,
      ];
      final routeBoardings =
          await _queryWhereIn(_boardings, 'routeId', routeValues);
      for (final bDoc in routeBoardings) {
        final bData = _asMap(bDoc.data()) ?? const {};
        if (_matchesAnyId(bData['userId'], idSet) ||
            _matchesAnyId(bData['cpfPessoa'], idSet)) {
          boardingsToDelete.add(bDoc.reference);
        }
      }
    }

    await _updateDocs(routeUpdates);
    await _deleteRefs(boardingsToDelete);

    // 4. Limpa defaultDriverId nos veículos da empresa
    final companyVehicles = await _findCompanyVehicles(cnpjVariants);
    final vehicleUpdates = <DocumentReference, Map<String, dynamic>>{};
    for (final vDoc in companyVehicles) {
      final data = _asMap(vDoc.data()) ?? const {};
      if (_matchesAnyId(data['defaultDriverId'], idSet)) {
        vehicleUpdates[vDoc.reference] = {'defaultDriverId': null};
      }
    }
    await _updateDocs(vehicleUpdates);
  }

  Future<List<DocumentReference>> _findCompanyRefs(
    Set<String> cnpjVariants,
    String cleanCnpj,
  ) async {
    final refs = <String, DocumentReference>{};

    for (final candidate in {if (cleanCnpj.isNotEmpty) cleanCnpj, ...cnpjVariants}) {
      try {
        final direct = await _companies.doc(candidate).get();
        if (direct.exists) refs[direct.reference.path] = direct.reference;
      } catch (_) {}
    }

    final byCnpj = await _queryWhereIn(_companies, 'cnpj', cnpjVariants);
    for (final doc in byCnpj) {
      refs[doc.reference.path] = doc.reference;
    }

    return refs.values.toList();
  }

  Future<List<QueryDocumentSnapshot>> _findCompanyRoutes(
    Set<String> cnpjVariants,
  ) async {
    final byPath = <String, QueryDocumentSnapshot>{};
    for (final field in ['companyCnpj', 'cnpj_empresa', 'cnpjEmpresa']) {
      final docs = await _queryWhereIn(_routes, field, cnpjVariants);
      for (final d in docs) {
        byPath[d.reference.path] = d;
      }
    }
    return byPath.values.toList();
  }

  Future<List<QueryDocumentSnapshot>> _findCompanyVehicles(
    Set<String> cnpjVariants,
  ) async {
    final byPath = <String, QueryDocumentSnapshot>{};
    for (final field in ['companyCnpj', 'cnpjEmpresa']) {
      final docs = await _queryWhereIn(_vehicles, field, cnpjVariants);
      for (final d in docs) {
        byPath[d.reference.path] = d;
      }
    }
    return byPath.values.toList();
  }

  // =========================================================================
  //   6. EXCLUIR EMPRESA -> rotas (e embarques/viagens/notifs) + veículos +
  //      membros + avaliações + empresa
  // =========================================================================
  Future<void> deleteCompany(String cnpj) async {
    final cnpjVariants = _buildCnpjVariants(cnpj);
    if (cnpjVariants.isEmpty) return;
    final cleanCnpj = _cleanDigits(cnpj);

    // 1. Exclui todas as rotas da empresa em cascata
    final companyRoutes = await _findCompanyRoutes(cnpjVariants);
    for (final routeDoc in companyRoutes) {
      final data = _asMap(routeDoc.data());
      final routeIdInt =
          int.tryParse((data?['id'] ?? routeDoc.id).toString());
      await _deleteRouteInternal(
        routeIdStr: routeDoc.id,
        routeIdInt: routeIdInt,
        knownRouteRef: routeDoc.reference,
      );
    }

    // 2. Exclui viagens residuais vinculadas diretamente ao CNPJ da empresa
    final companyTripsByPath = <String, QueryDocumentSnapshot>{};
    for (final field in ['companyCnpj', 'cnpjEmpresa']) {
      final docs = await _queryWhereIn(_trips, field, cnpjVariants);
      for (final d in docs) {
        companyTripsByPath[d.reference.path] = d;
      }
    }
    for (final tripDoc in companyTripsByPath.values) {
      await deleteTrip(tripDoc.id);
    }

    // 3. Exclui todos os veículos da empresa
    final companyVehicles = await _findCompanyVehicles(cnpjVariants);
    await _deleteRefs(companyVehicles.map((d) => d.reference));

    // 4. Exclui todos os vínculos de membros ('vinculos_empresa' e 'company_members')
    final memberLinkRefs = <DocumentReference>[];
    for (final col in [_vinculosEmpresa, _companyMembers]) {
      for (final field in ['cnpj_empresa', 'cnpjEmpresa', 'companyCnpj']) {
        final docs = await _queryWhereIn(col, field, cnpjVariants);
        memberLinkRefs.addAll(docs.map((d) => d.reference));
      }
    }
    await _deleteRefs(memberLinkRefs);

    // 5. Exclui a subcoleção 'ratings' e o(s) documento(s) da empresa
    final companyRefs = await _findCompanyRefs(cnpjVariants, cleanCnpj);
    for (final companyRef in companyRefs) {
      try {
        final ratingsSnap = await companyRef.collection('ratings').get();
        await _deleteRefs(ratingsSnap.docs.map((d) => d.reference));
      } catch (_) {}
    }

    await _deleteRefs(companyRefs);
  }

  // =========================================================================
  //   7. EXCLUIR CONTA DE USUÁRIO -> empresas próprias (cascata total) +
  //      vínculos/rotas/veículos/viagens/embarques/notifs/avaliações + user
  // =========================================================================
  Future<void> deleteUserAccount({
    required String uid,
    String? email,
  }) async {
    final collected = await _collectUserIdentifiers(uid: uid, email: email);
    final idSet = collected.ids;
    final idList = idSet.toList();
    if (idList.isEmpty) return;

    // 1. Exclui todas as empresas onde o usuário é dono (dispara cascata completa)
    final ownedCompanies = await _queryWhereIn(_companies, 'ownerId', idList);
    final deletedCompanyPaths = <String>{};

    for (final compDoc in ownedCompanies) {
      deletedCompanyPaths.add(compDoc.reference.path);
      final data = _asMap(compDoc.data());
      final cnpj = (data?['cnpj'] ?? compDoc.id).toString();
      await deleteCompany(cnpj.isNotEmpty ? cnpj : compDoc.id);
    }

    // 2. Exclui vínculos do usuário em empresas de terceiros
    final linkRefsToDelete = <DocumentReference>[];
    for (final field in ['cpf_pessoa', 'cpfPessoa', 'userId', 'uid', 'cpf']) {
      final vDocs = await _queryWhereIn(_vinculosEmpresa, field, idList);
      linkRefsToDelete.addAll(vDocs.map((d) => d.reference));
    }
    for (final field in [
      'userId',
      'cpf',
      'cpf_pessoa',
      'cpfPessoa',
      'uid',
      'email',
    ]) {
      final mDocs = await _queryWhereIn(_companyMembers, field, idList);
      linkRefsToDelete.addAll(mDocs.map((d) => d.reference));
    }
    await _deleteRefs(linkRefsToDelete);

    // 3. Remove o usuário dos arrays de membros em empresas de terceiros
    final thirdPartyCompanies = <String, QueryDocumentSnapshot>{};
    for (final field in ['memberIds', 'listaIdMembros']) {
      final docs = await _queryArrayContainsAny(_companies, field, idList);
      for (final d in docs) {
        if (!deletedCompanyPaths.contains(d.reference.path)) {
          thirdPartyCompanies[d.reference.path] = d;
        }
      }
    }
    if (thirdPartyCompanies.isNotEmpty) {
      await _updateDocs({
        for (final doc in thirdPartyCompanies.values)
          doc.reference: {
            'memberIds': FieldValue.arrayRemove(idList),
            'listaIdMembros': FieldValue.arrayRemove(idList),
          },
      });
    }

    // 4. Remove avaliações feitas pelo usuário em empresas restantes e recalcula a média
    try {
      final remainingCompanies = await _companies.get();
      for (final compDoc in remainingCompanies.docs) {
        if (deletedCompanyPaths.contains(compDoc.reference.path)) continue;

        final ratingsRef = compDoc.reference.collection('ratings');
        final userRatingRefs = <String, DocumentReference>{};

        final byUserId = await _queryWhereIn(ratingsRef, 'userId', idList);
        for (final r in byUserId) {
          userRatingRefs[r.reference.path] = r.reference;
        }
        for (final id in idList) {
          if (id.contains('/')) continue;
          try {
            final direct = await ratingsRef.doc(id).get();
            if (direct.exists) {
              userRatingRefs[direct.reference.path] = direct.reference;
            }
          } catch (_) {}
        }

        if (userRatingRefs.isEmpty) continue;

        await _deleteRefs(userRatingRefs.values);

        // Recalcula média e total de avaliações da empresa
        final remainingRatings = await ratingsRef.get();
        double sum = 0.0;
        int count = 0;
        for (final rDoc in remainingRatings.docs) {
          final rData = _asMap(rDoc.data());
          if (rData == null || rData['rating'] == null) continue;
          final val = double.tryParse(rData['rating'].toString());
          if (val != null) {
            sum += val;
            count++;
          }
        }
        final newAvg =
            count > 0 ? double.parse((sum / count).toStringAsFixed(2)) : 0.0;

        await compDoc.reference.update({
          'rating': newAvg,
          'avaliacao': newAvg,
          'ratingCount': count,
          'quantidadeAvaliacoes': count,
        });
      }
    } catch (_) {}

    // 5. Remove o usuário de todas as rotas restantes (passageiro/pendente/confirmado/motorista)
    final affectedRoutes = <String, QueryDocumentSnapshot>{};
    for (final field in [
      'passengerIds',
      'listaIdPassageiros',
      'pendingPassengerIds',
      'confirmedPassengerIds',
      'listaIdConfirmados',
    ]) {
      final docs = await _queryArrayContainsAny(_routes, field, idList);
      for (final d in docs) {
        affectedRoutes[d.reference.path] = d;
      }
    }
    for (final field in ['driverId', 'cpfMotorista']) {
      final docs = await _queryWhereIn(_routes, field, idList);
      for (final d in docs) {
        affectedRoutes[d.reference.path] = d;
      }
    }

    final routeUpdates = <DocumentReference, Map<String, dynamic>>{};
    for (final rDoc in affectedRoutes.values) {
      final data = _asMap(rDoc.data()) ?? const {};
      final update = <String, dynamic>{
        'passengerIds': FieldValue.arrayRemove(idList),
        'listaIdPassageiros': FieldValue.arrayRemove(idList),
        'pendingPassengerIds': FieldValue.arrayRemove(idList),
        'confirmedPassengerIds': FieldValue.arrayRemove(idList),
        'listaIdConfirmados': FieldValue.arrayRemove(idList),
      };
      if (_matchesAnyId(data['driverId'], idSet)) {
        update['driverId'] = null;
      }
      if (_matchesAnyId(data['cpfMotorista'], idSet)) {
        update['cpfMotorista'] = null;
      }
      routeUpdates[rDoc.reference] = update;
    }
    await _updateDocs(routeUpdates);

    // 6. Limpa defaultDriverId em veículos de terceiros
    final driverVehicles =
        await _queryWhereIn(_vehicles, 'defaultDriverId', idList);
    if (driverVehicles.isNotEmpty) {
      await _updateDocs({
        for (final vDoc in driverVehicles)
          vDoc.reference: {'defaultDriverId': null},
      });
    }

    // 7. Exclui todos os embarques e notificações do usuário
    final boardingsByUser = await _queryWhereIn(_boardings, 'userId', idList);
    final boardingsByCpf = await _queryWhereIn(_boardings, 'cpfPessoa', idList);
    await _deleteRefs([
      ...boardingsByUser.map((d) => d.reference),
      ...boardingsByCpf.map((d) => d.reference),
    ]);

    final userNotifs = await _queryWhereIn(_notifications, 'userId', idList);
    await _deleteRefs(userNotifs.map((d) => d.reference));

    // 8. Limpa referências do usuário em viagens de terceiros
    final affectedTrips = <String, QueryDocumentSnapshot>{};
    for (final d in await _queryWhereIn(_trips, 'driverId', idList)) {
      affectedTrips[d.reference.path] = d;
    }
    for (final field in ['assignedPassengerIds', 'confirmedPassengerIds']) {
      for (final d in await _queryArrayContainsAny(_trips, field, idList)) {
        affectedTrips[d.reference.path] = d;
      }
    }

    final tripUpdates = <DocumentReference, Map<String, dynamic>>{};
    final routesToCheckActive = <String>{};

    for (final tDoc in affectedTrips.values) {
      final data = _asMap(tDoc.data()) ?? const {};
      final update = <String, dynamic>{
        'assignedPassengerIds': FieldValue.arrayRemove(idList),
        'confirmedPassengerIds': FieldValue.arrayRemove(idList),
      };

      if (_matchesAnyId(data['driverId'], idSet)) {
        update['driverId'] = '';
        if (_isActiveTripStatus(data['status'])) {
          update['status'] = 'cancelled';
          update['isSharingLocation'] = false;
          final rId = data['routeId']?.toString().trim() ?? '';
          if (rId.isNotEmpty) routesToCheckActive.add(rId);
        }
      }

      final rawStops = data['stops'];
      if (rawStops is List) {
        final filteredStops = rawStops.where((item) {
          if (item is! Map) return true;
          return !_matchesAnyId(item['passengerId'], idSet);
        }).toList();

        if (filteredStops.length != rawStops.length) {
          update['stops'] = filteredStops;
          update['passengerCount'] = filteredStops.length;
          update['numeroPassageiros'] = filteredStops.length;
        }
      }

      tripUpdates[tDoc.reference] = update;
    }

    await _updateDocs(tripUpdates);
    for (final routeId in routesToCheckActive) {
      await _syncRouteActiveFlagIfNoTrips(routeId);
    }

    // 9. Por fim, exclui o(s) documento(s) do usuário em 'users'
    await _deleteRefs([
      _users.doc(uid.trim()),
      ...collected.userDocRefs,
    ]);
  }
}