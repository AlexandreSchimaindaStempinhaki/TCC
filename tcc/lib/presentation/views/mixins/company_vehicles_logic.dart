import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/routes/company_routes.dart';
import '../../../domain/models/company_entity.dart';
import '../../../domain/models/vehicle_entity.dart';
import '../../controllers/company/company_viewmodel.dart';
import '../../controllers/user/user_viewmodel.dart';
import '../../controllers/vehicle/vehicle_list_viewmodel.dart';
import '../application/company/company_vehicles_view.dart';

mixin CompanyVehiclesMixin on State<CompanyVehiclesView> {
  late final VehicleListViewModel vehicleListViewModel;
  late final CompanyViewModel companyViewModel;
  late final UserViewModel userViewModel;

  final searchController = TextEditingController();

  CompanyModel? get targetCompany =>
      widget.company ?? companyViewModel.state.selectedCompany.value;

  String get targetCompanyCnpj {
    final fromCompany = targetCompany?.cnpj.trim() ?? '';
    if (fromCompany.isNotEmpty) return fromCompany;
    return (widget.companyCnpj ?? '').trim();
  }

  bool get hasManageAccess {
    if (widget.canManage) return true;
    final company = targetCompany;
    final currentUser = userViewModel.state.user.value;
    if (company == null || currentUser == null) return false;

    final uid = currentUser.uid.trim();
    final cpf = (currentUser.cpf ?? '').trim();

    return company.ownerId == uid || (cpf.isNotEmpty && company.ownerId == cpf);
  }

  bool isVehicleInUse(VehicleModel vehicle) =>
      widget.unavailableVehicleIds.contains(vehicle.id.trim());

  bool isVehicleUnavailableForSelection(VehicleModel vehicle) =>
      isVehicleInUse(vehicle);

  @override
  void initState() {
    super.initState();
    vehicleListViewModel = injector.get<VehicleListViewModel>();
    companyViewModel = injector.get<CompanyViewModel>();
    userViewModel = injector.get<UserViewModel>();

    vehicleListViewModel.state.searchQuery.value = '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshVehicles();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> refreshVehicles() async {
    final cnpj = targetCompanyCnpj;
    if (cnpj.isNotEmpty) {
      await vehicleListViewModel.commands.fetchVehiclesByCompany(cnpj);
    }
  }

  void onSearchChanged(String value) {
    vehicleListViewModel.state.searchQuery.value = value;
  }

  void clearSearch(BuildContext context) {
    searchController.clear();
    vehicleListViewModel.state.searchQuery.value = '';
    FocusScope.of(context).unfocus();
  }

  void handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    }
  }

  void handleVehicleTap(BuildContext context, VehicleModel vehicle) {
    if (!widget.isSelectionMode) {
      openVehicleDetails(context, vehicle);
      return;
    }

    if (isVehicleInUse(vehicle)) {
      _showSelectionWarning(
        context,
        'Este veículo já está em uso em outra viagem ativa nesta rota.',
      );
      return;
    }

    context.pop(vehicle);
  }

  void _showSelectionWarning(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> openCreateVehicle(BuildContext context) async {
    final created = await context.pushNamed<bool>(
      CompanyRouteNames.createVehicle,
      extra: targetCompany,
    );
    if (created == true) {
      await refreshVehicles();
    }
  }

  Future<void> openVehicleDetails(
    BuildContext context,
    VehicleModel vehicle,
  ) async {
    final changed = await context.pushNamed<bool>(
      CompanyRouteNames.vehicleDetails,
      extra: {
        'vehicle': vehicle,
        'company': targetCompany,
        'canManage': hasManageAccess,
      },
    );
    if (changed == true) {
      await refreshVehicles();
    }
  }
}