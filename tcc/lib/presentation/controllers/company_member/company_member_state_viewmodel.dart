import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/models/company_member_entity.dart';

class CompanyMemberState {
  final members = signal<List<CompanyMemberModel>>([]);
  final userMemberships = signal<List<CompanyMemberModel>>([]);
  final currentUserLink = signal<CompanyMemberModel?>(null);
  final message = signal<String?>(null);

  late final drivers = computed(
    () => members.value
        .where((m) => m.cargo == CompanyRole.driver)
        .toList(),
  );

  late final passengers = computed(
    () => members.value
        .where((m) => m.cargo == CompanyRole.passenger)
        .toList(),
  );

  late final admins = computed(
    () => members.value
        .where((m) => m.cargo == CompanyRole.admin)
        .toList(),
  );

  late final pendingRequests = computed(
    () => members.value
        .where((m) => m.cargo == CompanyRole.pending)
        .toList(),
  );

  bool get isCurrentUserAdmin =>
      currentUserLink.value?.cargo == CompanyRole.admin;

  bool get isCurrentUserDriver =>
      currentUserLink.value?.cargo == CompanyRole.driver;

  bool get isCurrentUserPassenger =>
      currentUserLink.value?.cargo == CompanyRole.passenger;

  void clearMessage() => message.value = null;
}