import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/routes/indigo_routes.dart';
import '../../../../domain/models/company_entity.dart';
import '../../../../domain/models/route_entity.dart';
import '../../../widgets/account_option.dart';
import '../../../widgets/animated_three_dots.dart';
import '../../../widgets/route_itinerary_card.dart';
import '../../mixins/route_entered_logic.dart';

class RouteEnteredView extends StatefulWidget {
  final RouteModel route;
  final CompanyModel? company;
  final String? roleBadge;

  const RouteEnteredView({
    super.key,
    required this.route,
    this.company,
    this.roleBadge,
  });

  @override
  State<RouteEnteredView> createState() => _RouteEnteredViewState();
}

class _RouteEnteredViewState extends State<RouteEnteredView>
    with RouteEnteredMixin {
  List<String> _resolveShifts(RouteModel r) {
    if (r.schedules.isEmpty) return const ['Horários sob consulta'];
    return r.schedules.map((dt) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      final timeStr = '$h:$m';
      if (dt.hour >= 5 && dt.hour < 12) return 'Manhã ($timeStr)';
      if (dt.hour >= 12 && dt.hour < 18) return 'Tarde ($timeStr)';
      if (dt.hour >= 18) return 'Noite ($timeStr)';
      return 'Madrugada ($timeStr)';
    }).toList();
  }

  Widget _buildRawImage(
    String imageUrl,
    ColorScheme colorScheme, {
    required BoxFit fit,
  }) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          color: colorScheme.primary.withOpacity(0.08),
          alignment: Alignment.center,
          child: Icon(
            Icons.directions_bus_rounded,
            size: 48,
            color: colorScheme.primary,
          ),
        ),
      );
    }
    return Image.file(
      File(imageUrl),
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        color: colorScheme.primary.withOpacity(0.08),
        alignment: Alignment.center,
        child: Icon(
          Icons.directions_bus_rounded,
          size: 48,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Watch((context) {
      final loading = isLoading.value;
      final executing = isActionExecuting.value;
      final route = currentRoute;
      final company = currentCompany;
      final routeActive = isRouteActiveNow;

      final staff = isStaffRole;
      final hasCnh = hasValidCnh;
      final canDrive = canDriveRoute;
      final isPassenger = isPassengerInRoute;

      final currentBoarding = boardingViewModel.state.currentBoarding.value;
      final isReady = currentBoarding?.isReadyForBoarding ?? false;
      final myStop = currentUserStop;

      final imageUrl =
          (route.imageUrl != null && route.imageUrl!.trim().isNotEmpty)
              ? route.imageUrl!.trim()
              : ((company?.logoUrl != null && company!.logoUrl!.trim().isNotEmpty)
                  ? company!.logoUrl!.trim()
                  : '');

      final companyName = (company?.name.trim().isNotEmpty == true)
          ? company!.name.trim()
          : 'Transporte Contratual';

      final originText =
          (route.originName != null && route.originName!.trim().isNotEmpty)
              ? route.originName!
              : 'Local de Partida';

      final destinationText =
          (route.destinationName != null && route.destinationName!.trim().isNotEmpty)
              ? route.destinationName!
              : 'Local de Destino';

      final operatingDaysText = route.operatingDaysLabel;
      final currentShifts = _resolveShifts(route);

      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: colorScheme.onSurface,
            ),
            onPressed: () {
              if (context.canPop()) context.pop();
            },
          ),
          title: Text(
            'Painel da Rota',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: loading
            ? Center(
                child: AnimatedThreeDots(color: colorScheme.onSurface),
              )
            : RefreshIndicator(
                color: colorScheme.onSurface,
                onRefresh: loadInitialData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ================= CARD DA ROTA (COM IMAGEM, BLUR E NOME DA EMPRESA) =================
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? colorScheme.onSurface.withOpacity(0.24)
                                : colorScheme.onSurface.withOpacity(0.16),
                            width: 1.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(18),
                                  ),
                                  child: SizedBox(
                                    height: 155,
                                    width: double.infinity,
                                    child: imageUrl.isEmpty
                                        ? Container(
                                            color: colorScheme.primary.withOpacity(0.08),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              Icons.route_rounded,
                                              size: 48,
                                              color: colorScheme.primary,
                                            ),
                                          )
                                        : Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              ImageFiltered(
                                                imageFilter: ImageFilter.blur(
                                                  sigmaX: 16,
                                                  sigmaY: 16,
                                                ),
                                                child: _buildRawImage(
                                                  imageUrl,
                                                  colorScheme,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Container(
                                                color: Colors.black.withOpacity(
                                                  isDark ? 0.25 : 0.12,
                                                ),
                                              ),
                                              _buildRawImage(
                                                imageUrl,
                                                colorScheme,
                                                fit: BoxFit.contain,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                if (widget.roleBadge != null)
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        widget.roleBadge!,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    companyName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  
                                  // ================= 1. STATUS PARA PASSAGEIRO =================
                                  if (isPassenger) ...[
                                    const SizedBox(height: 16),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: routeActive
                                                ? const Color(0xFF16A34A)
                                                : colorScheme.onSurfaceVariant,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          routeActive
                                              ? 'Rota ativa no momento'
                                              : 'A rota ainda não foi iniciada',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: routeActive
                                                ? const Color(0xFF16A34A)
                                                : colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (routeActive &&
                                        myStop?.estimatedMinutesRemaining !=
                                            null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Chegada estimada no seu ponto: ~${myStop!.estimatedMinutesRemaining} min (Parada #${myStop.orderIndex})',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ],

                                  // ================= 2. PAINEL DO MOTORISTA / GESTOR =================
                                  if (staff) ...[
                                    const SizedBox(height: 16),
                                    Divider(
                                      color: theme.dividerColor.withOpacity(0.5),
                                      height: 1,
                                    ),
                                    const SizedBox(height: 14),
                                    if (!hasCnh)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.amber.shade700
                                                .withOpacity(0.4),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.badge_outlined,
                                              size: 20,
                                              color: Colors.amber.shade800,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Cadastre sua CNH no seu perfil para poder iniciar esta rota.',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: colorScheme.onSurface,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else if (canDrive) ...[
                                      SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: ElevatedButton.icon(
                                          onPressed: executing
                                              ? null
                                              : (routeActive
                                                  ? () {
                                                      openLiveMap(context);
                                                    }
                                                  : startOptimizedRouteTrip),
                                          icon: Icon(
                                            routeActive
                                                ? Icons.navigation_rounded
                                                : Icons.play_arrow_rounded,
                                            color: Colors.white,
                                          ),
                                          label: Text(
                                            routeActive
                                                ? 'Abrir Rota Ativa (Modo Uber)'
                                                : 'Iniciar a Rota',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: routeActive
                                                ? const Color(0xFF16A34A)
                                                : colorScheme.primary,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ================= ITINERÁRIO CARD TOPZERA =================
                      RouteItineraryCard(
                        origin: originText,
                        destination: destinationText,
                        operatingDays: operatingDaysText,
                        shifts: currentShifts,
                      ),
                      const SizedBox(height: 16),

                      // ================= 3. AÇÕES INFERIORES =================
                      Container(
                        clipBehavior: Clip.antiAlias,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
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
                            if (isPassenger && routeActive) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  4,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: executing
                                        ? null
                                        : togglePassengerReady,
                                    icon: Icon(
                                      isReady
                                          ? Icons.check_circle_rounded
                                          : Icons.hail_rounded,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      isReady
                                          ? 'Estou Pronto (Confirmado)'
                                          : 'Confirmar que estou no ponto',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isReady
                                          ? const Color(0xFF16A34A)
                                          : colorScheme.primary,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            AccountOption(
                              icon: Icons.calendar_month_outlined,
                              title: 'Calendário de Presença',
                              trailing: const SizedBox.shrink(),
                              onTap: () async {
                                // await context.pushNamed(
                                //   IndigoRouteNames.routeCalendar,
                                //   extra: {
                                //     'route': route,
                                //     'company': company,
                                //   },
                                // );
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      );
    });
  }
}