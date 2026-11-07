import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/theme/theme_controller.dart';
import 'package:tcc/presentation/widgets/nav_bar.dart';
import 'package:tcc/presentation/widgets/account_option.dart'; 
import 'package:tcc/presentation/widgets/logout_confirmation.dart'; 
import 'package:tcc/presentation/widgets/animated_three_dots.dart'; 
import '../../../core/routes/auth_routes.dart';
import '../../../core/routes/indigo_routes.dart';
import '../../controllers/authentication/auth_session_viewmodel.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  late final AuthViewModel authController;

  bool _notificationsEnabled = true;
  bool _isLoggingOut = false; // Controle de estado do loading

  @override
  void initState() {
    super.initState();
    authController = injector.get<AuthViewModel>();
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

    // O AbsorbPointer bloqueia TODOS os toques na tela enquanto _isLoggingOut for true
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
                      
                      AccountOption(
                        icon: Icons.person_outline_rounded,
                        title: 'Perfil',
                        onTap: () {
                          context.pushNamed(
                            IndigoRouteNames.editProfile,
                            extra: {
                              'name': 'Gabriel Silva',
                              'role': 'Estudante • UFPR Litoral',
                            },
                          );
                        },
                      ),
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
                      
                      AccountOption(
                        icon: Icons.home_outlined,
                        title: 'Endereço Residencial',
                        onTap: () {
                          context.pushNamed(IndigoRouteNames.manageAddress);
                        },
                      ),
                      const SizedBox(height: 8),
                      
                      AccountOption(
                        icon: Icons.place_outlined,
                        title: 'Pontos de Parada Salvos',
                        onTap: () {},
                      ),
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

                      // ================= BOTÃO DE SAIR (COM DIÁLOGO E LOADING) =================
                      AccountOption(
                        icon: Icons.logout_rounded,
                        title: 'Sair da Conta',
                        iconColor: Colors.redAccent,
                        textColor: Colors.redAccent,
                        // Se estiver saindo, mostra as reticências
                        trailing: _isLoggingOut 
                            ? const AnimatedThreeDots(color: Colors.redAccent) 
                            : null,
                        onTap: () async {
                          // 1. Abre o diálogo de confirmação
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => const LogoutConfirmation(),
                          );

                          // 2. Se confirmar, dispara o estado de loading e a lógica de saída
                          if (confirm == true) {
                            setState(() {
                              _isLoggingOut = true; // Aciona o AbsorbPointer e a animação
                            });

                            try {
                              final router = GoRouter.of(context);
                              await authController.commands.signOut();
                              
                              if (!context.mounted) return;
                              router.goNamed(AuthRouteNames.welcome); 
                            } catch (e) {
                              if (!context.mounted) return;
                              // Em caso de erro, remove o estado de carregamento e o bloqueio
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
                        onTap: () {},
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