import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/routes/indigo_routes.dart';
import '../../../../domain/models/company_entity.dart';
import '../../../controllers/company/company_list_viewmodel.dart';
import '../../../controllers/company/company_viewmodel.dart';
import '../../../widgets/animated_three_dots.dart';
import '../../../widgets/company_card.dart';

class MyCompaniesView extends StatefulWidget {
  const MyCompaniesView({super.key});

  @override
  State<MyCompaniesView> createState() => _MyCompaniesViewState();
}

class _MyCompaniesViewState extends State<MyCompaniesView> {
  late final CompanyListViewModel _companyListViewModel;
  late final CompanyViewModel _companyViewModel;

  final _isInitialLoading = signal(true);

  @override
  void initState() {
    super.initState();
    _companyListViewModel = injector.get<CompanyListViewModel>();
    _companyViewModel = injector.get<CompanyViewModel>();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    _isInitialLoading.value = true;
    await _companyListViewModel.commands.fetchOwnedCompanies();
    if (mounted) {
      _isInitialLoading.value = false;
    }
  }

  @override
  void dispose() {
    _isInitialLoading.dispose();
    super.dispose();
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(IndigoRouteNames.account);
    }
  }

  Future<bool> _confirmAndDeleteCompany(
    BuildContext context,
    CompanyModel company,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;

    // ================= 1ª CONFIRMAÇÃO (AMARELO) =================
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

    if (firstConfirm != true || !context.mounted) return false;

    // ================= 2ª CONFIRMAÇÃO (VERMELHO - PADRÃO ORIGINAL) =================
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

    if (secondConfirm != true) return false;

    final success = await _companyListViewModel.commands.deleteCompanyFromList(
      company.cnpj,
    );

    if (!context.mounted) return success;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Empresa excluída com sucesso!'
              : (_companyListViewModel.state.message.value ??
                    'Erro ao excluir empresa.'),
        ),
        backgroundColor: success ? Colors.green : Colors.redAccent,
      ),
    );

    return success;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
          onPressed: () => _handleBack(context),
        ),
        title: Text(
          'Minhas Empresas',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Watch((context) {
        final isExecuting = _companyListViewModel
            .fetchCompaniesByOwnerCommand
            .isExecuting
            .value;
        final companies = _companyListViewModel.state.ownedCompanies.value;
        final errorMessage = _companyListViewModel.state.message.value;

        if (_isInitialLoading.value || (isExecuting && companies.isEmpty)) {
          return Center(
            child: AnimatedThreeDots(color: colorScheme.onSurface),
          );
        }

        if (errorMessage != null && companies.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.error, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadCompanies,
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        if (companies.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma empresa encontrada',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Você ainda não possui empresas cadastradas no seu perfil.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _companyListViewModel.commands.fetchOwnedCompanies(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            itemCount: companies.length,
            itemBuilder: (context, index) {
              final company = companies[index];
              return CompanyCard(
                company: company,
                onTap: () async {
                  _companyViewModel.state.setSelectedCompany(company);

                  await context.pushNamed(
                    IndigoRouteNames.companyHome,
                    extra: company,
                  );

                  _loadCompanies();
                },
              );
            },
          ),
        );
      }),
    );
  }
}