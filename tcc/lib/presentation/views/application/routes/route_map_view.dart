import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:signals_flutter/signals_flutter.dart';
import 'package:tcc/presentation/widgets/animated_three_dots.dart';
import 'package:tcc/presentation/widgets/live_map/live_map_marker_factory.dart';

class RouteMapView extends StatefulWidget {
  final Map<String, dynamic> route;

  const RouteMapView({super.key, required this.route});

  @override
  State<RouteMapView> createState() => _RouteMapViewState();
}

class _RouteMapViewState extends State<RouteMapView> {
  GoogleMapController? _mapController;

  late final LatLng _startPoint;
  late final LatLng _endPoint;

  final _routePoints = signal<List<LatLng>>([]);
  final _isLoadingRoute = signal<bool>(true);

  @override
  void initState() {
    super.initState();

    final double startLat =
        (widget.route['startLatitude'] as num?)?.toDouble() ?? -25.6793952;
    final double startLng =
        (widget.route['startLongitude'] as num?)?.toDouble() ?? -48.4642768;

    final double endLat =
        (widget.route['endLatitude'] as num?)?.toDouble() ?? -25.5854082;
    final double endLng =
        (widget.route['endLongitude'] as num?)?.toDouble() ?? -48.5648844;

    _startPoint = LatLng(startLat, startLng);
    _endPoint = LatLng(endLat, endLng);

    _fetchRoadRoute();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _routePoints.dispose();
    _isLoadingRoute.dispose();
    super.dispose();
  }

  Future<void> _fetchRoadRoute() async {
    _isLoadingRoute.value = true;

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${_startPoint.longitude},${_startPoint.latitude};'
      '${_endPoint.longitude},${_endPoint.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List coordinates = data['routes'][0]['geometry']['coordinates'];

        if (!mounted) return;
        _routePoints.value = coordinates
            .map(
              (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
            )
            .toList();

        _fitRouteBounds();
      }
    } catch (e) {
      debugPrint('Erro ao traçar rota via OSRM: $e');
    } finally {
      if (mounted) {
        _isLoadingRoute.value = false;
      }
    }
  }

  void _fitRouteBounds() {
    final points = _routePoints.value;
    if (_mapController == null || points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 64));
  }

  Border _overlayBorder(bool isDark) {
    return Border.all(
      color: isDark
          ? Colors.white.withOpacity(0.22)
          : Colors.black.withOpacity(0.08),
      width: 1.2,
    );
  }

  BoxDecoration _cardDecoration(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(24),
      border: _overlayBorder(isDark),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton({
    required ThemeData theme,
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: _overlayBorder(isDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Tooltip(
            message: tooltip ?? '',
            child: Center(
              child: Icon(icon, color: colorScheme.onSurface, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final topSafePadding = MediaQuery.of(context).padding.top + 12;

    final origin =
        (widget.route['origin'] ?? widget.route['startAddress'])?.toString() ??
        'Origem Selecionada';
    final destination =
        (widget.route['destination'] ?? widget.route['endAddress'])
            ?.toString() ??
        'Destino Selecionado';
    final companyName =
        (widget.route['companyName'] ?? widget.route['name'])?.toString() ??
        'Detalhes da Rota';

    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('origin'),
        position: _startPoint,
        infoWindow: InfoWindow(title: 'Origem', snippet: origin),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: _endPoint,
        infoWindow: InfoWindow(title: 'Destino', snippet: destination),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Watch((context) {
            final points = _routePoints.value;
            final Set<Polyline> polylines = {
              if (points.isNotEmpty)
                Polyline(
                  polylineId: const PolylineId('indigo_real_route'),
                  points: points,
                  color: colorScheme.primary,
                  width: 5,
                  jointType: JointType.round,
                  startCap: Cap.roundCap,
                  endCap: Cap.roundCap,
                ),
            };

            return GoogleMap(
              key: ValueKey('route_map_${isDark ? 'dark' : 'light'}'),
              mapType: MapType.normal,
              style: isDark ? LiveMapMarkerFactory.darkMapStyle : null,
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  (_startPoint.latitude + _endPoint.latitude) / 2,
                  (_startPoint.longitude + _endPoint.longitude) / 2,
                ),
                zoom: 11.5,
              ),
              markers: markers,
              polylines: polylines,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                if (_routePoints.value.isNotEmpty) {
                  _fitRouteBounds();
                }
              },
            );
          }),

          Positioned(
            top: topSafePadding,
            left: 20,
            child: _buildFloatingActionButton(
              theme: theme,
              icon: Icons.arrow_back_rounded,
              tooltip: 'Voltar',
              onTap: () => context.pop(),
            ),
          ),

          Positioned(
            top: topSafePadding,
            right: 20,
            child: _buildFloatingActionButton(
              theme: theme,
              icon: Icons.my_location_rounded,
              tooltip: 'Centralizar rota',
              onTap: _fitRouteBounds,
            ),
          ),

          Positioned(
            top: topSafePadding,
            left: 76,
            right: 76,
            height: 44,
            child: Watch((context) {
              if (!_isLoadingRoute.value) {
                return const SizedBox.shrink();
              }
              return Center(
                child: IntrinsicWidth(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: _cardDecoration(theme),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          'Calculando trajeto',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(
                          width: 28,
                          height: 16,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: AnimatedThreeDots(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: _cardDecoration(theme),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Icon(
                        Icons.radio_button_checked_rounded,
                        size: 18,
                        color: colorScheme.onSurface,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Origem',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              origin,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: SizedBox(
                      height: 14,
                      child: VerticalDivider(
                        width: 2,
                        thickness: 1.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 18,
                        color: colorScheme.onSurface,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Destino',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              destination,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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