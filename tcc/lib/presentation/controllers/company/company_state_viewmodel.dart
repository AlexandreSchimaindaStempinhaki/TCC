import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/models/company_entity.dart';
import '../../../domain/models/company_review_entity.dart';

class CompanyState {
  final companies = signal<List<CompanyModel>>([]);
  final selectedCompany = signal<CompanyModel?>(null);
  final companyReviews = signal<List<CompanyReviewModel>>([]);
  final message = signal<String?>(null);

  String _cleanCnpj(String cnpj) => cnpj.replaceAll(RegExp(r'\D'), '');

  void setCompanies(List<CompanyModel> newCompanies) {
    companies.value = newCompanies;
    message.value = null;
  }

  void setSelectedCompany(CompanyModel? company) {
    selectedCompany.value = company;
  }

  void setCompanyReviews(List<CompanyReviewModel> reviews) {
    companyReviews.value = reviews;
    message.value = null;
  }

  CompanyReviewModel? getReviewByUser(String userId) {
    final trimmed = userId.trim();
    if (trimmed.isEmpty) return null;
    for (final review in companyReviews.value) {
      if (review.userId.trim() == trimmed) return review;
    }
    return null;
  }

  void addCompany(CompanyModel company) {
    companies.value = [...companies.value, company];
    selectedCompany.value = company;
  }

  void updateCompanyInList(CompanyModel updatedCompany) {
    final targetCnpj = _cleanCnpj(updatedCompany.cnpj);

    companies.value = companies.value.map((comp) {
      return _cleanCnpj(comp.cnpj) == targetCnpj ? updatedCompany : comp;
    }).toList();

    final currentSelected = selectedCompany.value;
    if (currentSelected == null ||
        _cleanCnpj(currentSelected.cnpj) == targetCnpj) {
      selectedCompany.value = updatedCompany;
    }
  }

  void removeCompany(String cnpj) {
    final targetCnpj = _cleanCnpj(cnpj);
    companies.value = companies.value
        .where((comp) => _cleanCnpj(comp.cnpj) != targetCnpj)
        .toList();

    if (selectedCompany.value != null &&
        _cleanCnpj(selectedCompany.value!.cnpj) == targetCnpj) {
      selectedCompany.value = null;
    }
  }

  void clearMessage() => message.value = null;
  void setMessage(String msg) => message.value = msg;
}