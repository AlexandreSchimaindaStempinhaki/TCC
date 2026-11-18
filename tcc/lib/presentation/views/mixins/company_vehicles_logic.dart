import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/routes/indigo_routes.dart';
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

  bool get hasManageAccess {
    if (widget.canManage) return true;
    final company = targetCompany;
    final currentUser = userViewModel.state.user.value;
    if (company == null || currentUser == null) return false;

    final uid = currentUser.uid.trim();
    final cpf = (currentUser.cpf ?? '').trim();

    return company.ownerId == uid ||
        (cpf.isNotEmpty && company.ownerId == cpf);
  }

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
    final cnpj = targetCompany?.cnpj ?? '';
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

  Future<void> openCreateVehicle(BuildContext context) async {
    final created = await context.pushNamed<bool>(
      IndigoRouteNames.createVehicle,
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
      IndigoRouteNames.vehicleDetails,
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