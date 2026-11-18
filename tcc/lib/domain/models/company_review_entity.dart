class CompanyReviewModel {
  final String id;
  final String companyCnpj;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final double rating;
  final String? description;
  final DateTime createdAt;

  const CompanyReviewModel({
    required this.id,
    required this.companyCnpj,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    this.description,
    required this.createdAt,
  });

  CompanyReviewModel copyWith({
    String? id,
    String? companyCnpj,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    double? rating,
    String? description,
    DateTime? createdAt,
  }) {
    return CompanyReviewModel(
      id: id ?? this.id,
      companyCnpj: companyCnpj ?? this.companyCnpj,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      rating: rating ?? this.rating,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}