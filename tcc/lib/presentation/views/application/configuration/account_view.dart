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
import '../../../controllers/user/user_viewmodel.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  late final AuthViewModel authController;
  late final UserViewModel _userViewModel;

  bool _notificationsEnabled = true;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    authController = injector.get<AuthViewModel>();
    _userViewModel = injector.get<UserViewModel>();
    _userViewModel.commands.fetchUser();
  }

  Widget _buildSectionTitle(BuildContext context, String title, {double topPadding = 24}) {
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configurações',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),

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
                      // ================= SEÇÃO: CONTA =================
                      _buildSectionTitle(context, 'Conta', topPadding: 16),
                      
                      Watch((context) {
                        final currentUser = _userViewModel.state.user.value;
                        
                        final hasMissingData = 
                            (currentUser?.email == null || currentUser!.email.trim().isEmpty) ||
                            (currentUser?.phone == null || currentUser!.phone!.trim().isEmpty) ||
                            (currentUser?.cpf == null || currentUser!.cpf!.trim().isEmpty);

                        return AccountOption(
                          icon: Icons.person_outline_rounded,
                          title: 'Perfil',
                          trailing: hasMissingData 
                              ? const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 22) 
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
                        final hasMissingAddress = currentUser?.boardingPoint == null;

                        return AccountOption(
                          icon: Icons.map_outlined,
                          title: 'Endereço e Pontos de Parada',
                          trailing: hasMissingAddress
                              ? const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 22)
                              : null,
                          onTap: () {
                            context.pushNamed(IndigoRouteNames.manageAddress);
                          },
                        );
                      }),
                      const SizedBox(height: 8),
                      
                      AccountOption(
                        icon: Icons.notifications_none_outlined,
                        title: 'Notificações',
                        trailing: Switch(
                          value: _notificationsEnabled,
                          activeColor: colorScheme.primary,
                          onChanged: (val) {
                            setState(() {
                              _notificationsEnabled = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ================= BOTÃO DE SAIR =================
                      AccountOption(
                        icon: Icons.logout_rounded,
                        title: 'Sair da Conta',
                        iconColor: Colors.redAccent,
                        textColor: Colors.redAccent,
                        trailing: _isLoggingOut 
                            ? const AnimatedThreeDots(color: Colors.redAccent) 
                            : null,
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => const LogoutConfirmation(),
                          );

                          if (confirm == true) {
                            setState(() {
                              _isLoggingOut = true;
                            });

                            try {
                              final router = GoRouter.of(context);
                              await authController.commands.signOut();
                              
                              if (!context.mounted) return;
                              router.goNamed(AuthRouteNames.welcome); 
                            } catch (e) {
                              if (!context.mounted) return;
                              setState(() {
                                _isLoggingOut = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro ao sair da conta: $e')),
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
                        onTap: () {},
                      ),

                      // ================= SEÇÃO: SUPORTE =================
                      _buildSectionTitle(context, 'Suporte'),

                      AccountOption(
                        icon: Icons.help_outline_rounded,
                        title: 'Ajuda e Suporte',
                        onTap: () {},
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
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}