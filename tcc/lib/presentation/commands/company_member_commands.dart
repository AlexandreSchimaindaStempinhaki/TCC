import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/facades/company_member/i_company_member_facade.dart';
import '../../../domain/models/company_member_entity.dart';

class FetchCompanyMembersCommand {
  final ICompanyMemberFacade _facade;
  final isExecuting = signal(false);

  FetchCompanyMembersCommand(this._facade);

  Future<List<CompanyMemberModel>> execute(String companyCnpj) async {
    isExecuting.value = true;
    try {
      return await _facade.fetchCompanyMembers(companyCnpj);
    } finally {
      isExecuting.value = false;
    }
  }
}

class FetchUserMembershipsCommand {
  final ICompanyMemberFacade _facade;
  final isExecuting = signal(false);

  FetchUserMembershipsCommand(this._facade);

  Future<List<CompanyMemberModel>> execute(String cpfOrUid) async {
    isExecuting.value = true;
    try {
      return await _facade.fetchUserMemberships(cpfOrUid);
    } finally {
      isExecuting.value = false;
    }
  }
}

class GetMemberLinkCommand {
  final ICompanyMemberFacade _facade;
  final isExecuting = signal(false);

  GetMemberLinkCommand(this._facade);

  Future<CompanyMemberModel?> execute(
    String companyCnpj,
    String cpfOrUid,
  ) async {
    isExecuting.value = true;
    try {
      return await _facade.getMemberLink(companyCnpj, cpfOrUid);
    } finally {
      isExecuting.value = false;
    }
  }
}

class AddCompanyMemberCommand {
  final ICompanyMemberFacade _facade;
  final isExecuting = signal(false);

  AddCompanyMemberCommand(this._facade);

  Future<CompanyMemberModel> execute(CompanyMemberModel member) async {
    isExecuting.value = true;
    try {
      return await _facade.addMember(member);
    } finally {
      isExecuting.value = false;
    }
  }
}

class ChangeCompanyMemberRoleCommand {
  final ICompanyMemberFacade _facade;
  final isExecuting = signal(false);

  ChangeCompanyMemberRoleCommand(this._facade);

  Future<void> execute({
    required String companyCnpj,
    required String userCpf,
    required String newRole,
  }) async {
    isExecuting.value = true;
    try {
      await _facade.changeMemberRole(
        companyCnpj: companyCnpj,
        userCpf: userCpf,
        newRole: newRole,
      );
    } finally {
      isExecuting.value = false;
    }
  }
}

class RemoveCompanyMemberCommand {
  final ICompanyMemberFacade _facade;
  final isExecuting = signal(false);

  RemoveCompanyMemberCommand(this._facade);

  Future<void> execute({
    required String companyCnpj,
    required String userCpf,
  }) async {
    isExecuting.value = true;
    try {
      await _facade.removeMember(
        companyCnpj: companyCnpj,
        userCpf: userCpf,
      );
    } finally {
      isExecuting.value = false;
    }
  }
}