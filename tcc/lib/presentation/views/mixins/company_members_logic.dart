import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/routes/indigo_routes.dart';
import '../../../domain/models/company_entity.dart';
import '../../controllers/company_member/company_member_state_viewmodel.dart';
import '../../controllers/company_member/company_member_viewmodel.dart';
import '../../widgets/account_option.dart';
import '../application/configuration/company_members_view.dart';

export '../../controllers/company_member/company_member_state_viewmodel.dart'
    show CompanyMemberItem;

mixin CompanyMembersMixin on State<CompanyMembersView> {
  late final CompanyMemberViewModel companyMemberViewModel;
  final TextEditingController searchController = TextEditingController();

  Signal<String> get searchQuery => companyMemberViewModel.state.searchQuery;
  Signal<int> get selectedFilterIndex =>
      companyMemberViewModel.state.selectedFilterIndex;
  Signal<bool> get isLoading => companyMemberViewModel.state.isLoading;
  Signal<bool> get canViewPassengers =>
      companyMemberViewModel.state.canViewPassengers;
  Signal<bool> get isCurrentUserOwner =>
      companyMemberViewModel.state.isCurrentUserOwner;
  Signal<bool> get isCurrentUserManager =>
      companyMemberViewModel.state.isCurrentUserManager;

  Signal<List<CompanyMemberItem>> get ownersList =>
      companyMemberViewModel.state.ownersList;
  Signal<List<CompanyMemberItem>> get managersList =>
      companyMemberViewModel.state.managersList;
  Signal<List<CompanyMemberItem>> get driversList =>
      companyMemberViewModel.state.driversList;
  Signal<List<CompanyMemberItem>> get passengersList =>
      companyMemberViewModel.state.passengersList;

  CompanyModel? get targetCompany =>
      companyMemberViewModel.commands.resolveCompany(widget.company);

  @override
  void initState() {
    super.initState();
    companyMemberViewModel = injector.get<CompanyMemberViewModel>();
    companyMemberViewModel.state.resetFilterState(
      showPassengers: widget.initialShowPassengers,
    );
    loadMembersData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadMembersData() =>
      companyMemberViewModel.commands.loadCompanyMembersDetailed(widget.company);

  List<CompanyMemberItem> filterItems(
    List<CompanyMemberItem> items,
    String rawQuery,
  ) => companyMemberViewModel.commands.filterItems(items, rawQuery);

  bool canManageMemberRole(CompanyMemberItem item) =>
      companyMemberViewModel.commands.canManageMemberRole(item);

  void handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(IndigoRouteNames.companyHome, extra: targetCompany);
    }
  }

  void openMemberProfile(BuildContext context, CompanyMemberItem item) {
    context.pushNamed(IndigoRouteNames.profile, extra: item.userModel);
  }

  Widget _buildSelectedRoleBadge(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: Colors.white,
          ),
          SizedBox(width: 4),
          Text(
            'Selecionado',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void handleMemberTap(BuildContext context, CompanyMemberItem item) {
    if (!canManageMemberRole(item)) {
      openMemberProfile(context, item);
      return;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? colorScheme.onSurface.withOpacity(0.22)
        : colorScheme.onSurface.withOpacity(0.14);
    final surfaceColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);

    final availableRoles = [
      if (isCurrentUserOwner.value)
        {
          'category': 'manager',
          'label': 'Gerente',
          'icon': Icons.manage_accounts_rounded,
        },
      {
        'category': 'driver',
        'label': 'Motorista',
        'icon': Icons.directions_bus_rounded,
      },
      {
        'category': 'passenger',
        'label': 'Passageiro',
        'icon': Icons.people_alt_rounded,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: surfaceColor,
                      backgroundImage: item.photoUrl.trim().isNotEmpty
                          ? NetworkImage(item.photoUrl.trim())
                          : null,
                      child: item.photoUrl.trim().isEmpty
                          ? Icon(
                              Icons.person_rounded,
                              color: colorScheme.onSurface,
                              size: 24,
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Opções do membro',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  clipBehavior: Clip.antiAlias,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 1.4),
                  ),
                  child: AccountOption(
                    icon: Icons.person_search_rounded,
                    title: 'Visualizar Perfil',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      openMemberProfile(context, item);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'Cargo na Empresa',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Container(
                  clipBehavior: Clip.antiAlias,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 1.4),
                  ),
                  child: Column(
                    children: List.generate(availableRoles.length, (idx) {
                      final role = availableRoles[idx];
                      final category = role['category'] as String;
                      final label = role['label'] as String;
                      final icon = role['icon'] as IconData;
                      final isSelected = item.roleCategory == category;

                      return Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary.withOpacity(0.10)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: isSelected
                                  ? Border.all(
                                      color: colorScheme.primary,
                                      width: 1.5,
                                    )
                                  : null,
                            ),
                            child: AccountOption(
                              icon: icon,
                              title: label,
                              iconColor: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                              textColor: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                              trailing: isSelected
                                  ? _buildSelectedRoleBadge(colorScheme)
                                  : Icon(
                                      Icons.radio_button_unchecked_rounded,
                                      size: 20,
                                      color: colorScheme.secondary,
                                    ),
                              onTap: () async {
                                if (isSelected) return;
                                Navigator.of(sheetContext).pop();
                                await _confirmAndChangeRole(
                                  context,
                                  item: item,
                                  newRole: category,
                                  newRoleLabel: label,
                                );
                              },
                            ),
                          ),
                          if (idx < availableRoles.length - 1)
                            const SizedBox(height: 4),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmAndChangeRole(
    BuildContext context, {
    required CompanyMemberItem item,
    required String newRole,
    required String newRoleLabel,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.manage_accounts_rounded,
              color: colorScheme.primary,
              size: 26,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Confirmar Cargo?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Deseja alterar o cargo de "${item.name}" para $newRoleLabel?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Confirmar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await companyMemberViewModel.commands
        .updateMemberRoleDetailed(
          widgetCompany: widget.company,
          item: item,
          newRoleCategory: newRole,
        );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Cargo alterado para $newRoleLabel com sucesso!'
                : (companyMemberViewModel.state.message.value ??
                      'Erro ao atualizar o cargo do membro.'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: success
              ? const Color(0xFF15803D)
              : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}