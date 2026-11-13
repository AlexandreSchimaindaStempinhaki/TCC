import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tcc/presentation/views/application/configuration/my_companies_view.dart';
import '../../domain/models/company_entity.dart';
import '../../domain/models/user_entity.dart';
import '../../presentation/controllers/user/user_viewmodel.dart';
import '../../presentation/views/application/configuration/about_view.dart';
import '../../presentation/views/application/configuration/company_home_view.dart';
import '../../presentation/views/application/configuration/create_companion_view.dart';
import '../../presentation/views/application/configuration/edit_address_view.dart';
import '../../presentation/views/application/configuration/location_view_map.dart';
import '../../presentation/views/application/configuration/manage_geolocation_view.dart';
import '../../presentation/views/application/home_view.dart';
import '../../presentation/views/application/saved_view.dart';
import '../../presentation/views/application/my_routes_view.dart';
import '../../presentation/views/application/configuration/account_view.dart';
import '../../presentation/views/application/route_details_view.dart';
import '../../presentation/views/application/route_map_view.dart';
import '../../presentation/views/application/company_profile_view.dart';
import '../../presentation/views/application/joined_route_detail_view.dart';
import '../../presentation/views/application/configuration/edit_profile_view.dart';
import '../../presentation/views/application/configuration/location_picker_view.dart';
import '../../presentation/views/application/configuration/manage_address_view.dart';
import '../../presentation/views/application/configuration/edit_profile_filed_view.dart';
import '../../presentation/views/application/configuration/edit_profile_date_view.dart';
import '../../presentation/views/application/configuration/edit_profile_photo_view.dart';
import '../../presentation/views/application/configuration/profile_view.dart';
import '../../presentation/views/application/configuration/change_password_view.dart';
import '../../presentation/views/application/configuration/confirm_password_view.dart';
import '../di/dependency_injection.dart';

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
  static const editProfileField = 'edit_profile_field';
  static const editProfileDate = 'edit_profile_date';
  static const editProfilePhoto = 'edit_profile_photo';
  static const profile = 'profile';
  static const confirmPassword = 'confirm_password';
  static const changePassword = 'change_password';
  static const editAddress = 'edit_address';
  static const manageGeolocation = 'manage_geolocation';
  static const singleLocationMap = 'single_location_map';
  static const about = 'about';
  static const myCompanies = 'my_companies';
  static const companyHome = 'company_home';
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
  static const editProfileField = '/edit-profile-field';
  static const editProfileDate = '/edit-profile-date';
  static const editProfilePhoto = '/edit-profile-photo';
  static const profile = '/profile';
  static const confirmPassword = '/confirm-password';
  static const changePassword = '/change-password';
  static const editAddress = '/edit-address';
  static const manageGeolocation = '/manage-geolocation';
  static const singleLocationMap = '/single-location-map';
  static const about = '/about';
  static const myCompanies = '/my-companies';
  static const companyHome = '/company-home';
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
      final initialLocation = state.extra as GeoPoint?;

      return LocationPickerView(initialLocation: initialLocation);
    },
  ),
  GoRoute(
    path: IndigoPaths.manageAddress,
    name: IndigoRouteNames.manageAddress,
    builder: (context, state) {
      return const ManageAddressView();
    },
  ),
  GoRoute(
    name: IndigoRouteNames.editProfileField,
    path: IndigoPaths.editProfileField,
    builder: (context, state) {
      final args = state.extra as Map<String, dynamic>;

      return EditProfileFieldView(
        title: args['title'] as String,
        currentValue: args['currentValue'] as String,
        keyboardType: args['keyboardType'] as TextInputType,
        onSave: args['onSave'] as Future<void> Function(String),
        hintText: args['hintText'] as String?,
        inputFormatters: args['inputFormatters'] as List<TextInputFormatter>?,
      );
    },
  ),
  GoRoute(
    name: IndigoRouteNames.editProfileDate,
    path: IndigoPaths.editProfileDate,
    builder: (context, state) {
      return const EditProfileDateView();
    },
  ),

  GoRoute(
    name: IndigoRouteNames.editProfilePhoto,
    path: IndigoPaths.editProfilePhoto,
    builder: (context, state) {
      return const EditProfilePhotoView();
    },
  ),
  GoRoute(
    name: IndigoRouteNames.profile,
    path: IndigoPaths.profile,
    builder: (context, state) {
      final targetUser = state.extra as UserModel?;
      return ProfileView(
        userViewModel: injector.get<UserViewModel>(),
        user: targetUser,
      );
    },
  ),
  GoRoute(
    name: IndigoRouteNames.confirmPassword,
    path: IndigoPaths.confirmPassword,
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>? ?? {};
      return ConfirmPasswordView(
        title: extra['title'] as String? ?? 'Confirmar',
        subtitle: extra['subtitle'] as String? ?? 'Digite sua senha:',
        buttonText: extra['buttonText'] as String? ?? 'Confirmar',
        isDestructive: extra['isDestructive'] as bool? ?? false,
        onConfirm: extra['onConfirm'] as Future<String?> Function(String),
      );
    },
  ),

  GoRoute(
    name: IndigoRouteNames.changePassword,
    path: IndigoPaths.changePassword,
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      return ChangePasswordView(extra: extra);
    },
  ),
  // Em indigo_routes.dart
  GoRoute(
    name: IndigoRouteNames.editAddress,
    path: IndigoPaths.editAddress,
    builder: (context, state) {
      final args = state.extra as Map<String, dynamic>;
      return EditAddressView(
        initialCity: args['initialCity'] as String? ?? '',
        initialNeighborhood: args['initialNeighborhood'] as String? ?? '',
        initialStreet: args['initialStreet'] as String? ?? '',
        initialNumber: args['initialNumber'] as String? ?? '',
        initialComplement: args['initialComplement'] as String? ?? '',
        onSave:
            args['onSave']
                as Future<void> Function({
                  required String city,
                  required String neighborhood,
                  required String street,
                  required String number,
                  required String complement,
                }),
      );
    },
  ),
  GoRoute(
    path: IndigoPaths.manageGeolocation,
    name: IndigoRouteNames.manageGeolocation,
    builder: (context, state) {
      final args = state.extra as Map<String, dynamic>?;
      final isBoarding = args?['isBoarding'] as bool? ?? true;

      return ManageGeolocationView(isBoarding: isBoarding);
    },
  ),
  GoRoute(
    path: IndigoPaths.singleLocationMap,
    name: IndigoRouteNames.singleLocationMap,
    builder: (context, state) {
      final args = state.extra as Map<String, dynamic>;
      return SingleLocationMapView(
        latitude: args['latitude'] as double,
        longitude: args['longitude'] as double,
        title: args['title'] as String? ?? 'Localização',
      );
    },
  ),
  GoRoute(
    path: IndigoPaths.about,
    name: IndigoRouteNames.about,
    builder: (context, state) => const AboutView(),
  ),
  GoRoute(
    path: '/create-company',
    name: IndigoRouteNames.createCompany,
    builder: (context, state) {
      final company = state.extra as CompanyModel?;
      return CreateCompanyView(initialCompany: company);
    },
  ),
  GoRoute(
    path: '/my-companies',
    name: IndigoRouteNames.myCompanies,
    builder: (context, state) => const MyCompaniesView(),
  ),
  GoRoute(
    path: '/company-home',
    name: IndigoRouteNames.companyHome,
    builder: (context, state) {
      final company = state.extra as CompanyModel?;
      return CompanyHomeView(initialCompany: company);
    },
  ),
];
