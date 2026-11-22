import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/company_entity.dart';
import '../../domain/models/route_entity.dart';
import '../../domain/models/trip_entity.dart' show TripModel, TripStopPoint;
import '../../domain/models/user_entity.dart';
import '../../domain/models/vehicle_entity.dart';
import '../../presentation/controllers/user/user_viewmodel.dart';
import '../../presentation/views/application/company/company_profile_view.dart';
import '../../presentation/views/application/company/company_reviews_view.dart';
import '../../presentation/views/application/company/vehicle_details_view.dart';
import '../../presentation/views/application/configuration/about_view.dart';
import '../../presentation/views/application/configuration/account_view.dart';
import '../../presentation/views/application/configuration/profile/change_password_view.dart';
import '../../presentation/views/application/company/company_home_view.dart';
import '../../presentation/views/application/company/company_members_view.dart';
import '../../presentation/views/application/company/company_route_request_view.dart';
import '../../presentation/views/application/company/company_routes_view.dart';
import '../../presentation/views/application/company/company_vehicles_view.dart';
import '../../presentation/views/application/configuration/profile/confirm_password_view.dart';
import '../../presentation/views/application/company/create_companion_view.dart';
import '../../presentation/views/application/company/create_vehicle_view.dart';
import '../../presentation/views/application/routes/create_route_view.dart';
import '../../presentation/views/application/configuration/address/edit_address_view.dart';
import '../../presentation/views/application/configuration/profile/edit_profile_date_view.dart';
import '../../presentation/views/application/configuration/profile/edit_profile_filed_view.dart';
import '../../presentation/views/application/configuration/profile/edit_profile_photo_view.dart';
import '../../presentation/views/application/configuration/profile/edit_profile_view.dart';
import '../../presentation/views/application/configuration/help_and_support_view.dart';
import '../../presentation/views/application/company/linked_companies_view.dart';
import '../../presentation/views/application/configuration/address/location_map_view.dart';
import '../../presentation/views/application/configuration/address/location_picker_view.dart';
import '../../presentation/views/application/configuration/address/manage_address_view.dart';
import '../../presentation/views/application/configuration/address/manage_geolocation_view.dart';
import '../../presentation/views/application/configuration/profile/profile_view.dart';
import '../../presentation/views/application/home/home_view.dart';
import '../../presentation/views/application/routes/driver_live_map_view.dart';
import '../../presentation/views/application/routes/joined_route_detail_view.dart';
import '../../presentation/views/application/routes/my_routes_view.dart';
import '../../presentation/views/application/routes/route_attendance_calendar_view.dart';
import '../../presentation/views/application/routes/route_day_schedule_view.dart';
import '../../presentation/views/application/routes/route_details_view.dart';
import '../../presentation/views/application/routes/route_entered_view.dart';
import '../../presentation/views/application/routes/route_map_view.dart';
import '../../presentation/views/application/home/saved_view.dart';
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
  static const createRoute = 'create_route';
  static const companyRoutes = 'company_routes';
  static const companyRouteRequests = 'company_route_requests';
  static const companyMembers = 'company_members';
  static const linkedCompanies = 'linked-companies';
  static const helpAndSupport = 'help-and-support';
  static const createVehicle = 'create-vehicle';
  static const companyVehicles = 'company-vehicles';
  static const vehicleDetails = 'vehicle_details';
  static const companyReviews = 'company_reviews';
  static const routeEntered = 'route_entered';
  static const driverLiveMap = 'driver_live_map';
  static const routeCalendar = 'route_calendar';
  static const routeDaySchedule = 'route_day_schedule';
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
  static const createRoute = '/create-route';
  static const companyRoutes = '/company-routes';
  static const companyRouteRequests = '/company-route-requests';
  static const companyMembers = '/company-members';
  static const linkedCompanies = '/linked-companies';
  static const helpAndSupport = '/help-and-support';
  static const createVehicle = '/create-vehicle';
  static const companyVehicles = '/company-vehicles';
  static const vehicleDetails = '/vehicle-details';
  static const companyReviews = '/company-reviews';
  static const routeEntered = '/route-entered';
  static const driverLiveMap = '/driver-live-map';
  static const routeCalendarPath = '/route-calendar';
  static const routeDaySchedule = '/route-day-schedule';
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
    path: IndigoPaths.createCompany,
    name: IndigoRouteNames.createCompany,
    builder: (context, state) {
      final company = state.extra as CompanyModel?;
      return CreateCompanyView(initialCompany: company);
    },
  ),
  GoRoute(
    path: IndigoPaths.companyHome,
    name: IndigoRouteNames.companyHome,
    builder: (context, state) {
      final company = state.extra as CompanyModel?;
      return CompanyHomeView(initialCompany: company);
    },
  ),
  GoRoute(
    path: IndigoPaths.createRoute,
    name: IndigoRouteNames.createRoute,
    builder: (context, state) {
      final extra = state.extra;
      if (extra is RouteModel) {
        return CreateRouteView(initialRoute: extra, company: extra.company);
      }
      return CreateRouteView(company: extra is CompanyModel ? extra : null);
    },
  ),
  GoRoute(
    path: IndigoPaths.companyRoutes,
    name: IndigoRouteNames.companyRoutes,
    builder: (context, state) {
      final company = state.extra is CompanyModel
          ? state.extra as CompanyModel
          : null;
      return CompanyRoutesView(company: company);
    },
  ),
  GoRoute(
    path: IndigoPaths.companyRouteRequests,
    name: IndigoRouteNames.companyRouteRequests,
    builder: (context, state) {
      final company = state.extra is CompanyModel
          ? state.extra as CompanyModel
          : null;
      return CompanyRouteRequestsView(company: company);
    },
  ),
  GoRoute(
    path: IndigoPaths.companyMembers,
    name: IndigoRouteNames.companyMembers,
    builder: (context, state) {
      final extra = state.extra;
      if (extra is CompanyModel) {
        return CompanyMembersView(company: extra);
      }
      if (extra is Map<String, dynamic>) {
        return CompanyMembersView(
          company: extra['company'] is CompanyModel
              ? extra['company'] as CompanyModel
              : null,
          initialShowPassengers:
              (extra['initialShowPassengers'] as bool?) ?? false,
        );
      }
      return const CompanyMembersView();
    },
  ),
  GoRoute(
    path: IndigoPaths.linkedCompanies,
    name: IndigoRouteNames.linkedCompanies,
    builder: (context, state) => const LinkedCompaniesView(),
  ),
  GoRoute(
    path: IndigoPaths.helpAndSupport,
    name: IndigoRouteNames.helpAndSupport,
    builder: (context, state) => const HelpAndSupportView(),
  ),
  GoRoute(
    path: IndigoPaths.createVehicle,
    name: IndigoRouteNames.createVehicle,
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
  GoRoute(
    path: IndigoPaths.companyVehicles,
    name: IndigoRouteNames.companyVehicles,
    builder: (context, state) {
      final extra = state.extra;
      if (extra is CompanyModel) {
        return CompanyVehiclesView(company: extra);
      }
      if (extra is Map<String, dynamic>) {
        final rawUnavailable = extra['unavailableVehicleIds'];
        final unavailableIds = rawUnavailable is Iterable
            ? rawUnavailable.map((e) => e.toString()).toSet()
            : const <String>{};

        return CompanyVehiclesView(
          company: extra['company'] is CompanyModel
              ? extra['company'] as CompanyModel
              : null,
          companyCnpj: extra['companyCnpj'] as String?,
          canManage: (extra['canManage'] as bool?) ?? false,
          isSelectionMode: (extra['isSelectionMode'] as bool?) ?? false,
          unavailableVehicleIds: unavailableIds,
        );
      }
      return const CompanyVehiclesView();
    },
  ),
  GoRoute(
    path: IndigoPaths.vehicleDetails,
    name: IndigoRouteNames.vehicleDetails,
    builder: (context, state) {
      final extra = state.extra;
      if (extra is VehicleModel) {
        return VehicleDetailsView(vehicle: extra);
      }
      final map = extra as Map<String, dynamic>;
      return VehicleDetailsView(
        vehicle: map['vehicle'] as VehicleModel,
        company: map['company'] as CompanyModel?,
        canManage: (map['canManage'] as bool?) ?? false,
      );
    },
  ),
  GoRoute(
    path: IndigoPaths.companyReviews,
    name: IndigoRouteNames.companyReviews,
    builder: (context, state) {
      final company = state.extra is CompanyModel
          ? state.extra as CompanyModel
          : null;
      return CompanyReviewsView(company: company);
    },
  ),
  GoRoute(
    path: '/route-entered',
    name: IndigoRouteNames.routeEntered,
    builder: (context, state) {
      final extra = state.extra;
      if (extra is Map<String, dynamic>) {
        return RouteEnteredView(
          route: extra['route'] as RouteModel,
          company: extra['company'] as CompanyModel?,
          roleBadge: extra['roleBadge'] as String?,
        );
      }
      return RouteEnteredView(route: extra as RouteModel);
    },
  ),
  GoRoute(
    path: IndigoPaths.routeCalendarPath, // ou '/route-calendar'
    name: IndigoRouteNames.routeCalendar,
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>? ?? {};
      return RouteAttendanceCalendarView(
        route: extra['route'] as RouteModel,
        company: extra['company'] as CompanyModel?,
        isStaff: (extra['isStaff'] as bool?) ?? false,
      );
    },
  ),
  GoRoute(
    path: IndigoPaths.driverLiveMap,
    name: IndigoRouteNames.driverLiveMap,
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>? ?? {};
      return DriverLiveMapView(
        route: extra['route'] as RouteModel,
        company: extra['company'] as CompanyModel?,
        trip: extra['trip'] as TripModel?,
        stops: (extra['stops'] as List<TripStopPoint>?) ?? const [],
        isDriver: (extra['isDriver'] as bool?) ?? false,
      );
    },
  ),
  GoRoute(
    path: IndigoPaths.routeDaySchedule,
    name: IndigoRouteNames.routeDaySchedule,
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>? ?? {};
      return RouteDayScheduleView(
        route: extra['route'] as RouteModel,
        company: extra['company'] as CompanyModel?,
        selectedDate: (extra['selectedDate'] as DateTime?) ?? DateTime.now(),
        isStaff: (extra['isStaff'] as bool?) ?? false,
        isDefaultPattern: (extra['isDefaultPattern'] as bool?) ?? false,
        monthLabel: extra['monthLabel'] as String?,
      );
    },
  ),
];
