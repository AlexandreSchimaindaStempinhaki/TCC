import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:tcc/presentation/widgets/account/account_option.dart';
import 'package:tcc/presentation/widgets/feedback/animated_three_dots.dart';

import '../../../../domain/models/company_entity.dart';
import '../../../../domain/models/vehicle_entity.dart';
import '../../mixins/vehicle_details_logic.dart';

class VehicleDetailsView extends StatefulWidget {
  final VehicleModel vehicle;
  final CompanyModel? company;
  final bool canManage;

  const VehicleDetailsView({
    super.key,
    required this.vehicle,
    this.company,
    this.canManage = false,
  });

  @override
  State<VehicleDetailsView> createState() => _VehicleDetailsViewState();
}

class _VehicleDetailsViewState extends State<VehicleDetailsView>
    with VehicleDetailsMixin {
  Widget _buildOuterSectionTitle(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildRawImage(
    String imageUrl,
    ColorScheme colorScheme, {
    required BoxFit fit,
  }) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          color: colorScheme.primary.withOpacity(0.1),
          child: Icon(
            Icons.directions_bus_rounded,
            size: 64,
            color: colorScheme.primary,
          ),
        ),
      );
    }

    return Image.file(
      File(imageUrl),
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        color: colorScheme.primary.withOpacity(0.1),
        child: Icon(
          Icons.directions_bus_rounded,
          size: 64,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildHeaderImage(String imageUrl, ColorScheme colorScheme) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        color: colorScheme.primary.withOpacity(0.1),
        child: Icon(
          Icons.directions_bus_rounded,
          size: 64,
          color: colorScheme.primary,
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: _buildRawImage(imageUrl, colorScheme, fit: BoxFit.cover),
        ),
        Container(
          color: Colors.black.withOpacity(0.28),
        ),
        _buildRawImage(imageUrl, colorScheme, fit: BoxFit.contain),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.45),
                Colors.transparent,
                Colors.black.withOpacity(0.55),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: AccountOption(
        icon: icon,
        title: title,
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        onTap: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Watch((context) {
      final currentVehicle = findReactiveVehicle();
      final company = targetCompany;
      final canManage = hasManageAccess.value;
      final deleting = isDeletingVehicle.value;

      final imageUrl =
          (currentVehicle.photoUrl != null &&
                  currentVehicle.photoUrl!.trim().isNotEmpty)
              ? currentVehicle.photoUrl!
              : (company?.logoUrl ?? '');

      return AbsorbPointer(
        absorbing: deleting,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 230,
                pinned: true,
                backgroundColor: colorScheme.primary,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => handleBack(context),
                      tooltip: 'Voltar',
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeaderImage(imageUrl, colorScheme),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título do Veículo + Badge de Status Atual
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentVehicle.model,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${currentVehicle.brand} • ${company?.name ?? 'Frota Contratada'}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.secondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: currentVehicle.isActive
                                  ? colorScheme.onSurface
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  currentVehicle.isActive
                                      ? Icons.sensors_rounded
                                      : Icons.check_circle_outline_rounded,
                                  size: 16,
                                  color: currentVehicle.isActive
                                      ? colorScheme.surface
                                      : colorScheme.onSurface,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  currentVehicle.isActive
                                      ? 'Em rota'
                                      : 'Disponível',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: currentVehicle.isActive
                                        ? colorScheme.surface
                                        : colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Atalho para Visualizar Empresa
                      if (company != null) ...[
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
                          child: AccountOption(
                            icon: Icons.storefront,
                            title: 'Visualizar Página da Empresa',
                            trailing: const Icon(Icons.chevron_right_outlined),
                            onTap: () => openCompanyHome(context),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],

                      // Especificações no mesmo padrão de AccountOption do botão acima
                      _buildOuterSectionTitle(
                        context,
                        'Especificações do Veículo',
                      ),
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
                            _buildSpecOption(
                              context,
                              icon: Icons.credit_card_rounded,
                              title: 'Placa',
                              value: formatPlate(currentVehicle.plate),
                            ),
                            const SizedBox(height: 8),
                            _buildSpecOption(
                              context,
                              icon: Icons.directions_bus_outlined,
                              title: 'Marca e Modelo',
                              value:
                                  '${currentVehicle.brand} ${currentVehicle.model}',
                            ),
                            const SizedBox(height: 8),
                            _buildSpecOption(
                              context,
                              icon: Icons.event_seat_outlined,
                              title: 'Capacidade',
                              value: '${currentVehicle.capacity} lugares',
                            ),
                            const SizedBox(height: 8),
                            _buildSpecOption(
                              context,
                              icon: Icons.palette_outlined,
                              title: 'Cor Predominante',
                              value: (currentVehicle.color != null &&
                                      currentVehicle.color!.trim().isNotEmpty)
                                  ? currentVehicle.color!
                                  : 'Não informada',
                            ),
                          ],
                        ),
                      ),

                      // Seção de Administração (Apenas CEO ou Gerente)
                      if (canManage) ...[
                        const SizedBox(height: 28),
                        _buildOuterSectionTitle(context, 'Administração'),
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
                              AccountOption(
                                icon: Icons.edit_rounded,
                                title: 'Editar Veículo',
                                onTap: () => openEditVehicle(
                                  context,
                                  currentVehicle,
                                ),
                              ),
                              const SizedBox(height: 8),
                              AccountOption(
                                icon: Icons.delete_outline_rounded,
                                title: 'Excluir Veículo',
                                iconColor: Colors.redAccent,
                                textColor: Colors.redAccent,
                                trailing: deleting
                                    ? const SizedBox(
                                        width: 24,
                                        child: AnimatedThreeDots(
                                          color: Colors.redAccent,
                                        ),
                                      )
                                    : Text(''),
                                onTap: () => confirmAndDeleteVehicle(
                                  context,
                                  currentVehicle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}