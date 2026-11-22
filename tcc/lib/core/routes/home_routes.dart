import 'package:go_router/go_router.dart';

import '../../domain/models/company_entity.dart';
import '../../presentation/views/application/company/company_reviews_view.dart';
import '../../presentation/views/application/company/linked_companies_view.dart';
import '../../presentation/views/application/configuration/account_view.dart';
import '../../presentation/views/application/home/home_view.dart';
import '../../presentation/views/application/home/saved_view.dart';
import '../../presentation/views/application/routes/my_routes_view.dart';
import '../../presentation/views/application/routes/route_details_view.dart';
import '../../presentation/views/application/routes/route_map_view.dart';
import 'route_access_guard.dart';

class HomeRouteNames {
  static const home = 'home';
  static const saved = 'saved';
  static const myRoutes = 'my_routes';
  static const account = 'account';
  static const routeDetails = 'route_details';
  static const routeMap = 'route_map';
  static const companyReviews = 'company_reviews';
  static const linkedCompanies = 'linked_companies';
}

class HomePaths {
  static const home = '/home';
  static const saved = '/saved';
  static const myRoutes = '/my-routes';
  static const account = '/account';
  static const routeDetails = '/route-details';
  static const routeMap = '/route-map';
  static const companyReviews = '/company-reviews';
  static const linkedCompanies = '/linked-companies';
}

final List<RouteBase> homeRoutes = [
  GoRoute(
    path: HomePaths.home,
    name: HomeRouteNames.home,
    pageBuilder: (context, state) => const NoTransitionPage(child: HomeView()),
  ),
  GoRoute(
    path: HomePaths.saved,
    name: HomeRouteNames.saved,
    pageBuilder: (context, state) => const NoTransitionPage(child: SavedView()),
  ),
  GoRoute(
    path: HomePaths.myRoutes,
    name: HomeRouteNames.myRoutes,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: MyRoutesView()),
  ),
  GoRoute(
    path: HomePaths.account,
    name: HomeRouteNames.account,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: AccountView()),
  ),
  GoRoute(
    path: HomePaths.routeDetails,
    name: HomeRouteNames.routeDetails,
    redirect: (context, state) => RouteAccessGuard.requireExtraMap(state),
    builder: (context, state) {
      final routeData = state.extra as Map<String, dynamic>;
      return RouteDetailsView(route: routeData);
    },
  ),
  GoRoute(
    path: HomePaths.routeMap,
    name: HomeRouteNames.routeMap,
    redirect: (context, state) => RouteAccessGuard.requireExtraMap(state),
    builder: (context, state) {
      final routeData = state.extra as Map<String, dynamic>;
      return RouteMapView(route: routeData);
    },
  ),
  GoRoute(
    path: HomePaths.companyReviews,
    name: HomeRouteNames.companyReviews,
    builder: (context, state) {
      final company = state.extra is CompanyModel
          ? state.extra as CompanyModel
          : null;
      return CompanyReviewsView(company: company);
    },
  ),
  GoRoute(
    path: HomePaths.linkedCompanies,
    name: HomeRouteNames.linkedCompanies,
    builder: (context, state) => const LinkedCompaniesView(),
  ),
];