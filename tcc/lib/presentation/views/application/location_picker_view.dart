import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';

class LocationPickerView extends StatefulWidget {
  final LatLng? initialPosition;

  const LocationPickerView({
    super.key,
    this.initialPosition,
  });

  @override
  State<LocationPickerView> createState() => _LocationPickerViewState();
}

class _LocationPickerViewState extends State<LocationPickerView> {
  GoogleMapController? _mapController;
  late LatLng _selectedPosition;
  bool _isLoading = false;

  // Posição padrão caso nenhuma seja passada (Ex: Paranaguá / PR)
  static const LatLng _defaultLocation = LatLng(-25.5188, -48.5496);

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition ?? _defaultLocation;
  }

  // Simula a obtenção da localização atual do usuário
  Future<void> _useCurrentLocation() async {
    setState(() => _isLoading = true);
    
    // Aqui você integraria o pacote 'geolocator' se desejar coordenadas reais do GPS do celular:
    // Position position = await Geolocator.getCurrentPosition();
    // final currentLatLng = LatLng(position.latitude, position.longitude);
    
    // Simulando uma localização atual para exemplo:
    await Future.delayed(const Duration(milliseconds: 800));
    const currentLatLng = LatLng(-25.5210, -48.5520);

    setState(() {
      _selectedPosition = currentLatLng;
      _isLoading = false;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(currentLatLng, 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // 1. GOOGLE MAPS
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) {
              // Atualiza a posição conforme o usuário arrasta o mapa
              _selectedPosition = position.target;
            },
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
          ),

          // Marcador Fixo no Centro da Tela
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35),
              child: Icon(
                Icons.location_pin,
                size: 45,
                color: colorScheme.primary,
              ),
            ),
          ),

          // 2. BOTÃO VOLTAR
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: theme.cardColor,
              radius: 20,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: colorScheme.onSurface,
                  size: 20,
                ),
                onPressed: () => context.pop(),
              ),
            ),
          ),

          // 3. BOTÃO DE "USAR LOCALIZAÇÃO ATUAL" (Flutuante no topo/direita)
          Positioned(
            top: 50,
            right: 20,
            child: FloatingActionButton.small(
              backgroundColor: theme.cardColor,
              heroTag: 'currentLocationBtn',
              onPressed: _isLoading ? null : _useCurrentLocation,
              child: _isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                  : Icon(
                      Icons.my_location_rounded,
                      color: colorScheme.primary,
                    ),
            ),
          ),

          // 4. CARD INFERIOR COM BOTÃO DE CONFIRMAÇÃO
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecionar Localização',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Arraste o mapa para posicionar o pino no local desejado.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        // Retorna a latitude e longitude selecionadas para a tela anterior
                        context.pop(_selectedPosition);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirmar Localização',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}