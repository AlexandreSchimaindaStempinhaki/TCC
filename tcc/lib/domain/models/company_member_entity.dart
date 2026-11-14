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
  final String cpfPessoa;
  final String cnpjEmpresa;
  final String cargo;
  final DateTime dataIngresso;

  // Dados hidratados da Pessoa para exibição direta na UI (nome, foto, CNH, etc.)
  final UserModel? user;

  const CompanyMemberModel({
    required this.id,
    required this.cpfPessoa,
    required this.cnpjEmpresa,
    required this.cargo,
    required this.dataIngresso,
    this.user,
  });

  CompanyMemberModel copyWith({
    String? id,
    String? cpfPessoa,
    String? cnpjEmpresa,
    String? cargo,
    DateTime? dataIngresso,
    UserModel? user,
  }) {
    return CompanyMemberModel(
      id: id ?? this.id,
      cpfPessoa: cpfPessoa ?? this.cpfPessoa,
      cnpjEmpresa: cnpjEmpresa ?? this.cnpjEmpresa,
      cargo: cargo ?? this.cargo,
      dataIngresso: dataIngresso ?? this.dataIngresso,
      user: user ?? this.user,
    );
  }

  factory CompanyMemberModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
    UserModel? user,
  }) {
    final rawDate = map['dataIngresso'];
    final parsedDate = rawDate is Timestamp
        ? rawDate.toDate()
        : (rawDate is DateTime ? rawDate : DateTime.now());

    final cnpj = map['cnpj_empresa'] as String? ?? '';
    final cpf = map['cpf_pessoa'] as String? ?? '';

    return CompanyMemberModel(
      id: documentId ?? map['id'] as String? ?? '${cnpj}_$cpf',
      cpfPessoa: cpf,
      cnpjEmpresa: cnpj,
      cargo: map['cargo'] as String? ?? CompanyRole.passenger,
      dataIngresso: parsedDate,
      user: user,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cpf_pessoa': cpfPessoa,
      'cnpj_empresa': cnpjEmpresa,
      'cargo': cargo,
      'dataIngresso': Timestamp.fromDate(dataIngresso),
    };
  }
}