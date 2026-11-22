import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/models/company_member_entity.dart';
import '../../../domain/models/user_entity.dart';

class CompanyMemberItem {
  final String id;
  final String name;
  final String photoUrl;
  final String roleCategory;
  final UserModel userModel;

  const CompanyMemberItem({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.roleCategory,
    required this.userModel,
  });
}

class CompanyMemberState {
  final members = signal<List<CompanyMemberModel>>([]);
  final userMemberships = signal<List<CompanyMemberModel>>([]);
  final currentUserLink = signal<CompanyMemberModel?>(null);
  final message = signal<String?>(null);

  // Estados da tela de Membros da Empresa
  final searchQuery = signal<String>('');
  final selectedFilterIndex = signal<int>(0);
  final isLoading = signal<bool>(false);
  final canViewPassengers = signal<bool>(false);
  final isCurrentUserOwner = signal<bool>(false);
  final isCurrentUserManager = signal<bool>(false);

  final ownersList = signal<List<CompanyMemberItem>>([]);
  final managersList = signal<List<CompanyMemberItem>>([]);
  final driversList = signal<List<CompanyMemberItem>>([]);
  final passengersList = signal<List<CompanyMemberItem>>([]);

  final Map<String, Map<String, dynamic>> userProfilesCache = {};

  late final drivers = computed(
    () => members.value
        .where((m) => m.role == CompanyRole.driver)
        .toList(),
  );

  late final passengers = computed(
    () => members.value
        .where((m) => m.role == CompanyRole.passenger)
        .toList(),
  );

  late final admins = computed(
    () => members.value
        .where((m) => m.role == CompanyRole.admin)
        .toList(),
  );

  late final pendingRequests = computed(
    () => members.value
        .where((m) => m.role == CompanyRole.pending)
        .toList(),
  );

  bool get isCurrentUserAdmin =>
      currentUserLink.value?.role == CompanyRole.admin ||
      isCurrentUserOwner.value ||
      isCurrentUserManager.value;

  bool get isCurrentUserDriver =>
      currentUserLink.value?.role == CompanyRole.driver;

  bool get isCurrentUserPassenger =>
      currentUserLink.value?.role == CompanyRole.passenger;

  void clearMessage() => message.value = null;

  void resetFilterState({bool showPassengers = false}) {
    searchQuery.value = '';
    selectedFilterIndex.value = showPassengers ? 4 : 0;
  }
}