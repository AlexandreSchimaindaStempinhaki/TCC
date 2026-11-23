import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../domain/models/company_entity.dart';
import '../../../../domain/models/vehicle_entity.dart';
import '../../../controllers/company/company_viewmodel.dart';
import '../../../controllers/vehicle/vehicle_list_viewmodel.dart';
import '../../../controllers/vehicle/vehicle_viewmodel.dart';
import '../../application/company/create_vehicle_view.dart';

mixin CreateVehicleMixin on State<CreateVehicleView> {
  late final VehicleViewModel vehicleViewModel;
  late final VehicleListViewModel vehicleListViewModel;
  late final CompanyViewModel companyViewModel;

  late final TextEditingController companyNameController;
  late final TextEditingController brandController;
  late final TextEditingController modelController;
  late final TextEditingController plateController;
  late final TextEditingController capacityController;
  late final TextEditingController colorController;

  final isLoading = signal<bool>(false);
  final errorMessage = signal<String?>(null);

  File? selectedImageFile;

  bool get isEditing => widget.initialVehicle != null;

  CompanyModel? get targetCompany =>
      widget.company ?? companyViewModel.state.selectedCompany.value;

  @override
  void initState() {
    super.initState();
    vehicleViewModel = injector.get<VehicleViewModel>();
    vehicleListViewModel = injector.get<VehicleListViewModel>();
    companyViewModel = injector.get<CompanyViewModel>();

    vehicleViewModel.state.clearMessage();

    final initial = widget.initialVehicle;
    companyNameController = TextEditingController(
      text: targetCompany?.name ?? '',
    );
    brandController = TextEditingController(text: initial?.brand ?? '');
    modelController = TextEditingController(text: initial?.model ?? '');
    plateController = TextEditingController(text: initial?.plate ?? '');
    capacityController = TextEditingController(
      text: initial != null ? initial.capacity.toString() : '',
    );
    colorController = TextEditingController(text: initial?.color ?? '');
  }

  @override
  void dispose() {
    companyNameController.dispose();
    brandController.dispose();
    modelController.dispose();
    plateController.dispose();
    capacityController.dispose();
    colorController.dispose();
    isLoading.dispose();
    errorMessage.dispose();
    super.dispose();
  }

  void handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    }
  }

  Future<void> pickVehicleImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null && mounted) {
        setState(() {
          selectedImageFile = File(picked.path);
        });
      }
    } catch (_) {
      errorMessage.value = 'Não foi possível selecionar a imagem do veículo.';
    }
  }

  Future<void> submitForm(BuildContext context) async {
    FocusScope.of(context).unfocus();
    errorMessage.value = null;
    vehicleViewModel.state.clearMessage();

    final companyCnpj =
        widget.initialVehicle?.companyCnpj ?? targetCompany?.cnpj ?? '';
    if (companyCnpj.isEmpty) {
      errorMessage.value = 'Nenhuma empresa vinculada encontrada.';
      return;
    }

    final brand = brandController.text.trim();
    final model = modelController.text.trim();
    final plate = plateController.text
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final capacity = int.tryParse(capacityController.text.trim());
    final color = colorController.text.trim();

    if (brand.isEmpty) {
      errorMessage.value = 'Informe a marca do veículo.';
      return;
    }
    if (model.isEmpty) {
      errorMessage.value = 'Informe o modelo do veículo.';
      return;
    }
    if (plate.isEmpty) {
      errorMessage.value = 'Informe a placa do veículo.';
      return;
    }
    final plateRegex = RegExp(r'^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$');
    if (!plateRegex.hasMatch(plate)) {
      errorMessage.value =
          'Placa inválida (utilize o padrão ABC1234 ou ABC1D23).';
      return;
    }
    if (capacity == null || capacity <= 0) {
      errorMessage.value =
          'Informe uma capacidade de passageiros maior que zero.';
      return;
    }

    isLoading.value = true;

    try {
      final vehiclePayload = VehicleModel(
        id: widget.initialVehicle?.id ?? '',
        companyCnpj: companyCnpj,
        plate: plate,
        model: model,
        brand: brand,
        capacity: capacity,
        color: color.isEmpty ? null : color,
        photoUrl: selectedImageFile?.path ?? widget.initialVehicle?.photoUrl,
        defaultDriverId: widget.initialVehicle?.defaultDriverId,
        isActive: widget.initialVehicle?.isActive ?? false,
      );

      final result = isEditing
          ? await vehicleViewModel.commands.updateVehicle(vehiclePayload)
          : await vehicleViewModel.commands.createVehicle(vehiclePayload);

      if (!context.mounted) return;

      if (result != null) {
        vehicleListViewModel.state.upsertVehicleInList(result);

        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Veículo atualizado com sucesso!'
                  : 'Veículo cadastrado com sucesso!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.fixed,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            duration: const Duration(seconds: 2),
          ),
        );
        context.pop(true);
      }
    } finally {
      if (mounted) {
        isLoading.value = false;
      }
    }
  }
}