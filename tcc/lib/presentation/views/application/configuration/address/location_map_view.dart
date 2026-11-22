import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:tcc/presentation/widgets/live_map/live_map_marker_factory.dart';

import '../../../../widgets/animated_three_dots.dart';

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
  bool _isMapLoading = true;

  @override
  void initState() {
    super.initState();
    _targetPosition = LatLng(widget.latitude, widget.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final overlayBorder = Border.all(
      color: isDark
          ? Colors.white.withOpacity(0.22)
          : Colors.black.withOpacity(0.08),
      width: 1.2,
    );

    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('target_location'),
        position: _targetPosition,
        infoWindow: InfoWindow(title: widget.title),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. MAPA FOCADO NO PONTO ÚNICO
          GoogleMap(
            key: ValueKey('single_location_map_${isDark ? 'dark' : 'light'}'),
            mapType: MapType.normal,
            style: isDark ? LiveMapMarkerFactory.darkMapStyle : null,
            initialCameraPosition: CameraPosition(
              target: _targetPosition,
              zoom: 16.0,
            ),
            markers: markers,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            onMapCreated: (_) {
              if (mounted) {
                setState(() => _isMapLoading = false);
              }
            },
          ),

          // OVERLAY DE CARREGAMENTO ENQUANTO O MAPA INICIALIZA
          if (_isMapLoading)
            Positioned.fill(
              child: Container(
                color: theme.scaffoldBackgroundColor,
                child: Center(
                  child: AnimatedThreeDots(color: colorScheme.onSurface),
                ),
              ),
            ),

          // 2. BOTÃO VOLTAR (SEMPRE VISÍVEL NO TOPO)
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.cardColor,
                shape: BoxShape.circle,
                border: overlayBorder,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.18 : 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
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
          ),

          // 3. CARD INFERIOR COM DETALHES DO PONTO
          if (!_isMapLoading)
            Positioned(
              left: 20,
              right: 20,
              bottom: 30,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: overlayBorder,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.18 : 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
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
                            'Lat: ${widget.latitude.toStringAsFixed(5)}\nLng:${widget.longitude.toStringAsFixed(5)}',
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