import 'package:signals_flutter/signals_flutter.dart';
import '../../../../core/failure/failure.dart';
import '../../../../core/patterns/command.dart';
import '../../../core/typedefs/types_defs.dart';
import '../../../domain/models/company_entity.dart';
import '../../../domain/usecases/i_company_use_cases.dart';
import '../../commands/company_commands.dart';
import 'company_list_state_viewmodel.dart';

class CompanyListCommands {
  final CompanyListState state;
  final FetchCompaniesByOwnerCommand _fetchCompaniesByOwnerCommand;
  final FetchCompaniesByMemberCommand _fetchCompaniesByMemberCommand;
  final DeleteCompanyCommand _deleteCompanyCommand;

  CompanyListCommands({
    required this.state,
    required FetchCompaniesByOwnerCommand fetchCompaniesByOwnerCommand,
    required FetchCompaniesByMemberCommand fetchCompaniesByMemberCommand,
    required DeleteCompanyCommand deleteCompanyCommand,
  }) : _fetchCompaniesByOwnerCommand = fetchCompaniesByOwnerCommand,
       _fetchCompaniesByMemberCommand = fetchCompaniesByMemberCommand,
       _deleteCompanyCommand = deleteCompanyCommand {
    _observeFetchCompaniesByOwner();
    _observeFetchCompaniesByMember();
    _observeDeleteCompany();
  }

  // ========================================================
  //   GETTERS PARA WIDGETS USAREM DIRETAMENTE OS COMANDOS
  // ========================================================
  FetchCompaniesByOwnerCommand get fetchCompaniesByOwnerCommand =>
      _fetchCompaniesByOwnerCommand;
  FetchCompaniesByMemberCommand get fetchCompaniesByMemberCommand =>
      _fetchCompaniesByMemberCommand;
  DeleteCompanyCommand get deleteCompanyCommand => _deleteCompanyCommand;

  // ========================================================
  //   MÉTODOS PÚBLICOS (CHAMADOS PELOS WIDGETS)
  // ========================================================
  Future<void> fetchOwnedCompanies([String? ownerId]) async {
    if (_fetchCompaniesByOwnerCommand.isExecuting.value) return;

    state.clearMessage();
    await _fetchCompaniesByOwnerCommand.executeWith(
      FetchCompaniesByOwnerParams(ownerId: ownerId),
    );
  }

  Future<void> fetchMemberCompanies([String? memberId]) async {
    if (_fetchCompaniesByMemberCommand.isExecuting.value) return;

    state.clearMessage();
    await _fetchCompaniesByMemberCommand.executeWith(
      FetchCompaniesByMemberParams(memberId: memberId),
    );
  }

  Future<bool> deleteCompanyFromList(String cnpj) async {
    state.clearMessage();
    final result = await _deleteCompanyCommand.executeWith(
      DeleteCompanyParams(cnpj: cnpj),
    );

    if (result.isSuccess) {
      state.removeCompanyFromList(cnpj);
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
  void _observeFetchCompaniesByOwner() {
    _observeCommand<List<CompanyModel>>(
      _fetchCompaniesByOwnerCommand,
      onSuccess: (companies) {
        state.setOwnedCompanies(companies);
      },
    );
  }

  void _observeFetchCompaniesByMember() {
    _observeCommand<List<CompanyModel>>(
      _fetchCompaniesByMemberCommand,
      onSuccess: (companies) {
        state.setMemberCompanies(companies);
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
