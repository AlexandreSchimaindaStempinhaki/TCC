import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../domain/models/company_entity.dart';
import '../../../widgets/animated_three_dots.dart';
import '../../../widgets/company_vehicle_card.dart';
import '../../mixins/company_vehicles_logic.dart';

class CompanyVehiclesView extends StatefulWidget {
  final CompanyModel? company;
  final String? companyCnpj;
  final bool canManage;
  final bool isSelectionMode;
  final Set<String> unavailableVehicleIds;

  const CompanyVehiclesView({
    super.key,
    this.company,
    this.companyCnpj,
    this.canManage = false,
    this.isSelectionMode = false,
    this.unavailableVehicleIds = const {},
  });

  @override
  State<CompanyVehiclesView> createState() => _CompanyVehiclesViewState();
}

class _CompanyVehiclesViewState extends State<CompanyVehiclesView>
    with CompanyVehiclesMixin {
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
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colorScheme.onSurface,
          ),
          onPressed: () => handleBack(context),
        ),
        title: Text(
          widget.isSelectionMode ? 'Selecionar Veículo' : 'Veículos da Empresa',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (hasManageAccess && targetCompany != null)
            IconButton(
              tooltip: 'Cadastrar Veículo',
              icon: Icon(
                Icons.add_rounded,
                color: colorScheme.onSurface,
                size: 24,
              ),
              onPressed: () => openCreateVehicle(context),
            ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          if (widget.isSelectionMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.30),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_bus_filled_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Escolha o veículo que será utilizado nesta viagem para iniciar a rota.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // BARRA DE PESQUISA NO PADRÃO DA HOMEVIEW
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: theme.dividerColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      theme.brightness == Brightness.dark ? 0.3 : 0.05,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Watch((context) {
                final hasSearchText =
                    vehicleListViewModel.state.searchQuery.value
                        .trim()
                        .isNotEmpty;

                return TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Buscar por modelo, marca ou placa...',
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
                            onPressed: () => clearSearch(context),
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
                              tooltip: 'Atualizar veículos',
                              onPressed: refreshVehicles,
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
          Divider(height: 1, color: theme.dividerColor),

          // LISTA REATIVA DE VEÍCULOS
          Expanded(
            child: Watch((context) {
              final state = vehicleListViewModel.state;
              final isLoading = state.isLoading.value;
              final allVehicles = state.companyVehicles.value;
              final vehicles = state.filteredVehicles.value;
              final query = state.searchQuery.value;

              if (isLoading && allVehicles.isEmpty) {
                return Center(
                  child: AnimatedThreeDots(color: colorScheme.primary),
                );
              }

              if (vehicles.isEmpty) {
                final emptyTitle = query.trim().isNotEmpty
                    ? 'Nenhum veículo encontrado para "${query.trim()}"'
                    : (widget.isSelectionMode
                        ? 'Nenhum veículo disponível para iniciar a rota'
                        : 'Nenhum veículo cadastrado no momento');

                final emptySubtitle = query.trim().isNotEmpty
                    ? 'Tente pesquisar por outro modelo, marca ou placa.'
                    : (widget.isSelectionMode
                        ? (hasManageAccess
                            ? 'Cadastre um veículo no ícone + acima antes de iniciar a rota.'
                            : 'Solicite ao gerente ou proprietário da empresa o cadastro de um veículo para iniciar a rota.')
                        : (hasManageAccess
                            ? 'Toque no ícone + no topo para cadastrar o primeiro veículo.'
                            : 'Os veículos utilizados pela empresa aparecerão aqui.'));

                return RefreshIndicator(
                  color: colorScheme.onSurface,
                  onRefresh: refreshVehicles,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(32, 80, 32, 100),
                    children: [
                      Icon(
                        Icons.directions_bus_outlined,
                        size: 56,
                        color: colorScheme.secondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        emptyTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        emptySubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: colorScheme.onSurface,
                onRefresh: refreshVehicles,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  itemCount: vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = vehicles[index];
                    final unavailable = widget.isSelectionMode &&
                        isVehicleUnavailableForSelection(vehicle);
                    final inUse =
                        widget.isSelectionMode && isVehicleInUse(vehicle);

                    return Stack(
                      children: [
                        Opacity(
                          opacity: unavailable ? 0.48 : 1.0,
                          child: CompanyVehicleCard(
                            key: ValueKey('vehicle_${vehicle.id}'),
                            vehicle: vehicle,
                            companyLogoUrl: targetCompany?.logoUrl,
                            onTap: () => handleVehicleTap(context, vehicle),
                          ),
                        ),
                        if (unavailable)
                          Positioned(
                            top: 10,
                            right: 12,
                            child: IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: inUse
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFFDC2626),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  inUse ? 'Em uso na rota' : 'Inativo',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}