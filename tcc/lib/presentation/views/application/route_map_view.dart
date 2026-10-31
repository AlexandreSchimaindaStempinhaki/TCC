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

  final LatLng _startPoint = const LatLng(-25.6793952, -48.4642768);
  final LatLng _endPoint = const LatLng(-25.5854082, -48.5648844);

  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = true;

  @override
  void initState() {
    super.initState();
    _fetchRoadRoute();
  }

  // Requisição ao OSRM para traçar a rota exata pelas pistas
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
    final origin = widget.route['origin'] as String? ?? 'Av. das Magnólias, 58';
    final destination = widget.route['destination'] as String? ?? 'IFPR - Campus Paranaguá';
    final companyName = widget.route['companyName'] as String? ?? 'Linha Universitária';

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
          color: const Color(0xFF1E3A8A), // Azul Índigo
          width: 5,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
    };

    return Scaffold(
      body: Stack(
        children: [
          // 1. GOOGLE MAPS
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

          // Feedback visual durante o cálculo da rota
          if (_isLoadingRoute)
            const Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Chip(
                  backgroundColor: Colors.white,
                  elevation: 2,
                  avatar: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  label: Text(
                    'Calculando trajeto via rodovia...',
                    style: TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                  ),
                ),
              ),
            ),

          // 2. BOTÃO VOLTAR
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 20,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF0F172A),
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 3. CARD INFERIOR COM ENDEREÇOS ATUALIZADOS
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.radio_button_checked_rounded,
                        size: 16,
                        color: Color(0xFF1E3A8A),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          origin,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 7),
                    child: SizedBox(
                      height: 10,
                      child: VerticalDivider(
                        width: 2,
                        color: Color(0xFFCBD5E1),
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
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
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