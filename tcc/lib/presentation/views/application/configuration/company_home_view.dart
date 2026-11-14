import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../domain/models/company_entity.dart';
import '../../../widgets/account_option.dart';
import '../../../widgets/animated_three_dots.dart';
import '../../mixins/company_home_logic.dart';

class CompanyHomeView extends StatefulWidget {
  final CompanyModel? initialCompany;

  const CompanyHomeView({super.key, this.initialCompany});

  @override
  State<CompanyHomeView> createState() => _CompanyHomeViewState();
}

class _CompanyHomeViewState extends State<CompanyHomeView>
    with CompanyHomeMixin {
  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    double topPadding = 24,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPadding, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildCopyableInfoRow(
    BuildContext context, {
    required IconData icon,
    required String displayText,
    required String copyLabel,
    required String rawValueToCopy,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => copyToClipboard(context, copyLabel, rawValueToCopy),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.copy_rounded,
              size: 15,
              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Watch((context) {
      final isLoading = isInitialLoading.value;
      final company =
          companyViewModel.state.selectedCompany.value ?? widget.initialCompany;

      return AbsorbPointer(
        absorbing: isDeleting,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: colorScheme.onSurface,
              ),
              onPressed: () => handleBack(context),
            ),
            title: Text(
              'Painel da Empresa',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
          ),
          body: isLoading
              ? Center(
                  child: AnimatedThreeDots(color: colorScheme.onSurface),
                )
              : company == null
                  ? Center(
                      child: Text(
                        'Nenhuma empresa selecionada.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ================= CARD UNIFICADO DA EMPRESA =================
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: theme.dividerColor.withOpacity(0.5),
                              ),
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
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 36,
                                      backgroundColor: colorScheme.onSurface
                                          .withOpacity(0.1),
                                      backgroundImage: (company.logoUrl !=
                                                  null &&
                                              company.logoUrl!.isNotEmpty)
                                          ? NetworkImage(company.logoUrl!)
                                          : null,
                                      child: (company.logoUrl == null ||
                                              company.logoUrl!.isEmpty)
                                          ? Icon(
                                              Icons.domain_rounded,
                                              size: 36,
                                              color: colorScheme.onSurface,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            company.name,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          InkWell(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            onTap: () => copyToClipboard(
                                              context,
                                              'CNPJ',
                                              company.cnpj,
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 2,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      'CNPJ: ${formatCnpj(company.cnpj)}',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Icon(
                                                    Icons.copy_rounded,
                                                    size: 14,
                                                    color: colorScheme
                                                        .onSurfaceVariant
                                                        .withOpacity(0.7),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Divider(
                                  color: theme.dividerColor.withOpacity(0.5),
                                  height: 1,
                                ),
                                const SizedBox(height: 10),

                                // E-mail e Telefone copiáveis
                                _buildCopyableInfoRow(
                                  context,
                                  icon: Icons.email_outlined,
                                  displayText: company.email,
                                  copyLabel: 'E-mail',
                                  rawValueToCopy: company.email,
                                ),
                                const SizedBox(height: 2),
                                _buildCopyableInfoRow(
                                  context,
                                  icon: Icons.phone_outlined,
                                  displayText: formatPhone(company.phone),
                                  copyLabel: 'Telefone',
                                  rawValueToCopy: company.phone,
                                ),

                                const SizedBox(height: 14),

                                // Barra integrada de Equipe e Reputação
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.scaffoldBackgroundColor
                                        .withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color:
                                          theme.dividerColor.withOpacity(0.35),
                                    ),
                                  ),
                                  child: IntrinsicHeight(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            onTap: () => showComingSoon(
                                              context,
                                              'Motoristas e Membros',
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.people_alt_outlined,
                                                  size: 20,
                                                  color: colorScheme.onSurface,
                                                ),
                                                const SizedBox(width: 10),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      '${company.memberIds.length} ${company.memberIds.length == 1 ? 'membro' : 'membros'}',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: colorScheme
                                                            .onSurface,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        VerticalDivider(
                                          color: theme.dividerColor
                                              .withOpacity(0.6),
                                          thickness: 1,
                                          width: 24,
                                        ),
                                        Expanded(
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            onTap: () => showComingSoon(
                                              context,
                                              'Avaliações e Feedbacks',
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.star_rounded,
                                                  size: 22,
                                                  color: Colors.amber.shade700,
                                                ),
                                                const SizedBox(width: 8),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      company.ratingCount > 0
                                                          ? '${company.rating.toStringAsFixed(1)} de 5.0'
                                                          : 'Sem nota',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: colorScheme
                                                            .onSurface,
                                                      ),
                                                    ),
                                                    Text(
                                                      company.ratingCount == 1
                                                          ? '1 avaliação'
                                                          : '${company.ratingCount} avaliações',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: colorScheme
                                                            .onSurfaceVariant,
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
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ================= MENU DE OPERAÇÃO E GESTÃO =================
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
                                // --- SEÇÃO: OPERAÇÃO DE TRANSPORTE ---
                                _buildSectionTitle(
                                  context,
                                  'Operação',
                                  topPadding: 16,
                                ),

                                AccountOption(
                                  icon: Icons.route_outlined,
                                  title: 'Rotas e Itinerários',
                                  onTap: () => showComingSoon(
                                    context,
                                    'Rotas e Itinerários',
                                  ),
                                ),
                                const SizedBox(height: 8),

                                AccountOption(
                                  icon: Icons.directions_bus_outlined,
                                  title: 'Viagens e Horários',
                                  onTap: () => showComingSoon(
                                    context,
                                    'Viagens e Horários',
                                  ),
                                ),
                                const SizedBox(height: 8),

                                AccountOption(
                                  icon: Icons.location_on_outlined,
                                  title: 'Pontos de Embarque',
                                  onTap: () => showComingSoon(
                                    context,
                                    'Pontos de Embarque',
                                  ),
                                ),

                                // --- SEÇÃO: EQUIPE E PASSAGEIROS ---
                                _buildSectionTitle(
                                  context,
                                  'Equipe e Clientes',
                                ),

                                AccountOption(
                                  icon: Icons.badge_outlined,
                                  title: 'Motoristas e Membros',
                                  onTap: () => showComingSoon(
                                    context,
                                    'Motoristas e Membros',
                                  ),
                                ),
                                const SizedBox(height: 8),

                                AccountOption(
                                  icon: Icons.people_outline_rounded,
                                  title: 'Passageiros Vinculados',
                                  onTap: () => showComingSoon(
                                    context,
                                    'Passageiros Vinculados',
                                  ),
                                ),
                                const SizedBox(height: 8),

                                AccountOption(
                                  icon: Icons.star_outline_rounded,
                                  title: 'Avaliações e Feedbacks',
                                  onTap: () => showComingSoon(
                                    context,
                                    'Avaliações e Feedbacks',
                                  ),
                                ),

                                // --- SEÇÃO: ADMINISTRAÇÃO ---
                                _buildSectionTitle(context, 'Administração'),

                                AccountOption(
                                  icon: Icons.edit_note_rounded,
                                  title: 'Editar Dados da Empresa',
                                  onTap: () => openEditCompany(company),
                                ),
                                const SizedBox(height: 8),

                                AccountOption(
                                  icon: Icons.delete_outline_rounded,
                                  title: 'Excluir Empresa',
                                  iconColor: Colors.redAccent,
                                  textColor: Colors.redAccent,
                                  trailing: isDeleting
                                      ? const AnimatedThreeDots(
                                          color: Colors.redAccent,
                                        )
                                      : null,
                                  onTap: () => confirmAndDeleteCompany(
                                    context,
                                    company,
                                  ),
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