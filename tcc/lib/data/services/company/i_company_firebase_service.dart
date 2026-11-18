import 'dart:io';
import '../../../domain/models/company_entity.dart';
import '../../../domain/models/company_review_entity.dart';

abstract interface class ICompanyRemoteService {
  Future<void> createCompany(CompanyModel company);
  Future<List<CompanyModel>> fetchCompaniesByOwner([String? ownerId]);
  Future<List<CompanyModel>> fetchCompaniesByMember([String? memberId]);
  Future<void> updateCompany(CompanyModel company);
  Future<String> uploadCompanyLogo(String cnpj, File imageFile);
  Future<void> deleteCompany(String cnpj);

  Future<List<CompanyReviewModel>> fetchCompanyReviews(String cnpj);

  Future<CompanyReviewModel?> getUserCompanyReview({
    required String cnpj,
    required String userId,
  });

  Future<bool> shouldPromptFirstTripReview({
    required String cnpj,
    required String userId,
  });

  Future<void> dismissFirstTripReviewPrompt({
    required String cnpj,
    required String userId,
  });

  Future<CompanyModel> rateCompany({
    required String cnpj,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required double rating,
    String? description,
  });
}
