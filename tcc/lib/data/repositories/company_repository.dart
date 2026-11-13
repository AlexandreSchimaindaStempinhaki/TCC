import 'dart:io';
import '../../../../core/typedefs/types_defs.dart';
import '../../../core/failure/failure.dart';
import '../../../core/patterns/result.dart';
import '../../domain/models/company_entity.dart';
import '../services/firebase/i_company_firebase_service.dart';
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
  Future<Result<List<CompanyModel>, Failure>> fetchCompaniesByOwner([String? ownerId]) async {
    try {
      final companies = await _remoteService.fetchCompaniesByOwner(ownerId);
      return Success(companies);
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<CompanyModel>, Failure>> fetchCompaniesByMember([String? memberId]) async {
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
  Future<Result<String, Failure>> updateCompanyLogo(String cnpj, File imageFile) async {
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
}