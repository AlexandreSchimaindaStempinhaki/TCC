import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/user_entity.dart';
import '../../presentation/controllers/user/user_viewmodel.dart';
import '../../presentation/views/application/configuration/about_view.dart';
import '../../presentation/views/application/configuration/address/edit_address_view.dart';
import '../../presentation/views/application/configuration/address/location_map_view.dart';
import '../../presentation/views/application/configuration/address/location_picker_view.dart';
import '../../presentation/views/application/configuration/address/manage_address_view.dart';
import '../../presentation/views/application/configuration/address/manage_geolocation_view.dart';
import '../../presentation/views/application/configuration/help_and_support_view.dart';
import '../../presentation/views/application/configuration/profile/change_password_view.dart';
import '../../presentation/views/application/configuration/profile/confirm_password_view.dart';
import '../../presentation/views/application/configuration/profile/edit_profile_date_view.dart';
import '../../presentation/views/application/configuration/profile/edit_profile_filed_view.dart';
import '../../presentation/views/application/configuration/profile/edit_profile_photo_view.dart';
import '../../presentation/views/application/configuration/profile/edit_profile_view.dart';
import '../../presentation/views/application/configuration/profile/profile_view.dart';
import '../di/dependency_injection.dart';
import 'home_routes.dart';
import 'route_access_guard.dart';

class AccountRouteNames {
  static const profile = 'profile';
  static const editProfile = 'edit_profile';
  static const editProfileField = 'edit_profile_field';
  static const editProfileDate = 'edit_profile_date';
  static const editProfilePhoto = 'edit_profile_photo';
  static const confirmPassword = 'confirm_password';
  static const changePassword = 'change_password';
  static const manageAddress = 'manage_address';
  static const editAddress = 'edit_address';
  static const manageGeolocation = 'manage_geolocation';
  static const locationPicker = 'location_picker';
  static const singleLocationMap = 'single_location_map';
  static const helpAndSupport = 'help_and_support';
  static const about = 'about';
}

class AccountPaths {
  static const profile = '/profile';
  static const editProfile = '/edit-profile';
  static const editProfileField = '/edit-profile-field';
  static const editProfileDate = '/edit-profile-date';
  static const editProfilePhoto = '/edit-profile-photo';
  static const confirmPassword = '/confirm-password';
  static const changePassword = '/change-password';
  static const manageAddress = '/manage-address';
  static const editAddress = '/edit-address';
  static const manageGeolocation = '/manage-geolocation';
  static const locationPicker = '/location-picker';
  static const singleLocationMap = '/single-location-map';
  static const helpAndSupport = '/help-and-support';
  static const about = '/about';
}

final List<RouteBase> accountRoutes = [
  GoRoute(
    path: AccountPaths.profile,
    name: AccountRouteNames.profile,
    builder: (context, state) {
      final targetUser = state.extra is UserModel
          ? state.extra as UserModel
          : null;
      return ProfileView(
        userViewModel: injector.get<UserViewModel>(),
        user: targetUser,
      );
    },
  ),
  GoRoute(
    path: AccountPaths.editProfile,
    name: AccountRouteNames.editProfile,
    builder: (context, state) => const EditProfileView(),
  ),
  GoRoute(
    path: AccountPaths.editProfileField,
    name: AccountRouteNames.editProfileField,
    redirect: (context, state) => RouteAccessGuard.requireExtraMap(
      state,
      requiredKeys: const ['title', 'currentValue', 'keyboardType', 'onSave'],
      fallback: AccountPaths.editProfile,
    ),
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
    path: AccountPaths.editProfileDate,
    name: AccountRouteNames.editProfileDate,
    builder: (context, state) => const EditProfileDateView(),
  ),
  GoRoute(
    path: AccountPaths.editProfilePhoto,
    name: AccountRouteNames.editProfilePhoto,
    builder: (context, state) => const EditProfilePhotoView(),
  ),
  GoRoute(
    path: AccountPaths.confirmPassword,
    name: AccountRouteNames.confirmPassword,
    redirect: (context, state) => RouteAccessGuard.requireExtraMap(
      state,
      requiredKeys: const ['onConfirm'],
      fallback: HomePaths.account,
    ),
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>;
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
    path: AccountPaths.changePassword,
    name: AccountRouteNames.changePassword,
    builder: (context, state) {
      final extra = state.extra is Map<String, dynamic>
          ? state.extra as Map<String, dynamic>
          : null;
      return ChangePasswordView(extra: extra);
    },
  ),
  GoRoute(
    path: AccountPaths.manageAddress,
    name: AccountRouteNames.manageAddress,
    builder: (context, state) => const ManageAddressView(),
  ),
  GoRoute(
    path: AccountPaths.editAddress,
    name: AccountRouteNames.editAddress,
    redirect: (context, state) => RouteAccessGuard.requireExtraMap(
      state,
      requiredKeys: const ['onSave'],
      fallback: AccountPaths.manageAddress,
    ),
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
    path: AccountPaths.manageGeolocation,
    name: AccountRouteNames.manageGeolocation,
    builder: (context, state) {
      final args = state.extra is Map<String, dynamic>
          ? state.extra as Map<String, dynamic>
          : null;
      final isBoarding = args?['isBoarding'] as bool? ?? true;
      return ManageGeolocationView(isBoarding: isBoarding);
    },
  ),
  GoRoute(
    path: AccountPaths.locationPicker,
    name: AccountRouteNames.locationPicker,
    builder: (context, state) {
      final initialLocation = state.extra is GeoPoint
          ? state.extra as GeoPoint
          : null;
      return LocationPickerView(initialLocation: initialLocation);
    },
  ),
  GoRoute(
    path: AccountPaths.singleLocationMap,
    name: AccountRouteNames.singleLocationMap,
    redirect: (context, state) => RouteAccessGuard.requireExtraMap(
      state,
      requiredKeys: const ['latitude', 'longitude'],
      fallback: AccountPaths.manageAddress,
    ),
    builder: (context, state) {
      final args = state.extra as Map<String, dynamic>;
      return SingleLocationMapView(
        latitude: (args['latitude'] as num).toDouble(),
        longitude: (args['longitude'] as num).toDouble(),
        title: args['title'] as String? ?? 'Localização',
      );
    },
  ),
  GoRoute(
    path: AccountPaths.helpAndSupport,
    name: AccountRouteNames.helpAndSupport,
    builder: (context, state) => const HelpAndSupportView(),
  ),
  GoRoute(
    path: AccountPaths.about,
    name: AccountRouteNames.about,
    builder: (context, state) => const AboutView(),
  ),
];