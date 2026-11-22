import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../domain/models/company_entity.dart';
import '../../../widgets/feedback/animated_three_dots.dart';
import '../../../widgets/company/company_member_card.dart';
import '../../mixins/company_members_logic.dart';

class CompanyMembersView extends StatefulWidget {
  final CompanyModel? company;
  final bool initialShowPassengers;

  const CompanyMembersView({
    super.key,
    this.company,
    this.initialShowPassengers = false,
  });

  @override
  State<CompanyMembersView> createState() => _CompanyMembersViewState();
}

class _CompanyMembersViewState extends State<CompanyMembersView>
    with CompanyMembersMixin {
  Widget _buildSectionHeader(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 10, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildContinuousGroup(
    BuildContext context,
    List<CompanyMemberItem> items,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? colorScheme.onSurface.withOpacity(0.26)
              : colorScheme.onSurface.withOpacity(0.18),
          width: 1.6,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(items.length, (index) {
          final item = items[index];

          return CompanyMemberCard(
            name: item.name,
            photoUrl: item.photoUrl,
            onTap: () => handleMemberTap(context, item),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final company = targetCompany;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
          onPressed: () => handleBack(context),
          tooltip: 'Voltar',
        ),
        title: Column(
          children: [
            Text(
              'Membros',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (company != null && company.name.trim().isNotEmpty)
              Text(
                company.name,
                style: TextStyle(
                  color: colorScheme.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: theme.dividerColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Watch((context) {
                final hasSearchText = searchQuery.value.trim().isNotEmpty;

                return TextField(
                  controller: searchController,
                  onChanged: (val) => searchQuery.value = val,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 12.0),
                      child: Icon(
                        Icons.search_rounded,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    suffixIcon: hasSearchText
                        ? IconButton(
                            tooltip: 'Limpar busca',
                            icon: Icon(
                              Icons.close_rounded,
                              color: colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            onPressed: () {
                              searchController.clear();
                              searchQuery.value = '';
                              FocusScope.of(context).unfocus();
                            },
                          )
                        : Container(
                            margin: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.refresh_rounded,
                                color: colorScheme.onSurface,
                                size: 16,
                              ),
                              tooltip: 'Atualizar membros',
                              onPressed: loadMembersData,
                            ),
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          Watch((context) {
            final showPassengersTab = canViewPassengers.value;
            final currentTab = selectedFilterIndex.value;

            final categories = [
              {'index': 0, 'label': 'Todos', 'icon': Icons.groups_rounded},
              {
                'index': 1,
                'label': 'Proprietário',
                'icon': Icons.workspace_premium_rounded,
              },
              {
                'index': 2,
                'label': 'Gerentes',
                'icon': Icons.manage_accounts_rounded,
              },
              {
                'index': 3,
                'label': 'Motoristas',
                'icon': Icons.directions_bus_rounded,
              },
              if (showPassengersTab)
                {
                  'index': 4,
                  'label': 'Passageiros',
                  'icon': Icons.people_alt_rounded,
                },
            ];

            return SizedBox(
              height: 78,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, idx) {
                  final cat = categories[idx];
                  final tabIndex = cat['index'] as int;
                  final isSelected = currentTab == tabIndex;

                  return GestureDetector(
                    onTap: () => selectedFilterIndex.value = tabIndex,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.secondary.withOpacity(0.7),
                            size: 28,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 2.5,
                            width: 24,
                            color: isSelected
                                ? colorScheme.primary
                                : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          Divider(height: 1, color: theme.dividerColor),

          Expanded(
            child: Watch((context) {
              if (isLoading.value) {
                return Center(
                  child: AnimatedThreeDots(color: colorScheme.primary),
                );
              }

              final query = searchQuery.value;
              final filterIdx = selectedFilterIndex.value;
              final allowedPassengers = canViewPassengers.value;

              final owners = filterItems(ownersList.value, query);
              final managers = filterItems(managersList.value, query);
              final drivers = filterItems(driversList.value, query);
              final passengers = allowedPassengers
                  ? filterItems(passengersList.value, query)
                  : <CompanyMemberItem>[];

              final showOwners = filterIdx == 0 || filterIdx == 1;
              final showManagers = filterIdx == 0 || filterIdx == 2;
              final showDrivers = filterIdx == 0 || filterIdx == 3;
              final showPassengers =
                  allowedPassengers && (filterIdx == 0 || filterIdx == 4);

              final isEmptyResult =
                  (!showOwners || owners.isEmpty) &&
                  (!showManagers || managers.isEmpty) &&
                  (!showDrivers || drivers.isEmpty) &&
                  (!showPassengers || passengers.isEmpty);

              return RefreshIndicator(
                onRefresh: loadMembersData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  children: [
                    if (isEmptyResult)
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Column(
                          children: [
                            Icon(
                              Icons.group_off_rounded,
                              size: 56,
                              color: colorScheme.secondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              query.trim().isNotEmpty
                                  ? 'Nenhum membro encontrado para "${query.trim()}"'
                                  : 'Nenhum membro encontrado nesta categoria',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Puxe para baixo para atualizar ou altere o filtro acima.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (showOwners && owners.isNotEmpty) ...[
                      _buildSectionHeader(context, 'Proprietário'),
                      _buildContinuousGroup(context, owners),
                    ],

                    if (showManagers && managers.isNotEmpty) ...[
                      _buildSectionHeader(context, 'Gerentes'),
                      _buildContinuousGroup(context, managers),
                    ],

                    if (showDrivers && drivers.isNotEmpty) ...[
                      _buildSectionHeader(context, 'Motoristas'),
                      _buildContinuousGroup(context, drivers),
                    ],

                    if (showPassengers && passengers.isNotEmpty) ...[
                      _buildSectionHeader(context, 'Passageiros'),
                      _buildContinuousGroup(context, passengers),
                    ],
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}