import 'dart:io';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../../core/failure/failure.dart';
import '../../../../core/patterns/command.dart';
import '../../../../core/patterns/result.dart';
import '../../../core/typedefs/types_defs.dart';
import '../../../domain/models/company_entity.dart';
import '../../../domain/usecases/i_company_use_cases.dart';
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

  CompanyCommands({
    required this.state,
    required CreateCompanyCommand createCompanyCommand,
    required FetchCompaniesByOwnerCommand fetchCompaniesByOwnerCommand,
    required FetchCompaniesByMemberCommand fetchCompaniesByMemberCommand,
    required UpdateCompanyCommand updateCompanyCommand,
    required UpdateCompanyLogoCommand updateCompanyLogoCommand,
    required DeleteCompanyCommand deleteCompanyCommand,
  }) : _createCompanyCommand = createCompanyCommand,
       _fetchCompaniesByOwnerCommand = fetchCompaniesByOwnerCommand,
       _fetchCompaniesByMemberCommand = fetchCompaniesByMemberCommand,
       _updateCompanyCommand = updateCompanyCommand,
       _updateCompanyLogoCommand = updateCompanyLogoCommand,
       _deleteCompanyCommand = deleteCompanyCommand {
    _observeCreateCompany();
    _observeFetchCompaniesByOwner();
    _observeFetchCompaniesByMember();
    _observeUpdateCompany();
    _observeUpdateCompanyLogo();
    _observeDeleteCompany();
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
        state.clearMessage();
      },
    );
  }

  void _observeUpdateCompanyLogo() {
    _observeCommand<String>(
      _updateCompanyLogoCommand,
      onSuccess: (logoUrl) {
        final targetCnpj = _updateCompanyLogoCommand.parameter?.cnpj;
        if (targetCnpj != null) {
          final currentList = untracked(() => state.companies.value);
          for (final comp in currentList) {
            if (comp.cnpj == targetCnpj) {
              state.updateCompanyInList(comp.copyWith(logoUrl: logoUrl));
              break;
            }
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
}
