import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/routes/indigo_routes.dart';
import '../../../controllers/user_viewmodel.dart';
import '../../../widgets/account_option.dart';

class ManageAddressView extends StatefulWidget {
  const ManageAddressView({super.key});

  @override
  State<ManageAddressView> createState() => _ManageAddressViewState();
}

class _ManageAddressViewState extends State<ManageAddressView> {
  late final UserViewModel _userViewModel;
  bool _isLoadingGps = false;

  @override
  void initState() {
    super.initState();
    _userViewModel = injector.get<UserViewModel>();
    _userViewModel.commands.fetchUser();
  }

  // Indicador visual caso o campo de endereço esteja vazio
  Widget? _buildMissingIndicator(dynamic value) {
    final bool isEmpty = value == null || value.toString().trim().isEmpty;

    if (isEmpty) {
      return const Icon(
        Icons.error_outline_rounded,
        color: Colors.redAccent,
        size: 22,
      );
    }

    return null;
  }

  Widget _buildSectionTitle(BuildContext context, String title, {double topPadding = 24}) {
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Função para pegar a localização atual via GPS em tempo real
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingGps = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Por favor, ative o GPS do aparelho.');
        setState(() => _isLoadingGps = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Permissão de localização negada.');
          setState(() => _isLoadingGps = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final currentUser = _userViewModel.state.user.value;
      if (currentUser != null) {
        _showSnackBar(
          'GPS Atualizado: Lat ${position.latitude.toStringAsFixed(4)}, Lng ${position.longitude.toStringAsFixed(4)}',
        );
      }

      setState(() => _isLoadingGps = false);
    } catch (e) {
      setState(() => _isLoadingGps = false);
      _showSnackBar('Erro ao obter localização: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Watch((context) {
      final currentUser = _userViewModel.state.user.value;
      final balneario = currentUser?.boardingPoint ?? '';

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
                    // ================= SEÇÃO: RESIDÊNCIA =================
                    _buildSectionTitle(context, 'Residência', topPadding: 16),

                    AccountOption(
                      icon: Icons.edit_location_alt_outlined,
                      title: 'Editar Endereço',
                      trailing: _buildMissingIndicator(balneario),
                      onTap: () {
                        context.pushNamed(
                          IndigoRouteNames.editAddress,
                          extra: {
                            'initialCity': '',
                            'initialNeighborhood': balneario,
                            'initialStreet': '',
                            'initialNumber': '',
                            'initialComplement': '',
                            'onSave': ({
                              required String city,
                              required String neighborhood,
                              required String street,
                              required String number,
                              required String complement,
                            }) async {
                              // Nenhuma alteração persistida no banco por enquanto
                            },
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    AccountOption(
                      icon: Icons.map_outlined,
                      title: 'Geolocalização',
                      trailing: _isLoadingGps
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          builder: (context) => Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gerenciar Geolocalização',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  leading: Icon(
                                    Icons.my_location_rounded,
                                    color: colorScheme.primary,
                                  ),
                                  title: const Text(
                                    'Usar Localização Atual (GPS)',
                                  ),
                                  onTap: () {
                                    context.pop();
                                    _getCurrentLocation();
                                  },
                                ),
                                ListTile(
                                  leading: Icon(
                                    Icons.map_outlined,
                                    color: colorScheme.primary,
                                  ),
                                  title: const Text('Escolher no Mapa'),
                                  onTap: () async {
                                    context.pop();
                                    final LatLng? pickedLocation = await context
                                        .pushNamed<LatLng>(
                                          IndigoRouteNames.locationPicker,
                                        );
                                    if (pickedLocation != null) {
                                      _showSnackBar(
                                        'Coordenadas obtidas via Mapa!',
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    // ================= SEÇÃO: ADICIONAR PONTOS DE PARADA =================
                    _buildSectionTitle(context, 'Adicionar pontos de parada', topPadding: 16),

                    AccountOption(
                      icon: Icons.add_location_alt_outlined,
                      title: 'Novo Ponto de Parada',
                      onTap: () {
                        _showSnackBar('Funcionalidade de pontos de parada em breve.');
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