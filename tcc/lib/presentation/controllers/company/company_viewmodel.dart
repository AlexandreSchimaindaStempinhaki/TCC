import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/facades/company/i_company_use_case_facade.dart';
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
      updateCompanyLogoCommand: UpdateCompanyLogoCommand(_facade),
      deleteCompanyCommand: DeleteCompanyCommand(_facade),
      fetchCompanyReviewsCommand: FetchCompanyReviewsCommand(_facade),
      shouldPromptFirstTripReviewCommand: ShouldPromptFirstTripReviewCommand(
        _facade,
      ),
      dismissFirstTripReviewPromptCommand: DismissFirstTripReviewPromptCommand(
        _facade,
      ),
      rateCompanyCommand: RateCompanyCommand(_facade),
    );

    _loading = signal(false);
  }

  // --- Comandos expostos diretamente para conveniência na UI ---
  CreateCompanyCommand get createCompanyCommand =>
      _commands.createCompanyCommand;
  FetchCompaniesByOwnerCommand get fetchCompaniesByOwnerCommand =>
      _commands.fetchCompaniesByOwnerCommand;
  FetchCompaniesByMemberCommand get fetchCompaniesByMemberCommand =>
      _commands.fetchCompaniesByMemberCommand;
  UpdateCompanyCommand get updateCompanyCommand =>
      _commands.updateCompanyCommand;
  UpdateCompanyLogoCommand get updateCompanyLogoCommand =>
      _commands.updateCompanyLogoCommand;
  DeleteCompanyCommand get deleteCompanyCommand =>
      _commands.deleteCompanyCommand;
  FetchCompanyReviewsCommand get fetchCompanyReviewsCommand =>
      _commands.fetchCompanyReviewsCommand;
  ShouldPromptFirstTripReviewCommand get shouldPromptFirstTripReviewCommand =>
      _commands.shouldPromptFirstTripReviewCommand;
  DismissFirstTripReviewPromptCommand
      get dismissFirstTripReviewPromptCommand =>
          _commands.dismissFirstTripReviewPromptCommand;
  RateCompanyCommand get rateCompanyCommand => _commands.rateCompanyCommand;
}