import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/routes/indigo_routes.dart';
import '../../../domain/models/company_entity.dart';
import '../../controllers/company/company_list_viewmodel.dart';
import '../../controllers/company/company_viewmodel.dart';
import '../../views/application/configuration/company_home_view.dart';

mixin CompanyHomeMixin on State<CompanyHomeView> {
  late final CompanyViewModel companyViewModel;
  late final CompanyListViewModel companyListViewModel;

  final isInitialLoading = signal(true);
  bool isDeleting = false;

  @override
  void initState() {
    super.initState();
    companyViewModel = injector.get<CompanyViewModel>();
    companyListViewModel = injector.get<CompanyListViewModel>();

    if (widget.initialCompany != null) {
      companyViewModel.state.setSelectedCompany(widget.initialCompany);
    }

    loadCompanyData();
  }

  Future<void> loadCompanyData() async {
    isInitialLoading.value = true;
    await companyListViewModel.commands.fetchOwnedCompanies();

    final targetCnpj =
        companyViewModel.state.selectedCompany.value?.cnpj ??
        widget.initialCompany?.cnpj;

    if (targetCnpj != null) {
      final updatedList = companyListViewModel.state.ownedCompanies.value;
      for (final comp in updatedList) {
        if (comp.cnpj == targetCnpj) {
          companyViewModel.state.setSelectedCompany(comp);
          break;
        }
      }
    }

    if (mounted) {
      isInitialLoading.value = false;
    }
  }

  @override
  void dispose() {
    isInitialLoading.dispose();
    super.dispose();
  }

  String formatCnpj(String cnpj) {
    final digits = cnpj.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 14) return cnpj;
    return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.${digits.substring(5, 8)}/${digits.substring(8, 12)}-${digits.substring(12, 14)}';
  }

  String formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7, 11)}';
    } else if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6, 10)}';
    }
    return phone;
  }

  void handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(IndigoRouteNames.myCompanies);
    }
  }

  void showTopSnackBar(
    BuildContext context,
    String message, {
    Color backgroundColor = Colors.green,
    IconData icon = Icons.check_circle_outline_rounded,
  }) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomMargin = context.screenHeight - topPadding - 90;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor,
          elevation: 6,
          duration: const Duration(seconds: 2),
          margin: EdgeInsets.only(
            bottom: bottomMargin > 0 ? bottomMargin : 20,
            left: 20,
            right: 20,
          ),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  void copyToClipboard(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    showTopSnackBar(
      context,
      '$label copiado para a área de transferência!',
      backgroundColor: Colors.black87,
      icon: Icons.copy_rounded,
    );
  }

  Future<void> openEditCompany(CompanyModel company) async {
    await context.pushNamed(IndigoRouteNames.createCompany, extra: company);
    await loadCompanyData();
  }

  Future<void> confirmAndDeleteCompany(
    BuildContext context,
    CompanyModel company,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;

    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber.shade700,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('Excluir Empresa?')),
          ],
        ),
        content: Text(
          'Tem certeza que deseja excluir a empresa "${company.name}"? Esta ação não poderá ser desfeita.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (firstConfirm != true || !context.mounted) return;

    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 28,
            ),
            SizedBox(width: 8),
            Expanded(child: Text('Confirmar Exclusão?')),
          ],
        ),
        content: Text(
          'Esta confirmação é definitiva. Excluir "${company.name}" apagará permanentemente todos os dados vinculados a esta empresa. Deseja realmente excluir?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sim, Excluir'),
          ),
        ],
      ),
    );

    if (secondConfirm != true || !context.mounted) return;

    setState(() => isDeleting = true);

    final success = await companyListViewModel.commands.deleteCompanyFromList(
      company.cnpj,
    );

    if (!context.mounted) return;

    setState(() => isDeleting = false);

    showTopSnackBar(
      context,
      success
          ? 'Empresa excluída com sucesso!'
          : (companyListViewModel.state.message.value ??
                'Erro ao excluir empresa.'),
      backgroundColor: success ? Colors.green : Colors.redAccent,
      icon: success ? Icons.check_circle_outline_rounded : Icons.error_outline,
    );

    if (success) {
      companyViewModel.state.setSelectedCompany(null);
      handleBack(context);
    }
  }

  void showComingSoon(BuildContext context, String feature) {
    showTopSnackBar(
      context,
      'Módulo "$feature" pronto para integração.',
      backgroundColor: Colors.black87,
      icon: Icons.info_outline_rounded,
    );
  }
}
