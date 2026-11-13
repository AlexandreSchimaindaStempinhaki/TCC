import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/routes/indigo_routes.dart';
import '../../../../domain/models/company_entity.dart';
import '../../../controllers/company/company_list_viewmodel.dart';
import '../../../controllers/company/company_viewmodel.dart';
import '../../../widgets/account_option.dart';
import '../../../widgets/animated_three_dots.dart';

class CompanyHomeView extends StatefulWidget {
  final CompanyModel? initialCompany;

  const CompanyHomeView({super.key, this.initialCompany});

  @override
  State<CompanyHomeView> createState() => _CompanyHomeViewState();
}

class _CompanyHomeViewState extends State<CompanyHomeView> {
  late final CompanyViewModel _companyViewModel;
  late final CompanyListViewModel _companyListViewModel;

  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _companyViewModel = injector.get<CompanyViewModel>();
    _companyListViewModel = injector.get<CompanyListViewModel>();

    if (widget.initialCompany != null) {
      _companyViewModel.state.setSelectedCompany(widget.initialCompany);
    }
  }

  String _formatCnpj(String cnpj) {
    final digits = cnpj.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 14) return cnpj;
    return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.${digits.substring(5, 8)}/${digits.substring(8, 12)}-${digits.substring(12, 14)}';
  }

  String _formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7, 11)}';
    } else if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6, 10)}';
    }
    return phone;
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(IndigoRouteNames.myCompanies);
    }
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    double topPadding = 24,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPadding, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditCompany(CompanyModel company) async {
    await context.pushNamed(
      IndigoRouteNames.createCompany,
      extra: company,
    );
    await _companyListViewModel.commands.fetchOwnedCompanies();

    // Sincroniza a empresa selecionada com a versão atualizada da lista
    final updatedList = _companyListViewModel.state.ownedCompanies.value;
    for (final comp in updatedList) {
      if (comp.cnpj == company.cnpj) {
        _companyViewModel.state.setSelectedCompany(comp);
        break;
      }
    }
  }

  Future<void> _confirmAndDeleteCompany(
    BuildContext context,
    CompanyModel company,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;

    // ================= 1ª CONFIRMAÇÃO (AMARELO) =================
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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

    // ================= 2ª CONFIRMAÇÃO (VERMELHO) =================
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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

    setState(() => _isDeleting = true);

    final success = await _companyListViewModel.commands.deleteCompanyFromList(
      company.cnpj,
    );

    if (!context.mounted) return;

    setState(() => _isDeleting = false);

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

    if (success) {
      _companyViewModel.state.setSelectedCompany(null);
      _handleBack(context);
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Módulo "$feature" pronto para integração.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Watch((context) {
      final company =
          _companyViewModel.state.selectedCompany.value ?? widget.initialCompany;

      if (company == null) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
              onPressed: () => _handleBack(context),
            ),
          ),
          body: Center(
            child: Text(
              'Nenhuma empresa selecionada.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        );
      }

      return AbsorbPointer(
        absorbing: _isDeleting,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: colorScheme.onSurface,
              ),
              onPressed: () => _handleBack(context),
            ),
            title: Text(
              'Painel da Empresa',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.edit_outlined, color: colorScheme.primary),
                tooltip: 'Editar Empresa',
                onPressed: () => _openEditCompany(company),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= CARD DE CABEÇALHO DA EMPRESA =================
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor:
                                colorScheme.primary.withOpacity(0.1),
                            backgroundImage: (company.logoUrl != null &&
                                    company.logoUrl!.isNotEmpty)
                                ? NetworkImage(company.logoUrl!)
                                : null,
                            child: (company.logoUrl == null ||
                                    company.logoUrl!.isEmpty)
                                ? Icon(
                                    Icons.domain_rounded,
                                    size: 36,
                                    color: colorScheme.primary,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  company.name,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {
                                    Clipboard.setData(
                                      ClipboardData(text: company.cnpj),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'CNPJ copiado para a área de transferência!',
                                        ),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'CNPJ: ${_formatCnpj(company.cnpj)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.copy_rounded,
                                        size: 14,
                                        color: colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(
                        color: theme.dividerColor.withOpacity(0.5),
                        height: 1,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              company.email,
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _formatPhone(company.phone),
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ================= INDICADORES RÁPIDOS =================
                Row(
                  children: [
                    _buildStatCard(
                      context,
                      icon: Icons.group_rounded,
                      value: '${company.memberIds.length}',
                      label: company.memberIds.length == 1
                          ? 'Membro Ativo'
                          : 'Membros Ativos',
                      iconColor: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      context,
                      icon: Icons.star_rounded,
                      value: company.rating.toStringAsFixed(1),
                      label: '${company.ratingCount} avaliações',
                      iconColor: Colors.amber.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ================= MENU DE OPERAÇÃO E GESTÃO =================
                Container(
                  clipBehavior: Clip.antiAlias,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // --- SEÇÃO: OPERAÇÃO DE TRANSPORTE ---
                      _buildSectionTitle(
                        context,
                        'Operação',
                        topPadding: 16,
                      ),

                      AccountOption(
                        icon: Icons.route_outlined,
                        title: 'Rotas e Itinerários',
                        onTap: () =>
                            _showComingSoon(context, 'Rotas e Itinerários'),
                      ),
                      const SizedBox(height: 8),

                      AccountOption(
                        icon: Icons.directions_bus_outlined,
                        title: 'Viagens e Horários',
                        onTap: () =>
                            _showComingSoon(context, 'Viagens e Horários'),
                      ),
                      const SizedBox(height: 8),

                      AccountOption(
                        icon: Icons.location_on_outlined,
                        title: 'Pontos de Embarque',
                        onTap: () =>
                            _showComingSoon(context, 'Pontos de Embarque'),
                      ),

                      // --- SEÇÃO: EQUIPE E PASSAGEIROS ---
                      _buildSectionTitle(context, 'Equipe e Clientes'),

                      AccountOption(
                        icon: Icons.badge_outlined,
                        title: 'Motoristas e Membros',
                        onTap: () =>
                            _showComingSoon(context, 'Motoristas e Membros'),
                      ),
                      const SizedBox(height: 8),

                      AccountOption(
                        icon: Icons.people_outline_rounded,
                        title: 'Passageiros Vinculados',
                        onTap: () =>
                            _showComingSoon(context, 'Passageiros Vinculados'),
                      ),
                      const SizedBox(height: 8),

                      AccountOption(
                        icon: Icons.star_outline_rounded,
                        title: 'Avaliações e Feedbacks',
                        onTap: () =>
                            _showComingSoon(context, 'Avaliações e Feedbacks'),
                      ),

                      // --- SEÇÃO: ADMINISTRAÇÃO ---
                      _buildSectionTitle(context, 'Administração'),

                      AccountOption(
                        icon: Icons.edit_note_rounded,
                        title: 'Editar Dados da Empresa',
                        onTap: () => _openEditCompany(company),
                      ),
                      const SizedBox(height: 8),

                      AccountOption(
                        icon: Icons.delete_outline_rounded,
                        title: 'Excluir Empresa',
                        iconColor: Colors.redAccent,
                        textColor: Colors.redAccent,
                        trailing: _isDeleting
                            ? const AnimatedThreeDots(color: Colors.redAccent)
                            : null,
                        onTap: () => _confirmAndDeleteCompany(context, company),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}