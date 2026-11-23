import 'package:go_router/go_router.dart';

import '../../domain/models/company_entity.dart';
import '../../domain/models/route_entity.dart';
import '../../domain/models/trip_entity.dart' show TripModel, TripStopPoint;
import '../../presentation/views/application/routes/driver_live_map_view.dart';
import '../../presentation/views/application/routes/joined_route_detail_view.dart';
import '../../presentation/views/application/routes/route_attendance_calendar_view.dart';
import '../../presentation/views/application/routes/route_day_schedule_view.dart';
import '../../presentation/views/application/routes/route_entered_view.dart';
import 'home_routes.dart';
import 'route_access_guard.dart';

class RouteOperationNames {
  static const joinedRouteDetail = 'joined_route_detail';
  static const routeEntered = 'route_entered';
  static const routeCalendar = 'route_calendar';
  static const routeDaySchedule = 'route_day_schedule';
  static const driverLiveMap = 'driver_live_map';
}

class RouteOperationPaths {
  static const joinedRouteDetail = '/joined-route-detail';
  static const routeEntered = '/route-entered';
  static const routeCalendar = '/route-calendar';
  static const routeDaySchedule = '/route-day-schedule';
  static const driverLiveMap = '/driver-live-map';
}

final List<RouteBase> routeOperationRoutes = [
  GoRoute(
    path: RouteOperationPaths.joinedRouteDetail,
    name: RouteOperationNames.joinedRouteDetail,
    redirect: (context, state) => RouteAccessGuard.requireExtraMap(
      state,
      fallback: HomePaths.myRoutes,
    ),
    builder: (context, state) {
      final routeData = state.extra as Map<String, dynamic>;
      return JoinedRouteDetailView(route: routeData);
    },
  ),

  GoRoute(
    path: RouteOperationPaths.routeEntered,
    name: RouteOperationNames.routeEntered,
    redirect: (context, state) {
      final extra = state.extra;
      RouteModel? route;
      CompanyModel? company;

      if (extra is RouteModel) {
        route = extra;
      } else if (extra is Map<String, dynamic>) {
        route = extra['route'] is RouteModel
            ? extra['route'] as RouteModel
            : null;
        company = extra['company'] is CompanyModel
            ? extra['company'] as CompanyModel
            : null;
      }

      return RouteAccessGuard.requireRouteParticipant(
        route: route,
        company: company,
        fallback: HomePaths.myRoutes,
      );
    },
    builder: (context, state) {
      final extra = state.extra;
      if (extra is Map<String, dynamic>) {
        final route = extra['route'] as RouteModel;
        final company = extra['company'] is CompanyModel
            ? extra['company'] as CompanyModel
            : null;
        final rawBadge = extra['roleBadge'] as String?;

        // CEO, Gerente e Motorista mantêm o badge da equipe; demais ficam como Passageiro
        final isStaff = RouteAccessGuard.isCompanyStaff(
          company: company,
          companyCnpj: route.companyCnpj,
          route: route,
        );
        final safeBadge = isStaff ? rawBadge : 'Passageiro';

        return RouteEnteredView(
          route: route,
          company: company,
          roleBadge: safeBadge,
        );
      }
      return RouteEnteredView(route: extra as RouteModel);
    },
  ),

  GoRoute(
    path: RouteOperationPaths.routeCalendar,
    name: RouteOperationNames.routeCalendar,
    redirect: (context, state) {
      final extra = state.extra;
      if (extra is! Map<String, dynamic> || extra['route'] is! RouteModel) {
        return HomePaths.myRoutes;
      }
      final route = extra['route'] as RouteModel;
      final company = extra['company'] is CompanyModel
          ? extra['company'] as CompanyModel
          : null;

      return RouteAccessGuard.requireRouteParticipant(
        route: route,
        company: company,
        fallback: HomePaths.myRoutes,
      );
    },
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>;
      final route = extra['route'] as RouteModel;
      final company = extra['company'] is CompanyModel
          ? extra['company'] as CompanyModel
          : null;

      // CEO, Gerente e Motorista sempre recebem visão de equipe para ver passageiros
      final effectiveStaff = RouteAccessGuard.isCompanyStaff(
        company: company,
        companyCnpj: route.companyCnpj,
        route: route,
      );

      return RouteAttendanceCalendarView(
        route: route,
        company: company,
        isStaff: effectiveStaff,
      );
    },
  ),

  GoRoute(
    path: RouteOperationPaths.routeDaySchedule,
    name: RouteOperationNames.routeDaySchedule,
    redirect: (context, state) {
      final extra = state.extra;
      if (extra is! Map<String, dynamic> || extra['route'] is! RouteModel) {
        return HomePaths.myRoutes;
      }
      final route = extra['route'] as RouteModel;
      final company = extra['company'] is CompanyModel
          ? extra['company'] as CompanyModel
          : null;

      return RouteAccessGuard.requireRouteParticipant(
        route: route,
        company: company,
        fallback: HomePaths.myRoutes,
      );
    },
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>;
      final route = extra['route'] as RouteModel;
      final company = extra['company'] is CompanyModel
          ? extra['company'] as CompanyModel
          : null;

      // CEO, Gerente e Motorista sempre recebem visão de equipe para ver passageiros do dia
      final effectiveStaff = RouteAccessGuard.isCompanyStaff(
        company: company,
        companyCnpj: route.companyCnpj,
        route: route,
      );

      return RouteDayScheduleView(
        route: route,
        company: company,
        selectedDate: (extra['selectedDate'] as DateTime?) ?? DateTime.now(),
        isStaff: effectiveStaff,
        isDefaultPattern: (extra['isDefaultPattern'] as bool?) ?? false,
        monthLabel: extra['monthLabel'] as String?,
      );
    },
  ),

  GoRoute(
    path: RouteOperationPaths.driverLiveMap,
    name: RouteOperationNames.driverLiveMap,
    redirect: (context, state) {
      final extra = state.extra;
      if (extra is! Map<String, dynamic> || extra['route'] is! RouteModel) {
        return HomePaths.myRoutes;
      }
      final route = extra['route'] as RouteModel;
      final company = extra['company'] is CompanyModel
          ? extra['company'] as CompanyModel
          : null;

      return RouteAccessGuard.requireRouteParticipant(
        route: route,
        company: company,
        fallback: HomePaths.myRoutes,
      );
    },
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>;
      final route = extra['route'] as RouteModel;
      final company = extra['company'] is CompanyModel
          ? extra['company'] as CompanyModel
          : null;

      final requestedDriver = (extra['isDriver'] as bool?) ?? false;
      final effectiveDriver =
          requestedDriver &&
          RouteAccessGuard.canDriveRoute(
            company: company,
            companyCnpj: route.companyCnpj,
            route: route,
          );

      return DriverLiveMapView(
        route: route,
        company: company,
        trip: extra['trip'] is TripModel ? extra['trip'] as TripModel : null,
        stops: (extra['stops'] as List<TripStopPoint>?) ?? const [],
        isDriver: effectiveDriver,
      );
    },
  ),
];