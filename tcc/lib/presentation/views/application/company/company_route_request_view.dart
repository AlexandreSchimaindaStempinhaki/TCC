import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../domain/models/company_entity.dart';
import '../../../widgets/feedback/animated_three_dots.dart';
import '../../../widgets/company/company_requests_header_card.dart';
import '../../../widgets/routes/user_route_request_card.dart';
import '../../mixins/company_route_requests_logic.dart';

class CompanyRouteRequestsView extends StatefulWidget {
  final CompanyModel? company;

  const CompanyRouteRequestsView({
    super.key,
    this.company,
  });

  @override
  State<CompanyRouteRequestsView> createState() =>
      _CompanyRouteRequestsViewState();
}

class _CompanyRouteRequestsViewState extends State<CompanyRouteRequestsView>
    with CompanyRouteRequestsMixin {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final company = targetCompany;

    final Color solidBorderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFCBD5E1);
    final Color solidMutedSurface = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
          onPressed: () => handleBack(context),
          tooltip: 'Voltar',
        ),
        title: Column(
          children: [
            Text(
              'Solicitações de Vínculo',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (company != null && company.name.trim().isNotEmpty)
              Text(
                company.name,
                style: TextStyle(
                  color: colorScheme.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: Watch((context) {
        final loading = isLoading.value;
        final currentProcessing = processingKey.value;
        final routesWithRequests = getCompanyRoutes()
            .where((r) => r.pendingPassengerIds.isNotEmpty)
            .toList();

        final totalPendingCount = routesWithRequests.fold<int>(
          0,
          (sum, r) => sum + r.pendingPassengerIds.length,
        );

        if (loading) {
          return Center(
            child: AnimatedThreeDots(color: colorScheme.primary),
          );
        }

        return RefreshIndicator(
          onRefresh: loadRequests,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              if (company != null) ...[
                CompanyRequestsHeaderCard(
                  company: company,
                  formattedCnpj: formatCnpj(company.cnpj),
                  totalPendingCount: totalPendingCount,
                  borderColor: solidBorderColor,
                  mutedSurface: solidMutedSurface,
                ),
                const SizedBox(height: 20),
              ],
              if (routesWithRequests.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 48,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: solidBorderColor, width: 1.8),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: solidMutedSurface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.how_to_reg_rounded,
                          size: 32,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma solicitação pendente',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Quando passageiros solicitarem vínculo nas rotas desta empresa, os pedidos aparecerão aqui.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: colorScheme.secondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...routesWithRequests.map((route) {
                  final origin =
                      (route.originName != null &&
                          route.originName!.trim().isNotEmpty)
                      ? route.originName!
                      : 'Origem cadastrada';
                  final destination =
                      (route.destinationName != null &&
                          route.destinationName!.trim().isNotEmpty)
                      ? route.destinationName!
                      : 'Destino cadastrado';
                  final routeImage = resolveRouteImage(route, company);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: solidBorderColor,
                        width: 1.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox(
                                  width: 76,
                                  height: 76,
                                  child: Image.network(
                                    routeImage,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: solidMutedSurface,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.directions_bus_rounded,
                                        color: colorScheme.onSurface,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: CompanyRouteRequestsMixin
                                            .solidOrange,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${route.pendingPassengerIds.length} ${route.pendingPassengerIds.length == 1 ? 'Pendente' : 'Pendentes'}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.radio_button_checked_rounded,
                                          size: 13,
                                          color: colorScheme.onSurface,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            origin,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w500,
                                              color: colorScheme.secondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_rounded,
                                          size: 13,
                                          color: colorScheme.onSurface,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            destination,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          thickness: 1.2,
                          color: solidBorderColor,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                          child: Column(
                            children: route.pendingPassengerIds.map((
                              passengerId,
                            ) {
                              final profile =
                                  userProfilesCache[passengerId.trim()];
                              final displayName =
                                  (profile?['nome'] ??
                                          profile?['name'] ??
                                          'Passageiro')
                                      .toString();
                              final displayEmail =
                                  (profile?['email'] ?? '').toString();
                              final displayCpf =
                                  (profile?['cpf'] ?? '').toString();
                              final displayPhoto =
                                  (profile?['fotoUrl'] ??
                                          profile?['photoUrl'] ??
                                          '')
                                      .toString();
                              final isBusy =
                                  currentProcessing ==
                                  '${route.id}_$passengerId';

                              return UserRouteRequestCard(
                                displayName: displayName,
                                displayEmail: displayEmail,
                                displayCpf: displayCpf,
                                fallbackId: passengerId,
                                photoUrl: displayPhoto,
                                isBusy: isBusy,
                                surfaceColor: solidMutedSurface,
                                borderColor: solidBorderColor,
                                onApprove: () => confirmAndHandleDecision(
                                  route: route,
                                  passengerId: passengerId,
                                  passengerName: displayName,
                                  approve: true,
                                ),
                                onReject: () => confirmAndHandleDecision(
                                  route: route,
                                  passengerId: passengerId,
                                  passengerName: displayName,
                                  approve: false,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      }),
    );
  }
}