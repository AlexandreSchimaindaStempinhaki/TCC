import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../widgets/header_background.dart';
import '../../../widgets/text_field.dart';
import '../../../widgets/animated_three_dots.dart';

class EditAddressView extends StatefulWidget {
  final String initialCity;
  final String initialNeighborhood;
  final String initialStreet;
  final String initialNumber;
  final String initialComplement;
  final Future<void> Function({
    required String city,
    required String neighborhood,
    required String street,
    required String number,
    required String complement,
  })
  onSave;

  const EditAddressView({
    super.key,
    required this.initialCity,
    required this.initialNeighborhood,
    required this.initialStreet,
    required this.initialNumber,
    required this.initialComplement,
    required this.onSave,
  });

  @override
  State<EditAddressView> createState() => _EditAddressViewState();
}

class _EditAddressViewState extends State<EditAddressView> {
  late final TextEditingController _cityController;
  late final TextEditingController _neighborhoodController;
  late final TextEditingController _streetController;
  late final TextEditingController _numberController;
  late final TextEditingController _complementController;

  final isLoading = signal(false);
  final errorMessage = signal<String?>(null);

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.initialCity);
    _neighborhoodController = TextEditingController(
      text: widget.initialNeighborhood,
    );
    _streetController = TextEditingController(text: widget.initialStreet);
    _numberController = TextEditingController(text: widget.initialNumber);
    _complementController = TextEditingController(
      text: widget.initialComplement,
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    _neighborhoodController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    isLoading.dispose();
    errorMessage.dispose();
    super.dispose();
  }

  bool _validateFields() {
    final city = _cityController.text.trim();
    final neighborhood = _neighborhoodController.text.trim();
    final street = _streetController.text.trim();
    final number = _numberController.text.trim();

    if (city.isEmpty ||
        neighborhood.isEmpty ||
        street.isEmpty ||
        number.isEmpty) {
      errorMessage.value = 'Preencha todos os campos obrigatórios.';
      return false;
    }

    if (city.length < 3) {
      errorMessage.value = 'A cidade deve ter pelo menos 3 caracteres.';
      return false;
    }

    if (neighborhood.length < 3) {
      errorMessage.value = 'O bairro deve ter pelo menos 3 caracteres.';
      return false;
    }

    if (street.length < 3) {
      errorMessage.value = 'O logradouro deve ter pelo menos 3 caracteres.';
      return false;
    }

    errorMessage.value = null;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final router = GoRouter.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                HeaderBackground(height: context.screenHeight * 0.3),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => context.pop(),
                        tooltip: 'Voltar',
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Editar  Endereço',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  CustomTextField(
                    label: 'Cidade',
                    hintText: 'Ex: Pontal do Paraná',
                    controller: _cityController,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Bairro / Balneário',
                    hintText: 'Ex: Pontal do Sul',
                    controller: _neighborhoodController,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Rua / Logradouro',
                    hintText: 'Ex: Rua Barão do Rio Branco',
                    controller: _streetController,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: CustomTextField(
                          label: 'Número',
                          hintText: '150',
                          controller: _numberController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: CustomTextField(
                          label: 'Complemento',
                          hintText: 'Casa 2 (Opcional)',
                          controller: _complementController,
                          keyboardType: TextInputType.text,
                        ),
                      ),
                    ],
                  ),

                  Watch((context) {
                    if (errorMessage.value == null) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 12.0, left: 4.0),
                      child: Text(
                        errorMessage.value!,
                        style: TextStyle(
                          color: colorScheme.error,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 32),

                  Watch(
                    (context) => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading.value
                            ? null
                            : () async {
                                if (!_validateFields()) return;

                                try {
                                  isLoading.value = true;
                                  await widget.onSave(
                                    city: _cityController.text.trim(),
                                    neighborhood: _neighborhoodController.text
                                        .trim(),
                                    street: _streetController.text.trim(),
                                    number: _numberController.text.trim(),
                                    complement: _complementController.text
                                        .trim(),
                                  );

                                  if (!context.mounted) return;
                                  router.pop();
                                } catch (e) {
                                  errorMessage.value =
                                      'Erro ao salvar endereço. Tente novamente.';
                                } finally {
                                  if (context.mounted) {
                                    isLoading.value = false;
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading.value
                            ? AnimatedThreeDots(color: colorScheme.onSurface)
                            : const Text(
                                'Salvar Endereço',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
