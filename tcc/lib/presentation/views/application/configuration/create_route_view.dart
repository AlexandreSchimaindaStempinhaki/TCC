import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../domain/models/company_entity.dart';
import '../../../../domain/models/route_entity.dart';
import '../../../widgets/account_option.dart';
import '../../../widgets/animated_three_dots.dart';
import '../../../widgets/header_background.dart';
import '../../../widgets/route_location_selector.dart';
import '../../../widgets/text_field.dart';
import '../../mixins/create_route_logic.dart';

class CreateRouteView extends StatefulWidget {
  final CompanyModel? company;
  final RouteModel? initialRoute;

  const CreateRouteView({
    super.key,
    this.company,
    this.initialRoute,
  });

  @override
  State<CreateRouteView> createState() => _CreateRouteViewState();
}

class _CreateRouteViewState extends State<CreateRouteView>
    with CreateRouteMixin {
  Widget _buildOuterFieldLabel(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, left: 4.0),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildOperatingDaysSection(
    BuildContext context,
    List<int> selectedDays,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isMonToFri =
        selectedDays.length == 5 &&
        selectedDays.every((d) => d >= 1 && d <= 5);
    final isEveryDay = selectedDays.length == 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOuterFieldLabel(context, 'Dias de Operação'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Botões dos 7 dias da semana (Seg a Dom)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: CreateRouteMixin.weekDaysList.map((item) {
                  final dayNum = item['day'] as int;
                  final shortLabel = item['short'] as String;
                  final isSelected = selectedDays.contains(dayNum);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => toggleOperatingDay(dayNum),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primary
                                : theme.scaffoldBackgroundColor.withOpacity(
                                    0.6,
                                  ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : theme.dividerColor.withOpacity(0.5),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            shortLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              // Atalhos rápidos: Segunda a Sexta / Todos os dias
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: selectMondayToFriday,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isMonToFri
                            ? colorScheme.primary.withOpacity(0.1)
                            : Colors.transparent,
                        side: BorderSide(
                          color: isMonToFri
                              ? colorScheme.primary
                              : theme.dividerColor.withOpacity(0.6),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Segunda a Sexta',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isMonToFri
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: selectAllWeekDays,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isEveryDay
                            ? colorScheme.primary.withOpacity(0.1)
                            : Colors.transparent,
                        side: BorderSide(
                          color: isEveryDay
                              ? colorScheme.primary
                              : theme.dividerColor.withOpacity(0.6),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Todos os dias',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isEveryDay
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSchedulesSection(
    BuildContext context,
    List<DateTime> currentSchedules,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOuterFieldLabel(context, 'Horários de Saída'),
        Container(
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              if (currentSchedules.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: theme.dividerColor.withOpacity(0.4),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 32,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nenhum horário adicionado',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Toque abaixo para adicionar os horários de saída.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Column(
                    children: List.generate(currentSchedules.length, (index) {
                      final dt = currentSchedules[index];
                      final timeStr = formatScheduleTime(dt);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => editScheduleAt(context, index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor.withOpacity(
                                0.6,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.dividerColor.withOpacity(0.45),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 22,
                                  color: colorScheme.onSurface,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    timeStr,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => removeScheduleAt(index),
                                  tooltip: 'Remover horário',
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.redAccent,
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              AccountOption(
                icon: Icons.add_alarm_rounded,
                title: 'Adicionar Novo Horário',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => pickAndAddSchedule(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inverseColor = colorScheme.onSurface;
    final currentImageUrl =
        widget.initialRoute?.imageUrl ?? targetCompany?.logoUrl;

    ImageProvider? avatarImage;
    if (selectedImageFile != null) {
      avatarImage = FileImage(selectedImageFile!);
    } else if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
      avatarImage = NetworkImage(currentImageUrl);
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
                    isEditing ? 'Editar  Rota' : 'Cadastrar  Rota',
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
                        ? 'Atualize os nomes, localizações no mapa, dias da semana e horários da rota abaixo.'
                        : 'Defina o ponto de saída, o destino, os dias da semana e os horários para registrar uma nova rota no Índigo.',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.secondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SELETOR DE FOTO DA ROTA NO PADRÃO DA EMPRESA
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: pickRouteImage,
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
                            onPressed: pickRouteImage,
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
                                  ? 'Escolher Foto da Rota (Opcional)'
                                  : 'Trocar Foto da Rota',
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
                        hintText: 'Empresa responsável pela rota',
                        controller: companyNameController,
                        keyboardType: TextInputType.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 1. NOME E GEOLOCALIZAÇÃO DO PONTO DE SAÍDA (ORIGEM)
                  CustomTextField(
                    label: 'Nome do Ponto de Saída',
                    hintText: 'Ex: Terminal Central / Av. das Magnólias',
                    controller: originNameController,
                    keyboardType: TextInputType.text,
                    inputFormatters: [AppFormatters.nameLimit(60)],
                  ),
                  const SizedBox(height: 16),
                  Watch((context) {
                    return RouteLocationSelector(
                      label: 'Localização do Ponto de Saída',
                      geoPoint: originPoint.value,
                      isLoadingGps: isLoadingOriginGps.value,
                      onViewOnMap: () =>
                          viewLocationOnMap(context, isOrigin: true),
                      onGetGps: () => getCurrentLocation(isOrigin: true),
                      onPickOnMap: () =>
                          pickLocationOnMap(context, isOrigin: true),
                    );
                  }),
                  const SizedBox(height: 28),

                  // 2. NOME E GEOLOCALIZAÇÃO DO DESTINO DA ROTA
                  CustomTextField(
                    label: 'Nome do Destino da Rota',
                    hintText: 'Ex: IFPR Paranaguá / Campus Universitário',
                    controller: destinationNameController,
                    keyboardType: TextInputType.text,
                    inputFormatters: [AppFormatters.nameLimit(60)],
                  ),
                  const SizedBox(height: 16),
                  Watch((context) {
                    return RouteLocationSelector(
                      label: 'Localização do Destino',
                      geoPoint: destinationPoint.value,
                      isLoadingGps: isLoadingDestGps.value,
                      onViewOnMap: () =>
                          viewLocationOnMap(context, isOrigin: false),
                      onGetGps: () => getCurrentLocation(isOrigin: false),
                      onPickOnMap: () =>
                          pickLocationOnMap(context, isOrigin: false),
                    );
                  }),

                  // OPÇÃO DE VER TRAJETO COMPLETO NO MAPA (ROUTE_MAP_VIEW)
                  Watch((context) {
                    final hasBothPoints =
                        originPoint.value != null &&
                        destinationPoint.value != null;

                    if (!hasBothPoints) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.35),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: AccountOption(
                          icon: Icons.route_rounded,
                          title: 'Visualizar Trajeto da Rota no Mapa',
                          iconColor: colorScheme.primary,
                          textColor: colorScheme.primary,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: colorScheme.primary,
                          ),
                          onTap: () => viewFullRouteOnMap(context),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 28),

                  // 3. DIAS DA SEMANA DE OPERAÇÃO
                  Watch((context) {
                    return _buildOperatingDaysSection(
                      context,
                      operatingDays.value,
                    );
                  }),
                  const SizedBox(height: 28),

                  // 4. HORÁRIOS DE SAÍDA LIMPOS
                  Watch((context) {
                    return _buildSchedulesSection(
                      context,
                      schedules.value,
                    );
                  }),

                  // MENSAGEM DE ERRO
                  Watch((context) {
                    final localError = errorMessage.value;
                    final vmError = routeViewModel.state.message.value;
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

                  // BOTÃO DE SALVAR/CADASTRAR ROTA
                  Watch(
                    (context) => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading.value
                            ? null
                            : () => submitForm(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading.value
                            ? AnimatedThreeDots(color: colorScheme.onSurface)
                            : Text(
                                isEditing
                                    ? 'Salvar Alterações'
                                    : 'Cadastrar Rota',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
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