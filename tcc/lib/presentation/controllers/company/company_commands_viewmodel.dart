import 'dart:io';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../../core/failure/failure.dart';
import '../../../../core/patterns/command.dart';
import '../../../core/typedefs/types_defs.dart';
import '../../../domain/models/company_entity.dart';
import '../../../domain/models/company_review_entity.dart';
import '../../commands/company_commands.dart';
import 'company_state_viewmodel.dart';

class CompanyCommands {
  final CompanyState state;
  final CreateCompanyCommand _createCompanyCommand;
  final FetchCompaniesByOwnerCommand _fetchCompaniesByOwnerCommand;
  final FetchCompaniesByMemberCommand _fetchCompaniesByMemberCommand;
  final UpdateCompanyCommand _updateCompanyCommand;
  final UpdateCompanyLogoCommand _updateCompanyLogoCommand;
  final DeleteCompanyCommand _deleteCompanyCommand;
  final FetchCompanyReviewsCommand _fetchCompanyReviewsCommand;
  final ShouldPromptFirstTripReviewCommand _shouldPromptFirstTripReviewCommand;
  final DismissFirstTripReviewPromptCommand
      _dismissFirstTripReviewPromptCommand;
  final RateCompanyCommand _rateCompanyCommand;

  CompanyCommands({
    required this.state,
    required CreateCompanyCommand createCompanyCommand,
    required FetchCompaniesByOwnerCommand fetchCompaniesByOwnerCommand,
    required FetchCompaniesByMemberCommand fetchCompaniesByMemberCommand,
    required UpdateCompanyCommand updateCompanyCommand,
    required UpdateCompanyLogoCommand updateCompanyLogoCommand,
    required DeleteCompanyCommand deleteCompanyCommand,
    required FetchCompanyReviewsCommand fetchCompanyReviewsCommand,
    required ShouldPromptFirstTripReviewCommand
        shouldPromptFirstTripReviewCommand,
    required DismissFirstTripReviewPromptCommand
        dismissFirstTripReviewPromptCommand,
    required RateCompanyCommand rateCompanyCommand,
  }) : _createCompanyCommand = createCompanyCommand,
       _fetchCompaniesByOwnerCommand = fetchCompaniesByOwnerCommand,
       _fetchCompaniesByMemberCommand = fetchCompaniesByMemberCommand,
       _updateCompanyCommand = updateCompanyCommand,
       _updateCompanyLogoCommand = updateCompanyLogoCommand,
       _deleteCompanyCommand = deleteCompanyCommand,
       _fetchCompanyReviewsCommand = fetchCompanyReviewsCommand,
       _shouldPromptFirstTripReviewCommand =
           shouldPromptFirstTripReviewCommand,
       _dismissFirstTripReviewPromptCommand =
           dismissFirstTripReviewPromptCommand,
       _rateCompanyCommand = rateCompanyCommand {
    _observeCreateCompany();
    _observeFetchCompaniesByOwner();
    _observeFetchCompaniesByMember();
    _observeUpdateCompany();
    _observeUpdateCompanyLogo();
    _observeDeleteCompany();
    _observeFetchCompanyReviews();
    _observeRateCompany();
  }

  // ========================================================
  //   GETTERS PARA WIDGETS USAREM DIRETAMENTE OS COMANDOS
  // ========================================================
  CreateCompanyCommand get createCompanyCommand => _createCompanyCommand;
  FetchCompaniesByOwnerCommand get fetchCompaniesByOwnerCommand =>
      _fetchCompaniesByOwnerCommand;
  FetchCompaniesByMemberCommand get fetchCompaniesByMemberCommand =>
      _fetchCompaniesByMemberCommand;
  UpdateCompanyCommand get updateCompanyCommand => _updateCompanyCommand;
  UpdateCompanyLogoCommand get updateCompanyLogoCommand =>
      _updateCompanyLogoCommand;
  DeleteCompanyCommand get deleteCompanyCommand => _deleteCompanyCommand;
  FetchCompanyReviewsCommand get fetchCompanyReviewsCommand =>
      _fetchCompanyReviewsCommand;
  ShouldPromptFirstTripReviewCommand get shouldPromptFirstTripReviewCommand =>
      _shouldPromptFirstTripReviewCommand;
  DismissFirstTripReviewPromptCommand
      get dismissFirstTripReviewPromptCommand =>
          _dismissFirstTripReviewPromptCommand;
  RateCompanyCommand get rateCompanyCommand => _rateCompanyCommand;

  // ========================================================
  //   MÉTODOS PÚBLICOS (CHAMADOS PELOS WIDGETS)
  // ========================================================
  Future<bool> createCompany(CompanyModel company) async {
    state.clearMessage();
    final result = await _createCompanyCommand.executeWith(
      CreateCompanyParams(company: company),
    );

    if (result.isSuccess) {
      Future.microtask(() {
        state.addCompany(company);
      });
      return true;
    }
    return false;
  }

  Future<void> fetchCompaniesByOwner([String? ownerId]) async {
    state.clearMessage();
    await _fetchCompaniesByOwnerCommand.executeWith(
      FetchCompaniesByOwnerParams(ownerId: ownerId),
    );
  }

  Future<void> fetchCompaniesByMember([String? memberId]) async {
    state.clearMessage();
    await _fetchCompaniesByMemberCommand.executeWith(
      FetchCompaniesByMemberParams(memberId: memberId),
    );
  }

