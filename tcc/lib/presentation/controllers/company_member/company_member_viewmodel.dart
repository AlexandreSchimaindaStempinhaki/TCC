import '../../../domain/facades/company_member/i_company_member_facade.dart';
import '../../commands/company_member_commands.dart';
import 'company_member_state_viewmodel.dart';
import 'company_member_viewmodel_commands.dart';

class CompanyMemberViewModel {
  final ICompanyMemberFacade _facade;

  late final CompanyMemberState state;
  late final CompanyMemberViewModelCommands commands;

  late final FetchCompanyMembersCommand fetchCompanyMembersCommand;
  late final FetchUserMembershipsCommand fetchUserMembershipsCommand;
  late final GetMemberLinkCommand getMemberLinkCommand;
  late final AddCompanyMemberCommand addCompanyMemberCommand;
  late final ChangeCompanyMemberRoleCommand changeCompanyMemberRoleCommand;
  late final RemoveCompanyMemberCommand removeCompanyMemberCommand;

  CompanyMemberViewModel(this._facade) {
    state = CompanyMemberState();
    fetchCompanyMembersCommand = FetchCompanyMembersCommand(_facade);
    fetchUserMembershipsCommand = FetchUserMembershipsCommand(_facade);
    getMemberLinkCommand = GetMemberLinkCommand(_facade);
    addCompanyMemberCommand = AddCompanyMemberCommand(_facade);
    changeCompanyMemberRoleCommand = ChangeCompanyMemberRoleCommand(_facade);
    removeCompanyMemberCommand = RemoveCompanyMemberCommand(_facade);
    commands = CompanyMemberViewModelCommands(this);
  }
}