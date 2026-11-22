import 'package:go_router/go_router.dart';

import '../../domain/models/company_entity.dart';
import '../../domain/models/route_entity.dart';
import '../../domain/models/vehicle_entity.dart';
import '../../presentation/views/application/company/company_home_view.dart';
import '../../presentation/views/application/company/company_members_view.dart';
import '../../presentation/views/application/company/company_route_request_view.dart';
import '../../presentation/views/application/company/company_routes_view.dart';
import '../../presentation/views/application/company/company_vehicles_view.dart';
import '../../presentation/views/application/company/create_companion_view.dart';
import '../../presentation/views/application/company/create_vehicle_view.dart';
import '../../presentation/views/application/company/vehicle_details_view.dart';
import '../../presentation/views/application/routes/create_route_view.dart';
import 'home_routes.dart';
import 'route_access_guard.dart';

class CompanyRouteNames {
  static const createCompany = 'create_company';
  static const companyHome = 'company_home';
  static const companyRoutes = 'company_routes';
  static const companyMembers = 'company_members';
  static const companyVehicles = 'company_vehicles';
  static const vehicleDetails = 'vehicle_details';

  // Exclusivas de Gestão (Dono / Gerente)
  static const createRoute = 'create_route';
  static const companyRouteRequests = 'company_route_requests';
  static const createVehicle = 'create_vehicle';
}

class CompanyPaths {
  static const createCompany = '/create-company';
  static const companyHome = '/company-home';
  static const companyRoutes = '/company-routes';
  static const companyMembers = '/company-members';
  static const companyVehicles = '/company-vehicles';
  static const vehicleDetails = '/vehicle-details';

  // Exclusivas de Gestão (Dono / Gerente)
  static const createRoute = '/create-route';
  static const companyRouteRequests = '/company-route-requests';
  static const createVehicle = '/create-vehicle';
}

