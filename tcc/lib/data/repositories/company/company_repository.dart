import 'dart:io';
import '../../../../../core/typedefs/types_defs.dart';
import '../../../../core/failure/failure.dart';
import '../../../../core/patterns/result.dart';
import '../../../domain/models/company_entity.dart';
import '../../../domain/models/company_review_entity.dart';
import '../../services/company/i_company_firebase_service.dart';
import 'i_company_repository.dart';

final class CompanyRepositoryImpl implements ICompanyRepository {
  final ICompanyRemoteService _remoteService;

  CompanyRepositoryImpl({required ICompanyRemoteService remoteService})
    : _remoteService = remoteService;

  @override
  Future<VoidResult> createCompany(CompanyModel company) async {
    try {
      await _remoteService.createCompany(company);
      return const Success(null);
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<CompanyModel>, Failure>> fetchCompaniesByOwner([
    String? ownerId,
  ]) async {
    try {
      final companies = await _remoteService.fetchCompaniesByOwner(ownerId);
      return Success(companies);
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<CompanyModel>, Failure>> fetchCompaniesByMember([
    String? memberId,
  ]) async {
    try {
      final companies = await _remoteService.fetchCompaniesByMember(memberId);
      return Success(companies);
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }

  @override
  Future<VoidResult> updateCompany(CompanyModel company) async {
    try {
      await _remoteService.updateCompany(company);
      return const Success(null);
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }

  @override
  Future<Result<String, Failure>> updateCompanyLogo(
    String cnpj,
    File imageFile,
  ) async {
    try {
      final logoUrl = await _remoteService.uploadCompanyLogo(cnpj, imageFile);
      return Success(logoUrl);
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }

  @override
  Future<VoidResult> deleteCompany(String cnpj) async {
    try {
      await _remoteService.deleteCompany(cnpj);
      return const Success(null);
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<CompanyReviewModel>, Failure>> fetchCompanyReviews(
    String cnpj,
  ) async {
    try {
      final reviews = await _remoteService.fetchCompanyReviews(cnpj);
      return Success(reviews);
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }

  @override
  Future<Result<CompanyReviewModel?, Failure>> getUserCompanyReview({
    required String cnpj,
    required String userId,
  }) async {
    try {
      final review = await _remoteService.getUserCompanyReview(
        cnpj: cnpj,
        userId: userId,
      );
      return Success(review);
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }

  @override
  Future<Result<bool, Failure>> shouldPromptFirstTripReview({
    required String cnpj,
    required String userId,
  }) async {
    try {
      final shouldPrompt = await _remoteService.shouldPromptFirstTripReview(
        cnpj: cnpj,
        userId: userId,
      );
      return Success(shouldPrompt);
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }

  @override
  Future<VoidResult> dismissFirstTripReviewPrompt({
    required String cnpj,
    required String userId,
  }) async {
    try {
      await _remoteService.dismissFirstTripReviewPrompt(
        cnpj: cnpj,
        userId: userId,
      );
      return const Success(null);
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }

  @override
  Future<Result<CompanyModel, Failure>> rateCompany({
    required String cnpj,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required double rating,
    String? description,
  }) async {
    try {
      final updatedCompany = await _remoteService.rateCompany(
        cnpj: cnpj,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        rating: rating,
        description: description,
      );
      return Success(updatedCompany);
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }
}