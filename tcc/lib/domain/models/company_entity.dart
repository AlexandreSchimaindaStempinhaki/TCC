class CompanyModel {
  final String ownerId;
  final String cnpj;
  final String name;
  final String email;
  final String phone;
  final double rating;
  final int ratingCount;
  final String? logoUrl;
  final List<String> memberIds;

  const CompanyModel({
    required this.ownerId,
    required this.cnpj,
    required this.name,
    required this.email,
    required this.phone,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.logoUrl,
    this.memberIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'cnpj': cnpj,
      'name': name,
      'email': email,
      'phone': phone,
      'rating': rating,
      'ratingCount': ratingCount,
      'logoUrl': logoUrl,
      'memberIds': memberIds,
    };
  }

  factory CompanyModel.fromMap(Map<String, dynamic> map, [String? documentId]) {
    return CompanyModel(
      ownerId: map['ownerId'] ?? '',
      cnpj: documentId ?? map['cnpj'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      ratingCount: (map['ratingCount'] ?? 0).toInt(),
      logoUrl: map['logoUrl'],
      memberIds: List<String>.from(map['memberIds'] ?? []),
    );
  }

  CompanyModel copyWith({
    String? ownerId,
    String? cnpj,
    String? name,
    String? email,
    String? phone,
    double? rating,
    int? ratingCount,
    String? logoUrl,
    List<String>? memberIds,
  }) {
    return CompanyModel(
      ownerId: ownerId ?? this.ownerId,
      cnpj: cnpj ?? this.cnpj,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      logoUrl: logoUrl ?? this.logoUrl,
      memberIds: memberIds ?? this.memberIds,
    );
  }
}