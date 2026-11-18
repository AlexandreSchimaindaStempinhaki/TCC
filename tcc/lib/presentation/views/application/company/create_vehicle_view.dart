import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../domain/models/company_entity.dart';
import '../../../../domain/models/vehicle_entity.dart';
import '../../../widgets/animated_three_dots.dart';
import '../../../widgets/header_background.dart';
import '../../../widgets/text_field.dart';
import '../../mixins/create_vehicle_logic.dart';

class CreateVehicleView extends StatefulWidget {
  final CompanyModel? company;
  final VehicleModel? initialVehicle;

  const CreateVehicleView({
    super.key,
    this.company,
    this.initialVehicle,
  });

  @override
  State<CreateVehicleView> createState() => _CreateVehicleViewState();
}

class _CreateVehicleViewState extends State<CreateVehicleView>
    with CreateVehicleMixin {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inverseColor = colorScheme.onSurface;
    final currentImageUrl =
        widget.initialVehicle?.photoUrl ?? targetCompany?.logoUrl;

    ImageProvider? avatarImage;
    if (selectedImageFile != null) {
      avatarImage = FileImage(selectedImageFile!);
    } else if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
      if (currentImageUrl.startsWith('http://') ||
          currentImageUrl.startsWith('https://')) {
        avatarImage = NetworkImage(currentImageUrl);
      } else {
        avatarImage = FileImage(File(currentImageUrl));
      }
    }

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
                        onPressed: () => handleBack(context),
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
                    isEditing ? 'Editar  Veículo' : 'Cadastrar  Veículo',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEditing
                        ? 'Atualize a marca, o modelo, a placa, a cor e a capacidade de assentos do veículo abaixo.'
                        : 'Defina a marca, o modelo, a placa e a lotação máxima para registrar um novo veículo no Índigo.',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.secondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SELETOR DE FOTO DO VEÍCULO NO PADRÃO DA ROTA/EMPRESA
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: pickVehicleImage,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 76,
                                backgroundColor: inverseColor.withOpacity(0.12),
                                backgroundImage: avatarImage,
                                child: avatarImage == null
                                    ? Icon(
                                        Icons.directions_bus_rounded,
                                        size: 64,
                                        color: inverseColor,
                                      )
                                    : null,
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: inverseColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.scaffoldBackgroundColor,
                                    width: 2.5,
                                  ),
                                ),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  size: 18,
                                  color: theme.scaffoldBackgroundColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 38,
                          child: OutlinedButton(
                            onPressed: pickVehicleImage,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              side: BorderSide(
                                color: colorScheme.secondary.withOpacity(0.5),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              avatarImage == null
                                  ? 'Escolher Foto do Veículo (Opcional)'
                                  : 'Trocar Foto do Veículo',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.secondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // EMPRESA VINCULADA
                  IgnorePointer(
                    ignoring: true,
                    child: Opacity(
                      opacity: 0.6,
                      child: CustomTextField(
                        label: 'Empresa Vinculada',
                        hintText: 'Empresa responsável pelo veículo',
                        controller: companyNameController,
                        keyboardType: TextInputType.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 1. MARCA DO VEÍCULO
                  CustomTextField(
                    label: 'Marca do Veículo',
                    hintText: 'Ex: Mercedes-Benz / Renault / Marcopolo',
                    controller: brandController,
                    keyboardType: TextInputType.text,
                    inputFormatters: [AppFormatters.nameLimit(40)],
                  ),
                  const SizedBox(height: 20),

                  // 2. MODELO DO VEÍCULO
                  CustomTextField(
                    label: 'Modelo do Veículo',
                    hintText: 'Ex: Sprinter 416 / Master Executiva',
                    controller: modelController,
                    keyboardType: TextInputType.text,
                    inputFormatters: [AppFormatters.nameLimit(50)],
                  ),
                  const SizedBox(height: 20),

                  // 3. PLACA DO VEÍCULO
                  CustomTextField(
                    label: 'Placa do Veículo',
                    hintText: 'Ex: ABC1D23',
                    controller: plateController,
                    keyboardType: TextInputType.text,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9-]'),
                      ),
                      LengthLimitingTextInputFormatter(8),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4. CAPACIDADE DE PASSAGEIROS
                  CustomTextField(
                    label: 'Capacidade de Passageiros',
                    hintText: 'Ex: 15, 20, 44',
                    controller: capacityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 5. COR DO VEÍCULO (OPCIONAL)
                  CustomTextField(
                    label: 'Cor Predominante (Opcional)',
                    hintText: 'Ex: Branca / Prata',
                    controller: colorController,
                    keyboardType: TextInputType.text,
                    inputFormatters: [AppFormatters.nameLimit(30)],
                  ),

                  // MENSAGEM DE ERRO (LOCAL OU DO VIEWMODEL)
                  Watch((context) {
                    final localError = errorMessage.value;
                    final vmError = vehicleViewModel.state.message.value;
                    final displayError = localError ?? vmError;

                    if (displayError == null) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 16.0, left: 4.0),
                      child: Text(
                        displayError,
                        style: TextStyle(
                          color: colorScheme.error,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 32),

                  // BOTÃO DE SALVAR/CADASTRAR VEÍCULO
                  Watch((context) {
                    final busy =
                        isLoading.value ||
                        vehicleViewModel.state.isLoading.value;

                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: busy ? null : () => submitForm(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: busy
                            ? AnimatedThreeDots(color: colorScheme.onSurface)
                            : Text(
                                isEditing
                                    ? 'Salvar Alterações'
                                    : 'Cadastrar Veículo',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    );
                  }),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}