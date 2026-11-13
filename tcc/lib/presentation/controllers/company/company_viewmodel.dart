import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/facades/i_company_use_case_facade.dart';
import '../../commands/company_commands.dart';
import 'company_commands_viewmodel.dart';
import 'company_state_viewmodel.dart';

class CompanyViewModel {
  final ICompanyUseCaseFacade _facade;

  late final CompanyState _state;
  late final CompanyCommands _commands;
  late final Signal<bool> _loading;

  CompanyState get state => _state;
  CompanyCommands get commands => _commands;
  ReadonlySignal<bool> get loading => _loading.readonly();

  CompanyViewModel(this._facade) {
    _state = CompanyState();

    _commands = CompanyCommands(
      state: _state,
      createCompanyCommand: CreateCompanyCommand(_facade),
      fetchCompaniesByOwnerCommand: FetchCompaniesByOwnerCommand(_facade),
      fetchCompaniesByMemberCommand: FetchCompaniesByMemberCommand(_facade),
      updateCompanyCommand: UpdateCompanyCommand(_facade),
      deleteCompanyCommand: DeleteCompanyCommand(_facade),
    );

    _loading = signal(false);
  }

  CreateCompanyCommand get createCompanyCommand => _commands.createCompanyCommand;
  FetchCompaniesByOwnerCommand get fetchCompaniesByOwnerCommand => _commands.fetchCompaniesByOwnerCommand;
  FetchCompaniesByMemberCommand get fetchCompaniesByMemberCommand => _commands.fetchCompaniesByMemberCommand;
  UpdateCompanyCommand get updateCompanyCommand => _commands.updateCompanyCommand;
  DeleteCompanyCommand get deleteCompanyCommand => _commands.deleteCompanyCommand;
}