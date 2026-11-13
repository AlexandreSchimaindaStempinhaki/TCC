import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RouteMapView extends StatefulWidget {
  final Map<String, dynamic> route;

  const RouteMapView({
    super.key,
    required this.route,
  });

  @override
  State<RouteMapView> createState() => _RouteMapViewState();
}

class _RouteMapViewState extends State<RouteMapView> {
  GoogleMapController? _mapController;

  late LatLng _startPoint;
  late LatLng _endPoint;

  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = true;

  @override
  void initState() {
    super.initState();
    
    // Extrai dinamicamente as coordenadas vindas do 'extra' do GoRouter ou define padrões
    final double startLat = widget.route['startLatitude'] ?? -25.6793952;
    final double startLng = widget.route['startLongitude'] ?? -48.4642768;
    
    final double endLat = widget.route['endLatitude'] ?? -25.5854082;
    final double endLng = widget.route['endLongitude'] ?? -48.5648844;

    _startPoint = LatLng(startLat, startLng);
    _endPoint = LatLng(endLat, endLng);

    _fetchRoadRoute();
  }

  Future<void> _fetchRoadRoute() async {
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

        setState(() {
          _routePoints = coordinates
              .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
              .toList();
          _isLoadingRoute = false;
        });

        _fitRouteBounds();
      }
    } catch (e) {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final origin = widget.route['origin'] as String? ?? 'Origem Selecionada';
    final destination = widget.route['destination'] as String? ?? 'Destino Selecionado';
    final companyName = widget.route['companyName'] as String? ?? 'Detalhes da Rota';

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

    final Set<Polyline> polylines = {
      if (_routePoints.isNotEmpty)
        Polyline(
          polylineId: const PolylineId('indigo_real_route'),
          points: _routePoints,
          color: colorScheme.primary,
          width: 5,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
    };

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
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
            onMapCreated: (controller) {
              _mapController = controller;
              if (_routePoints.isNotEmpty) {
                _fitRouteBounds();
              }
            },
          ),

          if (_isLoadingRoute)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Chip(
                  backgroundColor: theme.cardColor,
                  elevation: 2,
                  avatar: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                  label: Text(
                    'Calculando trajeto via rodovia...',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                  ),
                ),
              ),
            ),

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
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

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
                    companyName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.radio_button_checked_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          origin,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 7),
                    child: SizedBox(
                      height: 10,
                      child: VerticalDivider(
                        width: 2,
                        color: colorScheme.secondary.withOpacity(0.4),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.school_rounded,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          destination,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
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

  void _fitRouteBounds() {
    if (_mapController == null || _routePoints.isEmpty) return;

    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (final point in _routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 60),
    );
  }
}