import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/routes/indigo_routes.dart';
import '../../../../domain/models/address_entity.dart';
import '../../../controllers/user/user_viewmodel.dart';
import '../../../widgets/account_option.dart';

class ManageAddressView extends StatefulWidget {
  const ManageAddressView({super.key});

  @override
  State<ManageAddressView> createState() => _ManageAddressViewState();
}

class _ManageAddressViewState extends State<ManageAddressView> {
  late final UserViewModel _userViewModel;

  @override
  void initState() {
    super.initState();
    _userViewModel = injector.get<UserViewModel>();
    _userViewModel.commands.fetchUser();
  }

  Widget? _buildMissingIndicator(bool isMissing) {
    if (isMissing) {
      return const Icon(
        Icons.error_outline_rounded,
        color: Colors.redAccent,
        size: 22,
      );
    }
    return null;
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    double topPadding = 24,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPadding, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Watch((context) {
      final currentUser = _userViewModel.state.user.value;
      final address = currentUser?.address;
      final isAddressMissing = address == null;
      
      final isBoardingMissing = currentUser?.boardingPoint == null;
      final isDisembarkationMissing = currentUser?.disembarkationPoint == null;

      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Gerenciar Endereços',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSectionTitle(context, 'Endereço', topPadding: 16),

                    AccountOption(
                      icon: Icons.edit_location_alt_outlined,
                      title: 'Endereço Residencial',
                      trailing: _buildMissingIndicator(isAddressMissing),
                      onTap: () {
                        context.pushNamed(
                          IndigoRouteNames.editAddress,
                          extra: {
                            'initialCity': address?.city ?? '',
                            'initialNeighborhood': address?.neighborhood ?? '',
                            'initialStreet': address?.street ?? '',
                            'initialNumber': address?.number ?? '',
                            'initialComplement': address?.complement ?? '',
                            'onSave': ({
                                  required String city,
                                  required String neighborhood,
                                  required String street,
                                  required String number,
                                  required String complement,
                                }) async {
                                  if (currentUser == null) return;
                                  final newAddress = AddressModel(
                                    city: city,
                                    neighborhood: neighborhood,
                                    street: street,
                                    number: number,
                                    complement: complement,
                                  );
                                  final updatedUser = currentUser.copyWith(
                                    address: newAddress,
                                  );
                                  await _userViewModel.commands.saveUserData(
                                    updatedUser,
                                  );
                                },
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    _buildSectionTitle(
                      context,
                      'Pontos de coleta',
                      topPadding: 16,
                    ),

                    AccountOption(
                      icon: Icons.pin_drop_outlined,
                      title: 'Ponto de Embarque (Ida)',
                      trailing: isBoardingMissing 
                          ? _buildMissingIndicator(true) 
                          : const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        context.pushNamed(
                          IndigoRouteNames.manageGeolocation,
                          extra: {'isBoarding': true},
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    AccountOption(
                      icon: Icons.flag_outlined,
                      title: 'Ponto de Desembarque (Volta)',
                      trailing: isDisembarkationMissing 
                          ? _buildMissingIndicator(true) 
                          : const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        context.pushNamed(
                          IndigoRouteNames.manageGeolocation,
                          extra: {'isBoarding': false},
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}