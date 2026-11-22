import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/routes/account_routes.dart';
import '../../../core/routes/company_routes.dart';
import '../../../core/routes/home_routes.dart';
import '../../../domain/models/company_entity.dart';
import '../../../domain/models/route_entity.dart';
import '../../controllers/company/company_viewmodel.dart';
import '../../controllers/route/route_list_viewmodel.dart';
import '../../controllers/route/route_viewmodel.dart';
import '../application/routes/create_route_view.dart';

mixin CreateRouteMixin on State<CreateRouteView> {
  late final RouteViewModel routeViewModel;
  late final RouteListViewModel routeListViewModel;
  late final CompanyViewModel companyViewModel;

  final companyNameController = TextEditingController();
  final originNameController = TextEditingController();
  final destinationNameController = TextEditingController();

  File? selectedImageFile;

  final originPoint = signal<GeoPoint?>(null);
  final destinationPoint = signal<GeoPoint?>(null);
  final isLoadingOriginGps = signal(false);
  final isLoadingDestGps = signal(false);
  final operatingDays = signal<List<int>>([1, 2, 3, 4, 5]);
  final schedules = signal<List<DateTime>>([]);

  final isLoading = signal(false);
  final errorMessage = signal<String?>(null);

  bool get isEditing => widget.initialRoute != null;

  CompanyModel? get targetCompany =>
      widget.company ??
      widget.initialRoute?.company ??
      companyViewModel.state.selectedCompany.value;

  static const List weekDaysList = [
    {'day': 1, 'short': 'Seg', 'full': 'Segunda'},
    {'day': 2, 'short': 'Ter', 'full': 'Terça'},
    {'day': 3, 'short': 'Qua', 'full': 'Quarta'},
    {'day': 4, 'short': 'Qui', 'full': 'Quinta'},
    {'day': 5, 'short': 'Sex', 'full': 'Sexta'},
    {'day': 6, 'short': 'Sáb', 'full': 'Sábado'},
    {'day': 7, 'short': 'Dom', 'full': 'Domingo'},
  ];

  @override
  void initState() {
    super.initState();
    routeViewModel = injector.get<RouteViewModel>();
    routeListViewModel = injector.get<RouteListViewModel>();
    companyViewModel = injector.get<CompanyViewModel>();

    routeViewModel.state.clearMessage();

    final company = targetCompany;
    companyNameController.text =
        company?.name ?? widget.initialRoute?.companyCnpj ?? '';

    if (isEditing) {
      final route = widget.initialRoute!;
      originNameController.text = route.originName ?? '';
      destinationNameController.text = route.destinationName ?? '';
      originPoint.value = route.origin;
      destinationPoint.value = route.destination;
      operatingDays.value = List<int>.from(route.operatingDays)..sort();
      schedules.value = List<DateTime>.from(route.schedules);
    }
  }

  @override
  void dispose() {
    companyNameController.dispose();
    originNameController.dispose();
    destinationNameController.dispose();
    originPoint.dispose();
    destinationPoint.dispose();
    isLoadingOriginGps.dispose();
    isLoadingDestGps.dispose();
    operatingDays.dispose();
    schedules.dispose();
    isLoading.dispose();
    errorMessage.dispose();
    super.dispose();
  }

  Future<void> pickRouteImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> getCurrentLocation({required bool isOrigin}) async {
    final loadingSignal = isOrigin ? isLoadingOriginGps : isLoadingDestGps;
    if (loadingSignal.value) return;

    loadingSignal.value = true;
    errorMessage.value = null;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          showTopSnackBar(
            context,
            'O GPS do aparelho está desativado.',
            isError: true,
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            showTopSnackBar(
              context,
              'Permissão de localização negada.',
              isError: true,
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          showTopSnackBar(
            context,
            'Permissões de localização negadas permanentemente.',
            isError: true,
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final newGeoPoint = GeoPoint(position.latitude, position.longitude);
      if (isOrigin) {
        originPoint.value = newGeoPoint;
      } else {
        destinationPoint.value = newGeoPoint;
      }

      if (mounted) {
        showTopSnackBar(
          context,
          isOrigin
              ? 'Ponto de saída atualizado via GPS!'
              : 'Ponto de destino atualizado via GPS!',
        );
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(
          context,
          'Erro ao obter localização: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        loadingSignal.value = false;
      }
    }
  }

  Future<void> pickLocationOnMap(
    BuildContext context, {
    required bool isOrigin,
  }) async {
    final initialLocation = isOrigin
        ? originPoint.value
        : destinationPoint.value;

    final LatLng? pickedLocation = await context.pushNamed<LatLng>(
      AccountRouteNames.locationPicker,
      extra: initialLocation,
    );

    if (pickedLocation != null) {
      final newGeoPoint = GeoPoint(
        pickedLocation.latitude,
        pickedLocation.longitude,
      );

      if (isOrigin) {
        originPoint.value = newGeoPoint;
      } else {
        destinationPoint.value = newGeoPoint;
      }

      errorMessage.value = null;
      if (context.mounted) {
        showTopSnackBar(
          context,
          isOrigin
              ? 'Ponto de saída escolhido no mapa!'
              : 'Ponto de destino escolhido no mapa!',
        );
      }
    }
  }

  void viewLocationOnMap(
    BuildContext context, {
    required bool isOrigin,
  }) {
    final geoPoint = isOrigin ? originPoint.value : destinationPoint.value;
    if (geoPoint == null) return;

    final customTitle = isOrigin
        ? originNameController.text.trim()
        : destinationNameController.text.trim();

    context.pushNamed(
      AccountRouteNames.singleLocationMap,
      extra: {
        'latitude': geoPoint.latitude,
        'longitude': geoPoint.longitude,
        'title': customTitle.isNotEmpty
            ? customTitle
            : (isOrigin ? 'Ponto de Saída' : 'Destino da Rota'),
      },
    );
  }

  void viewFullRouteOnMap(BuildContext context) {
    final start = originPoint.value;
    final end = destinationPoint.value;
    if (start == null || end == null) return;

    final originText = originNameController.text.trim();
    final destText = destinationNameController.text.trim();

    final routeData = <String, dynamic>{
      'startLatitude': start.latitude,
      'startLongitude': start.longitude,
      'endLatitude': end.latitude,
      'endLongitude': end.longitude,
      'origin': originText.isNotEmpty
          ? originText
          : 'Lat: ${start.latitude.toStringAsFixed(4)}, Lng:${start.longitude.toStringAsFixed(4)}',
      'destination': destText.isNotEmpty
          ? destText
          : 'Lat: ${end.latitude.toStringAsFixed(4)}, Lng:${end.longitude.toStringAsFixed(4)}',
      'companyName': targetCompany?.name ?? 'Trajeto da Rota',
    };

    context.pushNamed(HomeRouteNames.routeMap, extra: routeData);
  }

  void toggleOperatingDay(int weekday) {
    final current = Set<int>.from(operatingDays.value);
    if (current.contains(weekday)) {
      current.remove(weekday);
    } else {
      current.add(weekday);
    }
    final sorted = current.toList()..sort();
    operatingDays.value = sorted;
    if (sorted.isNotEmpty) {
      errorMessage.value = null;
    }
  }

  void selectMondayToFriday() {
    operatingDays.value = [1, 2, 3, 4, 5];
    errorMessage.value = null;
  }

  void selectAllWeekDays() {
    operatingDays.value = [1, 2, 3, 4, 5, 6, 7];
    errorMessage.value = null;
  }

  void _sortAndSaveSchedules(List<DateTime> list) {
    list.sort(
      (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
    );
    schedules.value = list;
  }

  Future<void> pickAndAddSchedule(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Adicionar horário de saída',
      cancelText: 'Cancelar',
      confirmText: 'Adicionar',
    );

    if (picked == null) return;

    final now = DateTime.now();
    final newSchedule = DateTime(
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );

    final alreadyExists = schedules.value.any(
      (dt) => dt.hour == newSchedule.hour && dt.minute == newSchedule.minute,
    );

    if (alreadyExists) {
      errorMessage.value = 'Este horário já foi adicionado na rota.';
      return;
    }

    errorMessage.value = null;
    _sortAndSaveSchedules([...schedules.value, newSchedule]);
  }

  Future<void> editScheduleAt(BuildContext context, int index) async {
    FocusScope.of(context).unfocus();
    final current = schedules.value[index];

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: 'Editar horário de saída',
      cancelText: 'Cancelar',
      confirmText: 'Salvar',
    );

    if (picked == null) return;

    final duplicateIndex = schedules.value.indexWhere(
      (dt) => dt.hour == picked.hour && dt.minute == picked.minute,
    );

    if (duplicateIndex != -1 && duplicateIndex != index) {
      errorMessage.value = 'Este horário já existe na lista.';
      return;
    }

    final now = DateTime.now();
    final updatedList = List<DateTime>.from(schedules.value);
    updatedList[index] = DateTime(
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );

    errorMessage.value = null;
    _sortAndSaveSchedules(updatedList);
  }

  void removeScheduleAt(int index) {
    final updated = List<DateTime>.from(schedules.value)..removeAt(index);
    schedules.value = updated;
  }

  String formatScheduleTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool validateFields() {
    final companyCnpj =
        targetCompany?.cnpj ?? widget.initialRoute?.companyCnpj ?? '';

    if (companyCnpj.trim().isEmpty) {
      errorMessage.value = 'Empresa vinculada não identificada.';
      return false;
    }

    if (originNameController.text.trim().isEmpty) {
      errorMessage.value = 'Informe o nome do ponto de saída.';
      return false;
    }

    if (originPoint.value == null) {
      errorMessage.value =
          'Selecione a localização do ponto de saída no mapa ou GPS.';
      return false;
    }

    if (destinationNameController.text.trim().isEmpty) {
      errorMessage.value = 'Informe o nome do destino da rota.';
      return false;
    }

    if (destinationPoint.value == null) {
      errorMessage.value =
          'Selecione a localização do destino no mapa ou GPS.';
      return false;
    }

    if (operatingDays.value.isEmpty) {
      errorMessage.value = 'Selecione pelo menos um dia da semana de operação.';
      return false;
    }

    if (schedules.value.isEmpty) {
      errorMessage.value =
          'Adicione pelo menos um horário de saída para a rota.';
      return false;
    }

    errorMessage.value = null;
    return true;
  }

  void handleBack(BuildContext context, [bool changed = false]) {
    routeViewModel.state.clearMessage();
    if (context.canPop()) {
      context.pop(changed);
    } else {
      context.goNamed(CompanyRouteNames.companyHome, extra: targetCompany);
    }
  }

  void showTopSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomMargin = context.screenHeight - topPadding - 150;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.redAccent : Colors.green,
          elevation: 6,
          margin: EdgeInsets.only(
            bottom: bottomMargin > 0 ? bottomMargin : 20,
            left: 20,
            right: 20,
          ),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> submitForm(BuildContext context) async {
    FocusScope.of(context).unfocus();
    routeViewModel.state.clearMessage();
    errorMessage.value = null;

    if (!validateFields()) return;

    final company = targetCompany;
    final rawCnpj = (company?.cnpj ?? widget.initialRoute?.companyCnpj ?? '')
        .replaceAll(RegExp(r'\D'), '');

    final cleanOriginName = originNameController.text.trim();
    final cleanDestName = destinationNameController.text.trim();

    try {
      isLoading.value = true;
      bool success = false;

      if (isEditing) {
        final routeToUpdate = widget.initialRoute!.copyWith(
          companyCnpj: rawCnpj,
          origin: originPoint.value!,
          destination: destinationPoint.value!,
          originName: cleanOriginName,
          destinationName: cleanDestName,
          operatingDays: List<int>.from(operatingDays.value),
          schedules: List<DateTime>.from(schedules.value),
          company: company ?? widget.initialRoute!.company,
        );

        success = await routeViewModel.commands.updateRoute(
          routeToUpdate,
          imageFile: selectedImageFile,
        );
      } else {
        final newRoute = RouteModel(
          id: DateTime.now().millisecondsSinceEpoch,
          companyCnpj: rawCnpj,
          origin: originPoint.value!,
          destination: destinationPoint.value!,
          originName: cleanOriginName,
          destinationName: cleanDestName,
          operatingDays: List<int>.from(operatingDays.value),
          schedules: List<DateTime>.from(schedules.value),
          imageUrl: company?.logoUrl,
          company: company,
        );

        success = await routeViewModel.commands.createRoute(
          newRoute,
          imageFile: selectedImageFile,
        );
      }

      if (!success) {
        errorMessage.value =
            routeViewModel.state.message.value ??
            (isEditing
                ? 'Não foi possível atualizar a rota.'
                : 'Não foi possível cadastrar a rota.');
        return;
      }

      final savedRoute = routeViewModel.state.route.value;
      if (savedRoute != null) {
        routeListViewModel.state.upsertRoute(savedRoute);
      }

      try {
        await routeListViewModel.commands.fetchRoutesByCompany(rawCnpj);
        await routeListViewModel.commands.fetchAllRoutes();
      } catch (_) {}

      if (!context.mounted) return;

      showTopSnackBar(
        context,
        isEditing
            ? 'Rota atualizada com sucesso!'
            : 'Rota cadastrada com sucesso!',
      );

      handleBack(context, true);
    } catch (e) {
      errorMessage.value = 'Erro inesperado: $e';
    } finally {
      if (mounted) {
        isLoading.value = false;
      }
    }
  }
}