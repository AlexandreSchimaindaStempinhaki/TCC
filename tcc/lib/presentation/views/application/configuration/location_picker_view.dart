import 'dart:convert';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' show GeoPoint;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../widgets/animated_three_dots.dart';

class LocationPickerView extends StatefulWidget {
  final GeoPoint? initialLocation;
  final String title;

  const LocationPickerView({
    super.key,
    this.initialLocation,
    this.title = 'Localização Salva',
  });

  @override
  State<LocationPickerView> createState() => _LocationPickerViewState();
}

class _LocationPickerViewState extends State<LocationPickerView> {
  GoogleMapController? _mapController;
  late LatLng _targetPosition;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isMapLoading = true;

  Timer? _debounce;
  List<dynamic> _searchResults = [];

  @override
  void initState() {
    super.initState();

    if (widget.initialLocation != null) {
      _targetPosition = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
    } else {
      _targetPosition = const LatLng(-25.5678, -48.3456);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);

      try {
        final String searchStr = Uri.encodeComponent('${query.trim()}, Paraná');
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$searchStr&format=json&limit=6&countrycodes=br&lat=${_targetPosition.latitude}&lon=${_targetPosition.longitude}',
        );

        final response = await http.get(
          url,
          headers: {'User-Agent': 'IndigoApp/1.0 (support@indigoapp.com)'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as List;
          setState(() {
            _searchResults = data;
          });
        }
      } catch (e) {
        debugPrint('Erro na busca: $e');
      } finally {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  void _selectLocation(dynamic result) {
    FocusScope.of(context).unfocus();

    final lat = double.parse(result['lat'].toString());
    final lon = double.parse(result['lon'].toString());
    final newPosition = LatLng(lat, lon);

    final String fullName = result['display_name'];
    final String shortName = fullName.split(',').first;

    setState(() {
      _targetPosition = newPosition;
      _searchResults = [];
      _searchController.text = shortName;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(newPosition, 16.0),
    );
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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _targetPosition,
              zoom: 16.0,
            ),
            markers: markers,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              if (mounted) {
                setState(() => _isMapLoading = false);
              }
            },
            onTap: (newPosition) {
              FocusScope.of(context).unfocus();
              setState(() {
                _targetPosition = newPosition;
                _searchResults = [];
              });
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: colorScheme.onSurface,
                          size: 40,
                        ),
                        const SizedBox(width: 12),
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
                                'Lat:    ${_targetPosition.latitude.toStringAsFixed(5)}\nLng:  ${_targetPosition.longitude.toStringAsFixed(5)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Clique no mapa para selecionar uma nova localização',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => context.pop(_targetPosition),
                        label: const Text(
                          'Confirmar Localização',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // CABEÇALHO DE PESQUISA SEMPRE VISÍVEL NO TOPO
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 56,
                      child: Row(
                        children: [
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: colorScheme.onSurface,
                            ),
                            onPressed: () => context.pop(),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onChanged: _onSearchChanged,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Pesquisar endereço...',
                                hintStyle: TextStyle(
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(0.7),
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          if (_isSearching)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                              ),
                              child: AnimatedThreeDots(
                                color: colorScheme.onSurface,
                              ),
                            )
                          else
                            IconButton(
                              icon: Icon(
                                Icons.search_rounded,
                                color: colorScheme.primary,
                              ),
                              onPressed: () =>
                                  _onSearchChanged(_searchController.text),
                            ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),

                    if (_searchResults.isNotEmpty) ...[
                      Divider(
                        height: 1,
                        color: theme.dividerColor.withOpacity(0.5),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 350),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final item = _searchResults[index];
                            final parts = item['display_name'].split(',');
                            final title = parts.isNotEmpty
                                ? parts[0].trim()
                                : '';
                            final subtitle = parts.length > 1
                                ? parts.skip(1).join(',').trim()
                                : '';

                            return InkWell(
                              onTap: () => _selectLocation(item),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.location_on_outlined,
                                        color: colorScheme.onSurfaceVariant,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: colorScheme.onSurface,
                                            fontFamily: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.fontFamily,
                                            height: 1.4,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (subtitle.isNotEmpty)
                                              TextSpan(
                                                text: ' $subtitle',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}