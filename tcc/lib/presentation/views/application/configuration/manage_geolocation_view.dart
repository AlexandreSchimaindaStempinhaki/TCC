import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tcc/presentation/widgets/animated_three_dots.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/routes/indigo_routes.dart';
import '../../../controllers/user/user_viewmodel.dart';
import '../../../widgets/account_option.dart';
import '../../../widgets/location_card.dart';

class ManageGeolocationView extends StatefulWidget {
  // Flag para saber se estamos editando o Embarque (true) ou o Desembarque (false)
  final bool isBoarding;

  const ManageGeolocationView({
    super.key,
    required this.isBoarding,
  });

  @override
  State<ManageGeolocationView> createState() => _ManageGeolocationViewState();
}

class _ManageGeolocationViewState extends State<ManageGeolocationView> {
  late final UserViewModel _userViewModel;
  bool _isLoadingGps = false;

  @override
  void initState() {
    super.initState();
    _userViewModel = injector.get<UserViewModel>();
    _userViewModel.commands.fetchUser();
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingGps = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorSnackBar('O GPS do aparelho está desativado.');
        setState(() => _isLoadingGps = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar('Permissão de localização negada.');
          setState(() => _isLoadingGps = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar('Permissões negadas permanentemente.');
        setState(() => _isLoadingGps = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final currentUser = _userViewModel.state.user.value;
      if (currentUser != null) {
        final newGeoPoint = GeoPoint(position.latitude, position.longitude);
        
        // Define qual campo será atualizado com base no parâmetro da tela
        final updatedUser = widget.isBoarding
            ? currentUser.copyWith(
                boardingPoint: newGeoPoint,
                disembarkationPoint: currentUser.disembarkationPoint ?? newGeoPoint,
              )
            : currentUser.copyWith(
                disembarkationPoint: newGeoPoint,
              );

        await _userViewModel.commands.saveUserData(updatedUser);
        _showSuccessSnackBar('Localização atualizada via GPS com sucesso!');
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao obter localização: $e');
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingGps = false);
    }
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
            fontSize: 24,
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
    
    // Títulos dinâmicos dependendo do tipo da tela
    final screenTitle = widget.isBoarding ? 'Ponto de Embarque (Ida)' : 'Ponto de Desembarque (Volta)';

    return Watch((context) {
      final currentUser = _userViewModel.state.user.value;
      
      // Lê o ponto de geolocalização correto
      final GeoPoint? geoPoint = widget.isBoarding 
          ? currentUser?.boardingPoint 
          : currentUser?.disembarkationPoint;

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
            screenTitle,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocationCard(
                geoPoint: geoPoint,
                onViewOnMap: () {
                  if (geoPoint != null) {
                    context.pushNamed(
                      IndigoRouteNames.singleLocationMap,
                      extra: {
                        'latitude': geoPoint.latitude,
                        'longitude': geoPoint.longitude,
                        'title': screenTitle,
                      },
                    );
                  }
                },
              ),
              const SizedBox(height: 24),

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
                    _buildSectionTitle(
                      context,
                      'Modificar Localização',
                      topPadding: 16,
                    ),

                    AccountOption(
                      icon: Icons.my_location_rounded,
                      title: 'Pegar Localização Atual (GPS)',
                      trailing: _isLoadingGps
                          ? AnimatedThreeDots(color: colorScheme.surfaceTint)
                          : const Icon(Icons.chevron_right_rounded),
                      onTap: _getCurrentLocation,
                    ),
                    const SizedBox(height: 8),

                    AccountOption(
                      icon: Icons.map_outlined,
                      title: 'Escolher no Mapa',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        final initialLocation = geoPoint ?? null;

                        final LatLng? pickedLocation = await context.pushNamed<LatLng>(
                          IndigoRouteNames.locationPicker,
                          extra: initialLocation,
                        );

                        if (pickedLocation != null && currentUser != null) {
                          final newGeoPoint = GeoPoint(
                            pickedLocation.latitude,
                            pickedLocation.longitude,
                          );
                          
                          final updatedUser = widget.isBoarding
                              ? currentUser.copyWith(
                                  boardingPoint: newGeoPoint,
                                  disembarkationPoint: currentUser.disembarkationPoint ?? newGeoPoint,
                                )
                              : currentUser.copyWith(
                                  disembarkationPoint: newGeoPoint,
                                );
                                
                          await _userViewModel.commands.saveUserData(
                            updatedUser,
                          );
                          _showSuccessSnackBar(
                            'Localização escolhida no mapa com sucesso!',
                          );
                        }
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