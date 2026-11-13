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

  void removeCompanyFromList(String cnpj) {
    companies.value = companies.value.where((c) => c.cnpj != cnpj).toList();
    ownedCompanies.value =
        ownedCompanies.value.where((c) => c.cnpj != cnpj).toList();
    memberCompanies.value =
        memberCompanies.value.where((c) => c.cnpj != cnpj).toList();
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