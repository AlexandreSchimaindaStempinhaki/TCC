import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? cpf;
  final String name;
  final String email;
  final String? phone;
  final DateTime? birthDate;
  final GeoPoint? boardingPoint;
  final GeoPoint? disembarkationPoint;
  final String? driverLicense;
  final String? photoUrl;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.cpf,
    this.phone,
    this.birthDate,
    this.boardingPoint,
    this.disembarkationPoint,
    this.driverLicense,
    this.photoUrl,
  });

  // Converte do Firestore para o Objeto Dart de forma segura contra nulos
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: map['uid'] ?? documentId,
      cpf: map['cpf'],
      name: map['name'] ?? map['nome'] ?? '', // Suporta legado caso já tenha algo salvo como 'nome'
      email: map['email'] ?? '',
      phone: map['phone'] ?? map['telefone'],
      birthDate: map['birthDate'] != null 
          ? (map['birthDate'] as Timestamp).toDate() 
          : (map['dataNascimento'] != null ? (map['dataNascimento'] as Timestamp).toDate() : null),
      boardingPoint: map['boardingPoint'] ?? map['pontoEmbarque'] as GeoPoint?,
      disembarkationPoint: map['disembarkationPoint'] ?? map['pontoDesembarque'] as GeoPoint?,
      driverLicense: map['driverLicense'] ?? map['carteiraMotorista'],
      photoUrl: map['photoUrl'] ?? map['fotoUrl'],
    );
  }

  // Converte do Objeto Dart para o Firestore (tratando datas nulas com segurança)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'cpf': cpf,
      'name': name,
      'email': email,
      'phone': phone,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'boardingPoint': boardingPoint,
      'disembarkationPoint': disembarkationPoint,
      'driverLicense': driverLicense,
      'photoUrl': photoUrl,
    };
  }

  // Permite clonar o objeto alterando apenas campos específicos
  UserModel copyWith({
    String? uid,
    String? cpf,
    String? name,
    String? email,
    String? phone,
    DateTime? birthDate,
    GeoPoint? boardingPoint,
    GeoPoint? disembarkationPoint,
    String? driverLicense,
    String? photoUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      cpf: cpf ?? this.cpf,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      boardingPoint: boardingPoint ?? this.boardingPoint,
      disembarkationPoint: disembarkationPoint ?? this.disembarkationPoint,
      driverLicense: driverLicense ?? this.driverLicense,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}