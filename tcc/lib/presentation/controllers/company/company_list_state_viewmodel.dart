import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/models/company_entity.dart';

class CompanyListState {
  final companies = signal<List<CompanyModel>>([]);

  final ownedCompanies = signal<List<CompanyModel>>([]);
  final memberCompanies = signal<List<CompanyModel>>([]);

  final message = signal<String?>(null);

  bool get hasCompanies => companies.value.isNotEmpty;
  bool get hasOwnedCompanies => ownedCompanies.value.isNotEmpty;
  bool get hasMemberCompanies => memberCompanies.value.isNotEmpty;

  String _cleanCnpj(String cnpj) => cnpj.replaceAll(RegExp(r'\D'), '');

  void setCompanies(List<CompanyModel> list) {
    companies.value = list;
    message.value = null;
  }

  void setOwnedCompanies(List<CompanyModel> list) {
    ownedCompanies.value = list;
    companies.value = list;
    message.value = null;
  }

  void setMemberCompanies(List<CompanyModel> list) {
    memberCompanies.value = list;
    companies.value = list;
    message.value = null;
  }

  void updateCompanyInList(CompanyModel updatedCompany) {
    final target = _cleanCnpj(updatedCompany.cnpj);
    companies.value = companies.value
        .map((c) => _cleanCnpj(c.cnpj) == target ? updatedCompany : c)
        .toList();
    ownedCompanies.value = ownedCompanies.value
        .map((c) => _cleanCnpj(c.cnpj) == target ? updatedCompany : c)
        .toList();
    memberCompanies.value = memberCompanies.value
        .map((c) => _cleanCnpj(c.cnpj) == target ? updatedCompany : c)
        .toList();
  }

  void removeCompanyFromList(String cnpj) {
    final target = _cleanCnpj(cnpj);
    companies.value = companies.value
        .where((c) => _cleanCnpj(c.cnpj) != target)
        .toList();
    ownedCompanies.value = ownedCompanies.value
        .where((c) => _cleanCnpj(c.cnpj) != target)
        .toList();
    memberCompanies.value = memberCompanies.value
        .where((c) => _cleanCnpj(c.cnpj) != target)
        .toList();
  }

  void clearList() {
    companies.value = [];
    ownedCompanies.value = [];
    memberCompanies.value = [];
    message.value = null;
  }

  void clearMessage() => message.value = null;

  void setMessage(String msg) => message.value = msg;
}