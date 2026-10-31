import 'package:go_router/go_router.dart';

import '../../presentation/views/application/home_view.dart';
import '../../presentation/views/application/saved_view.dart';
import '../../presentation/views/application/my_routes_view.dart';
import '../../presentation/views/application/account_view.dart';


class IndigoRouteNames {
  static const home = 'home';
  static const saved = 'saved';
  static const myRoutes = 'my_routes';
  static const account = 'account';
}

class IndigoPaths {
  static const home = '/home';
  static const saved = '/saved';
  static const myRoutes = '/my-routes';
  static const account = '/account';
}

final List<RouteBase> indigoRoutes = [
  GoRoute(
    path: IndigoPaths.home,
    name: IndigoRouteNames.home,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: HomeView()),
  ),
  GoRoute(
    path: IndigoPaths.saved,
    name: IndigoRouteNames.saved,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: SavedView()),
  ),
  GoRoute(
    path: IndigoPaths.myRoutes,
    name: IndigoRouteNames.myRoutes,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: MyRoutesView()),
  ),
  GoRoute(
    path: IndigoPaths.account,
    name: IndigoRouteNames.account,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: AccountView()),
  ),
];