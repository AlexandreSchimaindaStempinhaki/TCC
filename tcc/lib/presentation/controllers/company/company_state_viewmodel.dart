import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/models/company_entity.dart';

class CompanyState {
  final companies = signal<List<CompanyModel>>([]);
  final selectedCompany = signal<CompanyModel?>(null);
  final message = signal<String?>(null);

  bool get hasCompanies => companies.value.isNotEmpty;

  void setCompanies(List<CompanyModel> companyList) {
    companies.value = companyList;
    message.value = null;
  }

  void setSelectedCompany(CompanyModel? company) {
    selectedCompany.value = company;
  }

  void addCompany(CompanyModel company) {
    companies.value = [...companies.value, company];
    message.value = null;
  }

  void updateCompanyInList(CompanyModel updatedCompany) {
    companies.value = companies.value.map((comp) {
      return comp.cnpj == updatedCompany.cnpj ? updatedCompany : comp;
    }).toList();

    if (selectedCompany.value?.cnpj == updatedCompany.cnpj) {
      selectedCompany.value = updatedCompany;
    }
  }

  void removeCompany(String cnpj) {
    companies.value = companies.value.where((comp) => comp.cnpj != cnpj).toList();
    if (selectedCompany.value?.cnpj == cnpj) {
      selectedCompany.value = null;
    }
  }

  void clearState() {
    companies.value = [];
    selectedCompany.value = null;
    message.value = null;
  }

  void clearMessage() => message.value = null;

  void setMessage(String msg) => message.value = msg;
}