import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_entity.dart';

class CompanyRole {
  static const String admin = 'Administrador';
  static const String driver = 'Motorista';
  static const String passenger = 'Passageiro';
  static const String pending = 'Pendente';
}

class CompanyMemberModel {
  final String id;
  final String userCpf;
  final String companyCnpj;
  final String role;
  final DateTime joinedAt;

  final UserModel? user;

  const CompanyMemberModel({
    required this.id,
    required this.userCpf,
    required this.companyCnpj,
    required this.role,
    required this.joinedAt,
    this.user,
  });

  CompanyMemberModel copyWith({
    String? id,
    String? userCpf,
    String? companyCnpj,
    String? role,
    DateTime? joinedAt,
    UserModel? user,
  }) {
    return CompanyMemberModel(
      id: id ?? this.id,
      userCpf: userCpf ?? this.userCpf,
      companyCnpj: companyCnpj ?? this.companyCnpj,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      user: user ?? this.user,
    );
  }

  factory CompanyMemberModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
    UserModel? user,
  }) {
    final rawDate = map['joinedAt'] ?? map['dataIngresso'];
    final parsedDate = rawDate is Timestamp
        ? rawDate.toDate()
        : (rawDate is DateTime ? rawDate : DateTime.now());

    final companyCnpj =
        (map['companyCnpj'] ?? map['cnpj_empresa']) as String? ?? '';
    final userCpf = (map['userCpf'] ?? map['cpf_pessoa']) as String? ?? '';

    return CompanyMemberModel(
      id: documentId ?? map['id'] as String? ?? '${companyCnpj}_$userCpf',
      userCpf: userCpf,
      companyCnpj: companyCnpj,
      role: (map['role'] ?? map['cargo']) as String? ?? CompanyRole.passenger,
      joinedAt: parsedDate,
      user: user,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userCpf': userCpf,
      'companyCnpj': companyCnpj,
      'role': role,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}