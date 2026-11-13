import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/facades/i_company_use_case_facade.dart';
import '../../commands/company_commands.dart';
import 'company_list_commands_viewmodel.dart';
import 'company_list_state_viewmodel.dart';

class CompanyListViewModel {
  final ICompanyUseCaseFacade _facade;

  late final CompanyListState _state;
  late final CompanyListCommands _commands;
  late final Signal<bool> _loading;

  CompanyListState get state => _state;
  CompanyListCommands get commands => _commands;
  ReadonlySignal<bool> get loading => _loading.readonly();

  CompanyListViewModel(this._facade) {
    _state = CompanyListState();

    _commands = CompanyListCommands(
      state: _state,
      fetchCompaniesByOwnerCommand: FetchCompaniesByOwnerCommand(_facade),
      fetchCompaniesByMemberCommand: FetchCompaniesByMemberCommand(_facade),
      deleteCompanyCommand: DeleteCompanyCommand(_facade),
    );

    _loading = signal(false);
  }

  FetchCompaniesByOwnerCommand get fetchCompaniesByOwnerCommand =>
      _commands.fetchCompaniesByOwnerCommand;
  FetchCompaniesByMemberCommand get fetchCompaniesByMemberCommand =>
      _commands.fetchCompaniesByMemberCommand;
  DeleteCompanyCommand get deleteCompanyCommand =>
      _commands.deleteCompanyCommand;
}