import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';

class SingleLocationMapView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String title;

  const SingleLocationMapView({
    super.key,
    required this.latitude,
    required this.longitude,
    this.title = 'Localização Salva',
  });

  @override
  State<SingleLocationMapView> createState() => _SingleLocationMapViewState();
}

class _SingleLocationMapViewState extends State<SingleLocationMapView> {
  late LatLng _targetPosition;

  @override
  void initState() {
    super.initState();
    _targetPosition = LatLng(widget.latitude, widget.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('target_location'),
        position: _targetPosition,
        infoWindow: InfoWindow(title: widget.title),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };

    return Scaffold(
      body: Stack(
        children: [
          // 1. MAPA FOCADO NO PONTO ÚNICO
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _targetPosition,
              zoom: 16.0, // Zoom mais próximo pois é apenas um ponto
            ),
            markers: markers,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
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

          // 3. CARD INFERIOR COM DETALHES DO PONTO
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      theme.brightness == Brightness.dark ? 0.3 : 0.08,
                    ),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: colorScheme.onSurface,
                    size: 50,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lat: ${widget.latitude.toStringAsFixed(5)}\nLng: ${widget.longitude.toStringAsFixed(5)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
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