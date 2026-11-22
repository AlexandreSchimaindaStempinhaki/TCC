import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/theme/theme_controller.dart';
import 'package:tcc/presentation/widgets/nav_bar.dart';
import 'package:tcc/presentation/widgets/account_option.dart';
import 'package:tcc/presentation/widgets/logout_confirmation.dart';
import 'package:tcc/presentation/widgets/animated_three_dots.dart';
import '../../../../core/routes/auth_routes.dart';
import '../../../../core/routes/indigo_routes.dart';
import '../../../controllers/authentication/auth_session_viewmodel.dart';
import '../../../controllers/company/company_list_viewmodel.dart';
import '../../../controllers/notifications/notification_viewmodel.dart';
import '../../../controllers/user/user_viewmodel.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  late final AuthViewModel authController;
  late final UserViewModel _userViewModel;
  late final CompanyListViewModel _companyListViewModel;
  late final NotificationViewModel _notificationViewModel;

  final _isInitialLoading = signal(true);
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    authController = injector.get<AuthViewModel>();
    _userViewModel = injector.get<UserViewModel>();
    _companyListViewModel = injector.get<CompanyListViewModel>();
    _notificationViewModel = injector.get<NotificationViewModel>();

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _isInitialLoading.value = true;
    await Future.wait([
      _userViewModel.commands.fetchUser(),
      _companyListViewModel.commands.fetchOwnedCompanies(),
      _companyListViewModel.commands.fetchMemberCompanies(),
    ]);

    // Apenas sincroniza a sessão se o usuário já tiver ativado as notificações antes
    // (não abre o popup de permissão automaticamente ao entrar na tela).
    final currentUser = _userViewModel.state.user.value;
    if (_notificationViewModel.state.isEnabled.value) {
      await _notificationViewModel.commands.syncUserSession(
        cpf: currentUser?.cpf,
        requestPermission: false,
      );
    }

    if (mounted) {
      _isInitialLoading.value = false;
    }
  }

  Future<void> _handleToggleNotifications(bool val) async {
    final currentUser = _userViewModel.state.user.value;

    // Quando val == true, dispara o popup padrão do Android pedindo permissão.
    final success = await _notificationViewModel.commands.toggleNotifications(
      enable: val,
      cpf: currentUser?.cpf,
    );

    if (!mounted) return;
    if (val && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permissão de notificações negada. Ative nas configurações do aparelho para receber alertas.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _isInitialLoading.dispose();
    super.dispose();
  }

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
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeController = injector.get<ThemeController>();

    return AbsorbPointer(
      absorbing: _isLoggingOut,
      child: Scaffold(
        extendBody: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        bottomNavigationBar: const BottomNavBar(currentIndex: 3),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CABEÇALHO FIXO SEMPRE VISÍVEL
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Text(
                  'Configurações',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),

              // CORPO DA PÁGINA (ALTERNA ENTRE OS 3 PONTINHOS E O CONTEÚDO)
              Expanded(
                child: Watch((context) {
                  if (_isInitialLoading.value) {
                    return Center(
                      child: AnimatedThreeDots(color: colorScheme.onSurface),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    child: Container(
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
                          // ================= SEÇÃO: CONTA =================
                          _buildSectionTitle(context, 'Conta', topPadding: 16),

                          Watch((context) {
                            final currentUser = _userViewModel.state.user.value;

                            final hasMissingData =
                                (currentUser?.email == null ||
                                    currentUser!.email.trim().isEmpty) ||
                                (currentUser?.phone == null ||
                                    currentUser!.phone!.trim().isEmpty) ||
                                (currentUser?.cpf == null ||
                                    currentUser!.cpf!.trim().isEmpty);

                            return AccountOption(
                              icon: Icons.person_outline_rounded,
                              title: 'Perfil',
                              trailing: hasMissingData
                                  ? const Icon(
                                      Icons.error_outline_rounded,
                                      color: Colors.redAccent,
                                      size: 22,
                                    )
                                  : null,
                              onTap: () {
                                context.pushNamed(IndigoRouteNames.editProfile);
                              },
                            );
                          }),
                          const SizedBox(height: 8),

                          Watch((context) {
                            final isDarkMode = themeController.isDarkMode;
                            return AccountOption(
                              icon: isDarkMode
                                  ? Icons.dark_mode_outlined
                                  : Icons.light_mode_outlined,
                              title: 'Modo Escuro',
                              trailing: Switch(
                                value: isDarkMode,
                                activeColor: colorScheme.primary,
                                onChanged: (val) {
                                  themeController.toggleTheme(val);
                                },
                              ),
                            );
                          }),
                          const SizedBox(height: 8),

                          Watch((context) {
                            final currentUser = _userViewModel.state.user.value;
                            final hasMissingAddress =
                                currentUser?.boardingPoint == null;

                            return AccountOption(
                              icon: Icons.map_outlined,
                              title: 'Endereço e Pontos de Parada',
                              trailing: hasMissingAddress
                                  ? const Icon(
                                      Icons.error_outline_rounded,
                                      color: Colors.redAccent,
                                      size: 22,
                                    )
                                  : null,
                              onTap: () {
                                context.pushNamed(
                                  IndigoRouteNames.manageAddress,
                                );
                              },
                            );
                          }),
                          const SizedBox(height: 8),

                          Watch((context) {
                            final isEnabled =
                                _notificationViewModel.state.isEnabled.value;
                            final isToggling =
                                _notificationViewModel.state.isToggling.value;

                            return AccountOption(
                              icon: isEnabled
                                  ? Icons.notifications_active_outlined
                                  : Icons.notifications_off_outlined,
                              title: 'Notificações',
                              trailing: Switch(
                                value: isEnabled,
                                activeColor: colorScheme.primary,
                                onChanged: isToggling
                                    ? null
                                    : _handleToggleNotifications,
                              ),
                            );
                          }),
                          const SizedBox(height: 8),

                          AccountOption(
                            icon: Icons.logout_rounded,
                            title: 'Sair da Conta',
                            iconColor: Colors.redAccent,
                            textColor: Colors.redAccent,
                            trailing: _isLoggingOut
                                ? const AnimatedThreeDots(
                                    color: Colors.redAccent,
                                  )
                                : null,
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) =>
                                    const LogoutConfirmation(),
                              );

                              if (confirm == true) {
                                setState(() {
                                  _isLoggingOut = true;
                                });

                                try {
                                  final router = GoRouter.of(context);
                                  await _notificationViewModel.commands
                                      .onSignOut();
                                  await authController.commands.signOut();

                                  if (!context.mounted) return;
                                  router.goNamed(AuthRouteNames.welcome);
                                } catch (e) {
                                  if (!context.mounted) return;
                                  setState(() {
                                    _isLoggingOut = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Erro ao sair da conta: $e',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),

                          // ================= SEÇÃO: TRABALHE CONOSCO =================
                          _buildSectionTitle(context, 'Trabalhe Conosco'),

                          AccountOption(
                            icon: Icons.business_center_outlined,
                            title: 'Cadastrar Empresa',
                            onTap: () async {
                              await context.pushNamed(
                                IndigoRouteNames.createCompany,
                              );
                              _companyListViewModel.commands
                                  .fetchOwnedCompanies();
                              _companyListViewModel.commands
                                  .fetchMemberCompanies();
                            },
                          ),

                          const SizedBox(height: 8),
                          AccountOption(
                            icon: Icons.badge_outlined,
                            title: 'Empresas Vinculadas',
                            onTap: () {
                              context.pushNamed(
                                IndigoRouteNames.linkedCompanies,
                              );
                            },
                          ),

                          // ================= SEÇÃO: SUPORTE =================
                          _buildSectionTitle(context, 'Suporte'),

                          AccountOption(
                            icon: Icons.help_outline_rounded,
                            title: 'Ajuda e Suporte',
                            onTap: () {
                              context.pushNamed(
                                IndigoRouteNames.helpAndSupport,
                              );
                            },
                          ),
                          const SizedBox(height: 8),

                          AccountOption(
                            icon: Icons.info_outline_rounded,
                            title: 'Sobre o Aplicativo',
                            onTap: () {
                              context.goNamed(IndigoRouteNames.about);
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}