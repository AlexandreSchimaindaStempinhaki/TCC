import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/routes/company_routes.dart';
import '../../../domain/models/company_entity.dart';
import '../../../domain/models/vehicle_entity.dart';
import '../../controllers/company/company_viewmodel.dart';
import '../../controllers/user/user_viewmodel.dart';
import '../../controllers/vehicle/vehicle_list_viewmodel.dart';
import '../../controllers/vehicle/vehicle_viewmodel.dart';
import '../application/company/vehicle_details_view.dart';

mixin VehicleDetailsMixin on State<VehicleDetailsView> {
  late final VehicleViewModel vehicleViewModel;
  late final VehicleListViewModel vehicleListViewModel;
  late final CompanyViewModel companyViewModel;
  late final UserViewModel userViewModel;

  final isDeletingVehicle = signal<bool>(false);
  final hasModifiedVehicle = signal<bool>(false);

  CompanyModel? get targetCompany =>
      widget.company ?? companyViewModel.state.selectedCompany.value;

  late final Computed<bool> hasManageAccess = computed(() {
    if (widget.canManage) return true;
    final company = targetCompany;
    final currentUser = userViewModel.state.user.value;
    if (company == null || currentUser == null) return false;

    final uid = currentUser.uid.trim();
    final cpf = (currentUser.cpf ?? '').trim();

    return company.ownerId == uid ||
        (cpf.isNotEmpty && company.ownerId == cpf);
  });

  @override
  void initState() {
    super.initState();
    vehicleViewModel = injector.get<VehicleViewModel>();
    vehicleListViewModel = injector.get<VehicleListViewModel>();
    companyViewModel = injector.get<CompanyViewModel>();
    userViewModel = injector.get<UserViewModel>();
  }

  @override
  void dispose() {
    isDeletingVehicle.dispose();
    hasModifiedVehicle.dispose();
    super.dispose();
  }

  VehicleModel findReactiveVehicle() {
    final list = vehicleListViewModel.state.companyVehicles.value;
    for (final v in list) {
      if (v.id == widget.vehicle.id) {
        return v;
      }
    }
    final selected = vehicleViewModel.state.selectedVehicle.value;
    if (selected != null && selected.id == widget.vehicle.id) {
      return selected;
    }
    return widget.vehicle;
  }

  String formatPlate(String raw) {
    final clean = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (clean.length == 7) {
      return '${clean.substring(0, 3)}-${clean.substring(3)}';
    }
    return raw.toUpperCase();
  }

  void handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop(hasModifiedVehicle.value);
    }
  }

  void openCompanyHome(BuildContext context) {
    final company = targetCompany;
    if (company == null) return;
    context.pushNamed(
      CompanyRouteNames.companyHome,
      extra: company,
    );
  }

  Future<void> openEditVehicle(
    BuildContext context,
    VehicleModel currentVehicle,
  ) async {
    final updated = await context.pushNamed<bool>(
      CompanyRouteNames.createVehicle,
      extra: {
        'vehicle': currentVehicle,
        'company': targetCompany,
      },
    );

    if (updated == true) {
      hasModifiedVehicle.value = true;
      final cnpj = targetCompany?.cnpj ?? currentVehicle.companyCnpj;
      if (cnpj.isNotEmpty) {
        await vehicleListViewModel.commands.fetchVehiclesByCompany(cnpj);
      }
    }
  }

  Future<void> confirmAndDeleteVehicle(
    BuildContext context,
    VehicleModel currentVehicle,
  ) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Excluir Veículo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Tem certeza que deseja excluir o veículo "${currentVehicle.brand} ${currentVehicle.model}" (${formatPlate(currentVehicle.plate)}) da frota?',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Excluir',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    isDeletingVehicle.value = true;
    try {
      final success = await vehicleViewModel.commands.deleteVehicle(
        currentVehicle.id,
      );

      if (!context.mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();

      if (success) {
        vehicleListViewModel.state.removeVehicleFromList(currentVehicle.id);
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Veículo excluído com sucesso!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.fixed,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            duration: Duration(seconds: 2),
          ),
        );
        context.pop(true);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              vehicleViewModel.state.message.value ??
                  'Não foi possível excluir o veículo.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.fixed,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        isDeletingVehicle.value = false;
      }
    }
  }
}