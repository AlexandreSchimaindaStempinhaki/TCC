import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../../domain/models/company_entity.dart';
import '../../../domain/models/company_review_entity.dart';
import 'i_company_firebase_service.dart';

final class CompanyRemoteServiceImpl implements ICompanyRemoteService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String cloudName = 'db37erprw';
  final String uploadPreset = 'tcc_pics';

  CompanyRemoteServiceImpl({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  String get _currentUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Nenhum usuário autenticado no Firebase Auth.');
    }
    return uid;
  }

  CollectionReference get _companiesRef => _firestore.collection('companies');

  @override
  Future<void> createCompany(CompanyModel company) async {
    try {
      final uid = _currentUid;
      final cleanCnpj = company.cnpj.replaceAll(RegExp(r'\D'), '');

      final docRef = _companiesRef.doc(cleanCnpj);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        throw Exception('Já existe uma empresa cadastrada com este CNPJ.');
      }

      final companyToSave = company.copyWith(
        cnpj: cleanCnpj,
        ownerId: uid,
        memberIds: {uid, ...company.memberIds}.toList(),
      );

      await docRef.set(companyToSave.toMap());
    } catch (e) {
      throw Exception('Erro ao criar empresa: $e');
    }
  }

  @override
  Future<List<CompanyModel>> fetchCompaniesByOwner([String? ownerId]) async {
    try {
      final targetOwnerId = (ownerId != null && ownerId.isNotEmpty)
          ? ownerId
          : _currentUid;

      final snapshot = await _companiesRef
          .where('ownerId', isEqualTo: targetOwnerId)
          .get();

      return snapshot.docs
          .map(
            (doc) => CompanyModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar empresas do proprietário: $e');
    }
  }

  @override
  Future<List<CompanyModel>> fetchCompaniesByMember([String? memberId]) async {
    try {
      final uid = _currentUid;
      final candidateStrings = <String>{uid.trim().toLowerCase()};
      final candidateDigits = <String>{};

      void addCandidate(dynamic raw) {
        if (raw == null) return;
        final str = raw.toString().trim();
        if (str.isEmpty) return;
        candidateStrings.add(str.toLowerCase());
        final digits = str.replaceAll(RegExp(r'\D'), '');
        if (digits.length >= 9) {
          candidateDigits.add(digits);
          candidateStrings.add(digits);
        }
      }

      addCandidate(memberId);
      addCandidate(_auth.currentUser?.email);

      // 1. Busca os dados do perfil do usuário logado na coleção 'users'
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() is Map) {
        final userMap = Map<String, dynamic>.from(userDoc.data() as Map);
        addCandidate(userMap['cpf']);
        addCandidate(userMap['uid']);
        addCandidate(userMap['email']);
      } else {
        // Caso o documento em 'users' tenha sido salvo com o CPF como doc.id em vez do UID
        final queryByUid = await _firestore
            .collection('users')
            .where('uid', isEqualTo: uid)
            .limit(1)
            .get();
        if (queryByUid.docs.isNotEmpty) {
          final doc = queryByUid.docs.first;
          addCandidate(doc.id);
          if (doc.data() is Map) {
            final userMap = Map<String, dynamic>.from(doc.data() as Map);
            addCandidate(userMap['cpf']);
            addCandidate(userMap['email']);
          }
        }
      }

      bool matchesUser(dynamic value) {
        if (value == null) return false;
        final str = value.toString().trim();
        if (str.isEmpty) return false;
        if (candidateStrings.contains(str.toLowerCase())) return true;
        final digits = str.replaceAll(RegExp(r'\D'), '');
        if (digits.length >= 9 && candidateDigits.contains(digits)) {
          return true;
        }
        for (final token in candidateStrings) {
          if (token.length >= 9 && str.toLowerCase().contains(token)) {
            return true;
          }
        }
        return false;
      }

      final linkedCnpjs = <String>{};

      void registerCnpj(dynamic rawCnpj) {
        if (rawCnpj == null) return;
        final str = rawCnpj.toString().trim();
        if (str.isEmpty) return;
        linkedCnpjs.add(str);
        final digits = str.replaceAll(RegExp(r'\D'), '');
        if (digits.isNotEmpty) linkedCnpjs.add(digits);
      }

      // 2. Varre a coleção 'company_members'
      final membersSnap = await _firestore.collection('company_members').get();
      for (final doc in membersSnap.docs) {
        final rawData = doc.data();
        final map = rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : <String, dynamic>{};

        final personId =
            map['cpf_pessoa'] ??
            map['cpfPessoa'] ??
            map['userId'] ??
            map['uid'] ??
            map['cpf'];

        if (matchesUser(personId) || matchesUser(doc.id)) {
          final cnpj =
              map['cnpj_empresa'] ??
              map['cnpjEmpresa'] ??
              map['companyCnpj'] ??
              doc.id.split('_').first;
          registerCnpj(cnpj);
        }
      }

      // 3. Varre a coleção 'routes' (passageiros aprovados, confirmados ou motorista)
      final routesSnap = await _firestore.collection('routes').get();
      for (final doc in routesSnap.docs) {
        final rawData = doc.data();
        if (rawData is! Map) continue;
        final map = Map<String, dynamic>.from(rawData);

        final driver = map['driverId'] ?? map['cpfMotorista'];
        final passengers =
            (map['passengerIds'] ?? map['listaIdPassageiros']) as List? ?? [];
        final confirmed =
            (map['confirmedPassengerIds'] ?? map['listaIdConfirmados'])
                as List? ??
            [];

        if (matchesUser(driver) ||
            passengers.any(matchesUser) ||
            confirmed.any(matchesUser)) {
          registerCnpj(
            map['companyCnpj'] ?? map['cnpj_empresa'] ?? map['cnpjEmpresa'],
          );
        }
      }

      final allCompaniesSnap = await _companiesRef.get();
      final result = <String, CompanyModel>{};

      for (final doc in allCompaniesSnap.docs) {
        final rawData = doc.data();
        if (rawData is! Map) continue;
        final map = Map<String, dynamic>.from(rawData);
        final company = CompanyModel.fromMap(map, doc.id);

        final docIdClean = doc.id.replaceAll(RegExp(r'\D'), '');
        final cnpjClean = company.cnpj.replaceAll(RegExp(r'\D'), '');

        final isOwner = matchesUser(company.ownerId);
        final inMemberIds = company.memberIds.any(matchesUser);
        final inLinkedCnpjs =
            linkedCnpjs.contains(doc.id) ||
            linkedCnpjs.contains(company.cnpj) ||
            (docIdClean.isNotEmpty && linkedCnpjs.contains(docIdClean)) ||
            (cnpjClean.isNotEmpty && linkedCnpjs.contains(cnpjClean));

        if (isOwner || inMemberIds || inLinkedCnpjs) {
          final key = cnpjClean.isNotEmpty ? cnpjClean : doc.id;
          result[key] = company;
        }
      }

      return result.values.toList();
    } catch (e) {
      throw Exception('Erro ao buscar empresas do membro: $e');
    }
  }

  @override
  Future<void> updateCompany(CompanyModel company) async {
    try {
      final cleanCnpj = company.cnpj.replaceAll(RegExp(r'\D'), '');
      await _companiesRef
          .doc(cleanCnpj)
          .set(company.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Erro ao atualizar empresa: $e');
    }
  }

  @override
  Future<String> uploadCompanyLogo(String cnpj, File imageFile) async {
    final cleanCnpj = cnpj.replaceAll(RegExp(r'\D'), '');

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final jsonMap = jsonDecode(responseData);
      final String secureUrl = jsonMap['secure_url'];

      await _companiesRef.doc(cleanCnpj).update({'logoUrl': secureUrl});

      return secureUrl;
    } else {
      throw Exception(
        'Falha ao fazer upload da logo. Status: ${response.statusCode}',
      );
    }
  }

  @override
  Future<void> deleteCompany(String cnpj) async {
    try {
      final cleanCnpj = cnpj.replaceAll(RegExp(r'\D'), '');
      await _companiesRef.doc(cleanCnpj).delete();
    } catch (e) {
      throw Exception('Erro ao excluir empresa: $e');
    }
  }

  CompanyReviewModel? _reviewFromDoc(DocumentSnapshot doc, String companyCnpj) {
    if (!doc.exists) return null;
    final raw = doc.data();
    if (raw is! Map) return null;

    final map = Map<String, dynamic>.from(raw);
    if (map['rating'] == null)
      return null; // Ignora se foi apenas um "Agora não"

    final rawDate = map['updatedAt'] ?? map['createdAt'];
    final DateTime parsedDate = rawDate is Timestamp
        ? rawDate.toDate()
        : (rawDate is DateTime ? rawDate : DateTime.now());

    final desc = (map['description'] ?? map['descricao'] ?? map['comment'])
        ?.toString()
        .trim();

    return CompanyReviewModel(
      id: doc.id,
      companyCnpj: companyCnpj,
      userId: (map['userId'] ?? doc.id).toString(),
      userName: (map['userName'] ?? 'Passageiro').toString(),
      userPhotoUrl: map['userPhotoUrl']?.toString(),
      rating: double.tryParse(map['rating'].toString()) ?? 5.0,
      description: (desc != null && desc.isNotEmpty) ? desc : null,
      createdAt: parsedDate,
    );
  }

  @override
  Future<List<CompanyReviewModel>> fetchCompanyReviews(String cnpj) async {
    final cleanCnpj = cnpj.replaceAll(RegExp(r'\D'), '');
    if (cleanCnpj.isEmpty) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(cleanCnpj)
        .collection('ratings')
        .get();

    final reviews = snapshot.docs
        .map((doc) => _reviewFromDoc(doc, cleanCnpj))
        .whereType<CompanyReviewModel>()
        .toList();

    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reviews;
  }

  @override
  Future<CompanyReviewModel?> getUserCompanyReview({
    required String cnpj,
    required String userId,
  }) async {
    final cleanCnpj = cnpj.replaceAll(RegExp(r'\D'), '');
    final cleanUser = userId.trim();
    if (cleanCnpj.isEmpty || cleanUser.isEmpty) return null;

    final doc = await FirebaseFirestore.instance
        .collection('companies')
        .doc(cleanCnpj)
        .collection('ratings')
        .doc(cleanUser)
        .get();

    return _reviewFromDoc(doc, cleanCnpj);
  }

  @override
  Future<bool> shouldPromptFirstTripReview({
    required String cnpj,
    required String userId,
  }) async {
    final cleanCnpj = cnpj.replaceAll(RegExp(r'\D'), '');
    final cleanUser = userId.trim();
    if (cleanCnpj.isEmpty || cleanUser.isEmpty) return false;

    final doc = await FirebaseFirestore.instance
        .collection('companies')
        .doc(cleanCnpj)
        .collection('ratings')
        .doc(cleanUser)
        .get();

    if (!doc.exists) return true;
    final raw = doc.data();
    if (raw is! Map) return true;

    final map = Map<String, dynamic>.from(raw!);
    final hasRated = map['rating'] != null;
    final wasDismissed = (map['promptDismissed'] as bool?) ?? false;

    return !hasRated && !wasDismissed;
  }

  @override
  Future<void> dismissFirstTripReviewPrompt({
    required String cnpj,
    required String userId,
  }) async {
    final cleanCnpj = cnpj.replaceAll(RegExp(r'\D'), '');
    final cleanUser = userId.trim();
    if (cleanCnpj.isEmpty || cleanUser.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(cleanCnpj)
        .collection('ratings')
        .doc(cleanUser)
        .set({
          'userId': cleanUser,
          'promptDismissed': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  @override
  Future<CompanyModel> rateCompany({
    required String cnpj,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required double rating,
    String? description,
  }) async {
    final cleanCnpj = cnpj.replaceAll(RegExp(r'\D'), '');
    final cleanUser = userId.trim();
    final clampedRating = rating.clamp(1.0, 5.0);
    final trimmedDesc = description?.trim();

    final firestore = FirebaseFirestore.instance;
    final companyRef = firestore.collection('companies').doc(cleanCnpj);
    final userRatingRef = companyRef.collection('ratings').doc(cleanUser);

    return firestore.runTransaction<CompanyModel>((transaction) async {
      final companySnap = await transaction.get(companyRef);
      if (!companySnap.exists || companySnap.data() is! Map) {
        throw Exception('Empresa não encontrada para avaliação.');
      }

      final companyMap = Map<String, dynamic>.from(companySnap.data() as Map);
      final currentCompany = CompanyModel.fromMap(companyMap, companySnap.id);

      final userRatingSnap = await transaction.get(userRatingRef);
      final existingRatingMap =
          (userRatingSnap.exists && userRatingSnap.data() is Map)
          ? Map<String, dynamic>.from(userRatingSnap.data() as Map)
          : null;

      final hadPreviousRating =
          existingRatingMap != null && existingRatingMap['rating'] != null;

      double newAverage = currentCompany.rating;
      int newCount = currentCompany.ratingCount;

      if (hadPreviousRating) {
        final oldRating =
            double.tryParse(existingRatingMap['rating'].toString()) ?? 0.0;
        if (newCount <= 1) {
          newCount = 1;
          newAverage = clampedRating;
        } else {
          final totalSum =
              (currentCompany.rating * currentCompany.ratingCount) -
              oldRating +
              clampedRating;
          newAverage = totalSum / newCount;
        }
      } else {
        final totalSum =
            (currentCompany.rating * currentCompany.ratingCount) +
            clampedRating;
        newCount = currentCompany.ratingCount + 1;
        newAverage = totalSum / newCount;
      }

      newAverage = double.parse(newAverage.toStringAsFixed(2));

      transaction.set(userRatingRef, {
        'userId': cleanUser,
        'userName': userName.trim(),
        'userPhotoUrl': userPhotoUrl?.trim(),
        'rating': clampedRating,
        'description': trimmedDesc,
        'descricao': trimmedDesc,
        'promptDismissed': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.update(companyRef, {
        'rating': newAverage,
        'avaliacao': newAverage,
        'ratingCount': newCount,
        'quantidadeAvaliacoes': newCount,
      });

      return currentCompany.copyWith(rating: newAverage, ratingCount: newCount);
    });
  }
}