  Future<bool> updateCompany(CompanyModel company) async {
    state.clearMessage();
    final result = await _updateCompanyCommand.executeWith(
      UpdateCompanyParams(company: company),
    );

    if (result.isSuccess) {
      Future.microtask(() {
        state.updateCompanyInList(company);
      });
      return true;
    }
    return false;
  }

  Future<void> updateCompanyLogo(String cnpj, File imageFile) async {
    state.clearMessage();
    await _updateCompanyLogoCommand.executeWith(
      UpdateCompanyLogoParams(cnpj: cnpj, imageFile: imageFile),
    );
  }

  Future<bool> deleteCompany(String cnpj) async {
    state.clearMessage();
    final result = await _deleteCompanyCommand.executeWith(
      DeleteCompanyParams(cnpj: cnpj),
    );

    if (result.isSuccess) {
      state.removeCompany(cnpj);
      return true;
    }
    return false;
  }

  Future<void> fetchCompanyReviews(String cnpj) async {
    state.clearMessage();
    await _fetchCompanyReviewsCommand.executeWith(
      FetchCompanyReviewsParams(cnpj: cnpj),
    );
  }

  Future<bool> shouldPromptFirstTripReview({
    required String cnpj,
    required String userId,
  }) async {
    final result = await _shouldPromptFirstTripReviewCommand.executeWith(
      CheckFirstTripReviewParams(cnpj: cnpj, userId: userId),
    );
    return result.fold(
      onSuccess: (shouldPrompt) => shouldPrompt,
      onFailure: (_) => false,
    );
  }

  Future<void> dismissFirstTripReviewPrompt({
    required String cnpj,
    required String userId,
  }) async {
    await _dismissFirstTripReviewPromptCommand.executeWith(
      CheckFirstTripReviewParams(cnpj: cnpj, userId: userId),
    );
  }

  Future<bool> rateCompany({
    required String cnpj,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required double rating,
    String? description,
  }) async {
    state.clearMessage();
    final result = await _rateCompanyCommand.executeWith(
      RateCompanyParams(
        cnpj: cnpj,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        rating: rating,
        description: description,
      ),
    );

    if (result.isSuccess) {
      await fetchCompanyReviews(cnpj);
      return true;
    }
    return false;
  }

  // ========================================================
  //   MÉTODO GENÉRICO DE OBSERVAÇÃO DE COMANDOS
  // ========================================================
  void _observeCommand<T>(
    Command<T, Failure> command, {
    required void Function(T data) onSuccess,
    void Function(Failure err)? onFailure,
  }) {
    effect(() {
      if (command.isExecuting.value) return;

      final result = command.result.value;
      if (result == null) return;

      untracked(() {
        result.fold(
          onSuccess: (data) {
            state.clearMessage();
            onSuccess(data);
          },
          onFailure: (err) {
            state.setMessage(err.msg);
            if (onFailure != null) onFailure(err);
          },
        );
      });
    });
  }

  // ========================================================
  //   OBSERVERS ESPECÍFICOS
  // ========================================================
  void _observeCreateCompany() {
    _observeCommand<void>(
      _createCompanyCommand,
      onSuccess: (_) {
        state.clearMessage();
      },
    );
  }

  void _observeFetchCompaniesByOwner() {
    _observeCommand<List<CompanyModel>>(
      _fetchCompaniesByOwnerCommand,
      onSuccess: (companies) {
        state.setCompanies(companies);
      },
    );
  }

  void _observeFetchCompaniesByMember() {
    _observeCommand<List<CompanyModel>>(
      _fetchCompaniesByMemberCommand,
      onSuccess: (companies) {
        state.setCompanies(companies);
      },
    );
  }

  void _observeUpdateCompany() {
    _observeCommand<void>(
      _updateCompanyCommand,
      onSuccess: (_) {
        final updatedCompany = _updateCompanyCommand.parameter?.company;
        if (updatedCompany != null) {
          state.updateCompanyInList(updatedCompany);
        }
        state.clearMessage();
      },
    );
  }

  void _observeUpdateCompanyLogo() {
    _observeCommand<String>(
      _updateCompanyLogoCommand,
      onSuccess: (logoUrl) {
        final targetCnpj = _updateCompanyLogoCommand.parameter?.cnpj;
        if (targetCnpj == null) return;

        final cleanTarget = targetCnpj.replaceAll(RegExp(r'\D'), '');
        final currentSelected = untracked(() => state.selectedCompany.value);

        if (currentSelected != null &&
            currentSelected.cnpj.replaceAll(RegExp(r'\D'), '') == cleanTarget) {
          state.updateCompanyInList(currentSelected.copyWith(logoUrl: logoUrl));
          return;
        }

        final currentList = untracked(() => state.companies.value);
        for (final comp in currentList) {
          if (comp.cnpj.replaceAll(RegExp(r'\D'), '') == cleanTarget) {
            state.updateCompanyInList(comp.copyWith(logoUrl: logoUrl));
            break;
          }
        }
      },
    );
  }

  void _observeDeleteCompany() {
    _observeCommand<void>(
      _deleteCompanyCommand,
      onSuccess: (_) {
        state.clearMessage();
      },
    );
  }

  void _observeFetchCompanyReviews() {
    _observeCommand<List<CompanyReviewModel>>(
      _fetchCompanyReviewsCommand,
      onSuccess: (reviews) {
        state.setCompanyReviews(reviews);
      },
    );
  }

  void _observeRateCompany() {
    _observeCommand<CompanyModel>(
      _rateCompanyCommand,
      onSuccess: (updatedCompany) {
        state.updateCompanyInList(updatedCompany);
      },
    );
  }
}