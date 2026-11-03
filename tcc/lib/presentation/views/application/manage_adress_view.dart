import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/circular_text_field.dart';

class ManageAddressView extends StatefulWidget {
  const ManageAddressView({super.key});

  @override
  State<ManageAddressView> createState() => _ManageAddressViewState();
}

class _ManageAddressViewState extends State<ManageAddressView> {
  // Controladores para os campos do endereço
  final _balnearioController = TextEditingController(text: 'Pontal do Sul');
  final _ruaController = TextEditingController(text: 'Rua Barão do Rio Branco');
  final _numeroController = TextEditingController(text: '150');
  final _complementoController = TextEditingController(text: 'Casa 2');

  // Variáveis para guardar as coordenadas geográficas
  LatLng? _selectedCoordinates;
  String _locationStatus = 'Nenhuma coordenada GPS vinculada';
  bool _isLoadingGps = false;

  @override
  void dispose() {
    _balnearioController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    super.dispose();
  }

  // Função para pegar a localização atual em tempo real via GPS
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

      setState(() {
        _selectedCoordinates = LatLng(position.latitude, position.longitude);
        _locationStatus = 'Lat: ${position.latitude.toStringAsFixed(5)}, Lng: ${position.longitude.toStringAsFixed(5)} (GPS Atual)';
        _isLoadingGps = false;
      });

      _showSnackBar('Localização atual capturada com sucesso!');
    } catch (e) {
      setState(() => _isLoadingGps = false);
      _showSnackBar('Erro ao obter localização: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Endereço Residencial',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho descritivo
            Row(
              children: [
                Icon(Icons.home_work_rounded, color: colorScheme.primary, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Dados do Local',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Informe os dados textuais do seu endereço e vincule a geolocalização exata para facilitar as rotas.',
              style: TextStyle(fontSize: 12, color: colorScheme.secondary),
            ),
            const SizedBox(height: 20),

            // 1. CAMPOS TEXTUAIS USANDO O CircularTextField
            CircularTextField(
              label: 'Balneário / Bairro',
              controller: _balnearioController,
              icon: Icons.landscape_rounded,
            ),
            const SizedBox(height: 16),

            CircularTextField(
              label: 'Rua / Logradouro',
              controller: _ruaController,
              icon: Icons.alt_route_rounded,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CircularTextField(
                    label: 'Número',
                    controller: _numeroController,
                    icon: Icons.looks_one_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: CircularTextField(
                    label: 'Complemento (Opcional)',
                    controller: _complementoController,
                    icon: Icons.info_outline_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 2. SEÇÃO DE GEOLOCALIZAÇÃO (EM TEMPO REAL / MAPA)
            Text(
              'Geolocalização (GPS)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pin_drop_rounded, color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _locationStatus,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Botão Usar Localização Atual (Tempo Real)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingGps ? null : _getCurrentLocation,
                          icon: _isLoadingGps
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded, size: 18),
                          label: const Text('Usar Atual'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Botão Escolher no Mapa
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            // Abre a tela do mapa que criamos anteriormente
                            final LatLng? pickedLocation = await context.pushNamed<LatLng>('locationPicker');
                            if (pickedLocation != null) {
                              setState(() {
                                _selectedCoordinates = pickedLocation;
                                _locationStatus = 'Lat: ${pickedLocation.latitude.toStringAsFixed(5)}, Lng: ${pickedLocation.longitude.toStringAsFixed(5)} (Definido no Mapa)';
                              });
                            }
                          },
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text('Abrir Mapa'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.dividerColor),
                            foregroundColor: colorScheme.onSurface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 3. BOTÃO DE SALVAR ENDEREÇO
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Aqui você envia os dados consolidados para o backend/banco local
                  _showSnackBar('Endereço residencial salvo com sucesso!');
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Salvar Endereço',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}