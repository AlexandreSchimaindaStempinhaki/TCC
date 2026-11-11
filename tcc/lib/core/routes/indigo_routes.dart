import 'package:go_router/go_router.dart';
import '../../presentation/views/application/home_view.dart';
import '../../presentation/views/application/saved_view.dart';
import '../../presentation/views/application/my_routes_view.dart';
import '../../presentation/views/application/account_view.dart';
import '../../presentation/views/application/route_details_view.dart';
import '../../presentation/views/application/route_map_view.dart';
import '../../presentation/views/application/company_profile_view.dart';
import '../../presentation/views/application/joined_route_detail_view.dart';
import '../../presentation/views/application/edit_profile_view.dart';
import '../../presentation/views/application/location_picker_view.dart';
import '../../presentation/views/application/manage_adress_view.dart';

class IndigoRouteNames {
  static const home = 'home';
  static const saved = 'saved';
  static const myRoutes = 'my_routes';
  static const account = 'account';
  static const routeDetails = 'route_details';
  static const createCompany = 'create_company';
  static const routeMap = 'route_map';
  static const companyProfile = 'company_profile';
  static const joinedRouteDetail = 'joined_route_detail';
  static const editProfile = 'edit_profile';
  static const locationPicker = 'location_picker';
  static const manageAddress = 'manage_address';
}

class IndigoPaths {
  static const home = '/home';
  static const saved = '/saved';
  static const myRoutes = '/my-routes';
  static const account = '/account';
  static const routeDetails = '/route-details';
  static const createCompany = '/create-company';
  static const routeMap = '/route-map';
  static const companyProfile = '/company-profile';
  static const joinedRouteDetail = '/joined-route-detail';
  static const editProfile = '/edit-profile';
  static const locationPicker = '/location-picker';
  static const manageAddress = '/manage-address';
}

final List<RouteBase> indigoRoutes = [
  GoRoute(
    path: IndigoPaths.home,
    name: IndigoRouteNames.home,
    pageBuilder: (context, state) => const NoTransitionPage(child: HomeView()),
  ),
  GoRoute(
    path: IndigoPaths.saved,
    name: IndigoRouteNames.saved,
    pageBuilder: (context, state) => const NoTransitionPage(child: SavedView()),
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
  GoRoute(
    path: IndigoPaths.routeDetails,
    name: IndigoRouteNames.routeDetails,
    builder: (context, state) {
      final routeData = state.extra as Map<String, dynamic>;
      return RouteDetailsView(route: routeData);
    },
  ),
  GoRoute(
    path: IndigoPaths.routeMap,
    name: IndigoRouteNames.routeMap,
    builder: (context, state) {
      final routeData = state.extra as Map<String, dynamic>;
      return RouteMapView(route: routeData);
    },
  ),
  GoRoute(
    path: IndigoPaths.companyProfile,
    name: IndigoRouteNames.companyProfile,
    builder: (context, state) {
      final companyData = state.extra as Map<String, dynamic>;
      return CompanyProfileView(company: companyData);
    },
  ),
  GoRoute(
    path: IndigoPaths.joinedRouteDetail,
    name: IndigoRouteNames.joinedRouteDetail,
    builder: (context, state) {
      final routeData = state.extra as Map<String, dynamic>;
      return JoinedRouteDetailView(route: routeData);
    },
  ),
  GoRoute(
    path: IndigoPaths.editProfile,
    name: IndigoRouteNames.editProfile,
    builder: (context, state) {
      return const EditProfileView();
    },
  ),
  GoRoute(
    path: IndigoPaths.locationPicker,
    name: IndigoRouteNames.locationPicker,
    builder: (context, state) {
      return const LocationPickerView();
    },
  ),
  GoRoute(
    path: IndigoPaths.manageAddress,
    name: IndigoRouteNames.manageAddress,
    builder: (context, state) {
      return const ManageAddressView();
    },
  ),
];
