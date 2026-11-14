import '../../../domain/models/company_member_entity.dart';
import 'company_member_viewmodel.dart';

class CompanyMemberViewModelCommands {
  final CompanyMemberViewModel _viewModel;

  CompanyMemberViewModelCommands(this._viewModel);

  Future<void> fetchCompanyMembers(String cnpjEmpresa) async {
    _viewModel.state.clearMessage();
    try {
      final result = await _viewModel.fetchCompanyMembersCommand.execute(
        cnpjEmpresa,
      );
      _viewModel.state.members.value = result;
    } catch (e) {
      _viewModel.state.message.value =
          'Erro ao carregar membros da empresa: $e';
    }
  }

  Future<void> fetchUserMemberships(String cpfOrUid) async {
    _viewModel.state.clearMessage();
    try {
      final result = await _viewModel.fetchUserMembershipsCommand.execute(
        cpfOrUid,
      );
      _viewModel.state.userMemberships.value = result;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao carregar seus vínculos: $e';
    }
  }

  Future<CompanyMemberModel?> loadCurrentUserRole({
    required String cnpjEmpresa,
    required String cpfOrUid,
  }) async {
    try {
      final link = await _viewModel.getMemberLinkCommand.execute(
        cnpjEmpresa,
        cpfOrUid,
      );
      _viewModel.state.currentUserLink.value = link;
      return link;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao verificar permissão: $e';
      return null;
    }
  }

  Future<bool> addMember({
    required String cnpjEmpresa,
    required String cpfPessoa,
    String cargo = CompanyRole.passenger,
  }) async {
    _viewModel.state.clearMessage();
    try {
      final newMember = CompanyMemberModel(
        id: '${cnpjEmpresa}_$cpfPessoa',
        cpfPessoa: cpfPessoa,
        cnpjEmpresa: cnpjEmpresa,
        cargo: cargo,
        dataIngresso: DateTime.now(),
      );

      final created = await _viewModel.addCompanyMemberCommand.execute(
        newMember,
      );

      final currentList = _viewModel.state.members.value;
      final exists = currentList.any((m) => m.cpfPessoa == cpfPessoa);
      if (exists) {
        _viewModel.state.members.value = currentList
            .map((m) => m.cpfPessoa == cpfPessoa ? created : m)
            .toList();
      } else {
        _viewModel.state.members.value = [...currentList, created];
      }

      return true;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao vincular membro: $e';
      return false;
    }
  }

  Future<bool> changeMemberRole({
    required String cnpjEmpresa,
    required String cpfPessoa,
    required String newRole,
  }) async {
    _viewModel.state.clearMessage();
    try {
      await _viewModel.changeCompanyMemberRoleCommand.execute(
        cnpjEmpresa: cnpjEmpresa,
        cpfPessoa: cpfPessoa,
        newRole: newRole,
      );

      _viewModel.state.members.value = _viewModel.state.members.value.map((m) {
        if (m.cpfPessoa == cpfPessoa) {
          return m.copyWith(cargo: newRole);
        }
        return m;
      }).toList();

      return true;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao alterar cargo: $e';
      return false;
    }
  }

  Future<bool> removeMember({
    required String cnpjEmpresa,
    required String cpfPessoa,
  }) async {
    _viewModel.state.clearMessage();
    try {
      await _viewModel.removeCompanyMemberCommand.execute(
        cnpjEmpresa: cnpjEmpresa,
        cpfPessoa: cpfPessoa,
      );

      _viewModel.state.members.value = _viewModel.state.members.value
          .where((m) => m.cpfPessoa != cpfPessoa)
          .toList();

      return true;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao remover membro: $e';
      return false;
    }
  }
}