final List<RouteBase> companyRoutes = [
  // ================= CRIAÇÃO (PÚBLICO AUTENTICADO) / EDIÇÃO (SOMENTE CEO) =================
  GoRoute(
    path: CompanyPaths.createCompany,
    name: CompanyRouteNames.createCompany,
    redirect: (context, state) {
      final extra = state.extra;
      // Criar uma nova empresa é permitido para qualquer usuário autenticado.
      // Editar uma empresa existente é permitido apenas ao Dono (CEO).
      if (extra is CompanyModel) {
        return RouteAccessGuard.requireOwner(
          company: extra,
          fallback: CompanyPaths.companyHome,
        );
      }
      return null;
    },
    builder: (context, state) {
      final company = state.extra is CompanyModel
          ? state.extra as CompanyModel
          : null;
      return CreateCompanyView(initialCompany: company);
    },
  ),

  // ================= VISUALIZAÇÃO DA EMPRESA (COM AÇÕES DE GESTÃO PROTEGIDAS) =================
  GoRoute(
    path: CompanyPaths.companyHome,
    name: CompanyRouteNames.companyHome,
    builder: (context, state) {
      final company = state.extra is CompanyModel
          ? state.extra as CompanyModel
          : null;
      return CompanyHomeView(initialCompany: company);
    },
  ),

  GoRoute(
    path: CompanyPaths.companyRoutes,
    name: CompanyRouteNames.companyRoutes,
    builder: (context, state) {
      final company = state.extra is CompanyModel
          ? state.extra as CompanyModel
          : null;
      return CompanyRoutesView(company: company);
    },
  ),

  GoRoute(
    path: CompanyPaths.companyMembers,
    name: CompanyRouteNames.companyMembers,
    redirect: (context, state) {
      final extra = state.extra;
      CompanyModel? company;
      bool wantsPassengers = false;

      if (extra is CompanyModel) {
        company = extra;
      } else if (extra is Map<String, dynamic>) {
        company = extra['company'] is CompanyModel
            ? extra['company'] as CompanyModel
            : null;
        wantsPassengers = (extra['initialShowPassengers'] as bool?) ?? false;
      }

      // Aba de passageiros é estritamente restrita à equipe da empresa
      if (wantsPassengers) {
        return RouteAccessGuard.requireCompanyStaff(
          company: company,
          fallback: HomePaths.home,
        );
      }
      return null;
    },
    builder: (context, state) {
      final extra = state.extra;
      if (extra is CompanyModel) {
        return CompanyMembersView(company: extra);
      }
      if (extra is Map<String, dynamic>) {
        final company = extra['company'] is CompanyModel
            ? extra['company'] as CompanyModel
            : null;
        final requestedShowPassengers =
            (extra['initialShowPassengers'] as bool?) ?? false;
        final allowedShowPassengers =
            requestedShowPassengers &&
            RouteAccessGuard.isCompanyStaff(company: company);

        return CompanyMembersView(
          company: company,
          initialShowPassengers: allowedShowPassengers,
        );
      }
      return const CompanyMembersView();
    },
  ),

  GoRoute(
    path: CompanyPaths.companyVehicles,
    name: CompanyRouteNames.companyVehicles,
    redirect: (context, state) {
      final extra = state.extra;
      if (extra is Map<String, dynamic>) {
        final isSelectionMode = (extra['isSelectionMode'] as bool?) ?? false;
        if (isSelectionMode) {
          final company = extra['company'] is CompanyModel
              ? extra['company'] as CompanyModel
              : null;
          final companyCnpj = extra['companyCnpj'] as String?;

          return RouteAccessGuard.requireDriverWithLicense(
            company: company,
            companyCnpj: companyCnpj,
            fallback: HomePaths.myRoutes,
          );
        }
      }
      return null;
    },
    builder: (context, state) {
      final extra = state.extra;
      if (extra is CompanyModel) {
        return CompanyVehiclesView(
          company: extra,
          canManage: RouteAccessGuard.isOwnerOrManager(company: extra),
        );
      }
      if (extra is Map<String, dynamic>) {
        final company = extra['company'] is CompanyModel
            ? extra['company'] as CompanyModel
            : null;
        final companyCnpj = extra['companyCnpj'] as String?;
        final rawUnavailable = extra['unavailableVehicleIds'];
        final unavailableIds = rawUnavailable is Iterable
            ? rawUnavailable.map((e) => e.toString()).toSet()
            : const <String>{};

        final requestedCanManage = (extra['canManage'] as bool?) ?? false;
        final effectiveCanManage =
            requestedCanManage &&
            RouteAccessGuard.isOwnerOrManager(
              company: company,
              companyCnpj: companyCnpj,
            );

        return CompanyVehiclesView(
          company: company,
          companyCnpj: companyCnpj,
          canManage: effectiveCanManage,
          isSelectionMode: (extra['isSelectionMode'] as bool?) ?? false,
          unavailableVehicleIds: unavailableIds,
        );
      }
      return const CompanyVehiclesView();
    },
  ),

  GoRoute(
    path: CompanyPaths.vehicleDetails,
    name: CompanyRouteNames.vehicleDetails,
    redirect: (context, state) {
      final extra = state.extra;
      if (extra is VehicleModel) return null;
      if (extra is Map<String, dynamic> && extra['vehicle'] is VehicleModel) {
        return null;
      }
      return CompanyPaths.companyVehicles;
    },
    builder: (context, state) {
      final extra = state.extra;
      if (extra is VehicleModel) {
        return VehicleDetailsView(
          vehicle: extra,
          canManage: RouteAccessGuard.isOwnerOrManager(),
        );
      }
      final map = extra as Map<String, dynamic>;
      final company = map['company'] is CompanyModel
          ? map['company'] as CompanyModel
          : null;
      final requestedCanManage = (map['canManage'] as bool?) ?? false;
      final effectiveCanManage =
          requestedCanManage &&
          RouteAccessGuard.isOwnerOrManager(company: company);

      return VehicleDetailsView(
        vehicle: map['vehicle'] as VehicleModel,
        company: company,
        canManage: effectiveCanManage,
      );
    },
  ),

  // ================= GESTÃO EXCLUSIVA (SOMENTE DONO OU GERENTE) =================
  GoRoute(
    path: CompanyPaths.createRoute,
    name: CompanyRouteNames.createRoute,
    redirect: (context, state) {
      final extra = state.extra;
      CompanyModel? company;
      RouteModel? route;

      if (extra is RouteModel) {
        route = extra;
        company = extra.company;
      } else if (extra is CompanyModel) {
        company = extra;
      }

      return RouteAccessGuard.requireOwnerOrManager(
        company: company,
        companyCnpj: route?.companyCnpj,
        route: route,
        fallback: CompanyPaths.companyHome,
      );
    },
    builder: (context, state) {
      final extra = state.extra;
      if (extra is RouteModel) {
        return CreateRouteView(initialRoute: extra, company: extra.company);
      }
      return CreateRouteView(company: extra is CompanyModel ? extra : null);
    },
  ),

  GoRoute(
    path: CompanyPaths.companyRouteRequests,
    name: CompanyRouteNames.companyRouteRequests,
    redirect: (context, state) {
      final company = state.extra is CompanyModel
          ? state.extra as CompanyModel
          : null;
      return RouteAccessGuard.requireOwnerOrManager(
        company: company,
        fallback: CompanyPaths.companyHome,
      );
    },
    builder: (context, state) {
      final company = state.extra is CompanyModel
          ? state.extra as CompanyModel
          : null;
      return CompanyRouteRequestsView(company: company);
    },
  ),

  GoRoute(
    path: CompanyPaths.createVehicle,
    name: CompanyRouteNames.createVehicle,
    redirect: (context, state) {
      final extra = state.extra;
      CompanyModel? company;

      if (extra is CompanyModel) {
        company = extra;
      } else if (extra is Map<String, dynamic>) {
        company = extra['company'] is CompanyModel
            ? extra['company'] as CompanyModel
            : null;
      }

      return RouteAccessGuard.requireOwnerOrManager(
        company: company,
        fallback: CompanyPaths.companyHome,
      );
    },
    builder: (context, state) {
      final extra = state.extra;
      if (extra is VehicleModel) {
        return CreateVehicleView(initialVehicle: extra);
      }
      if (extra is Map<String, dynamic>) {
        return CreateVehicleView(
          initialVehicle: extra['vehicle'] is VehicleModel
              ? extra['vehicle'] as VehicleModel
              : null,
          company: extra['company'] is CompanyModel
              ? extra['company'] as CompanyModel
              : null,
        );
      }
      return CreateVehicleView(company: extra is CompanyModel ? extra : null);
    },
  ),
];