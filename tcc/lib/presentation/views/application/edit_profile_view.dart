import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/routes/auth_routes.dart';
import '../../../core/routes/indigo_routes.dart';
import '../../../core/utils/app_formatters.dart';
import '../../controllers/user_viewmodel.dart';
import '../../widgets/account_option.dart';
import '../../widgets/profile_header_card.dart';
import '../../widgets/animated_three_dots.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late final UserViewModel _userViewModel;
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    _userViewModel = injector.get<UserViewModel>();
    _userViewModel.commands.fetchUser();
  }

  Widget? _buildMissingIndicator(dynamic value) {
    final bool isEmpty = value == null || value.toString().trim().isEmpty;
    
    if (isEmpty) {
      return const Icon(
        Icons.error_outline_rounded,
        color: Colors.redAccent,
        size: 22,
      );
    }
    
    return null; 
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

    return Watch((context) {
      final currentUser = _userViewModel.state.user.value;
      final nameText = currentUser?.name ?? '';
      final emailText = currentUser?.email ?? '';
      final photoUrl = currentUser?.photoUrl;

      return AbsorbPointer(
        absorbing: _isDeletingAccount,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Editar Conta',
              style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileHeaderCard(name: nameText, email: emailText, photoUrl: photoUrl),
                const SizedBox(height: 24),

                Container(
                  clipBehavior: Clip.antiAlias,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSectionTitle(context, 'Dados Pessoais', topPadding: 16),
                      
                      AccountOption(
                        icon: Icons.camera_alt_outlined,
                        title: 'Foto de Perfil',
                        trailing: _buildMissingIndicator(currentUser?.photoUrl),
                        onTap: () => context.pushNamed(IndigoRouteNames.editProfilePhoto),
                      ),
                      const SizedBox(height: 8),
                      
                      AccountOption(
                        icon: Icons.person_outline_rounded,
                        title: 'Nome Completo',
                        trailing: _buildMissingIndicator(currentUser?.name),
                        onTap: () {
                          context.pushNamed(
                            IndigoRouteNames.editProfileField,
                            extra: {
                              'title': 'Nome',
                              'currentValue': currentUser?.name ?? '',
                              'keyboardType': TextInputType.name,
                              'inputFormatters': [AppFormatters.nameLimit(50)],
                              'onSave': (String newValue) async {
                                final updated = currentUser!.copyWith(name: newValue);
                                await _userViewModel.commands.saveUserData(updated);
                              },
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 8),

                      AccountOption(
                        icon: Icons.phone_outlined,
                        title: 'Telefone',
                        trailing: _buildMissingIndicator(currentUser?.phone),
                        onTap: () {
                          context.pushNamed(
                            IndigoRouteNames.editProfileField,
                            extra: {
                              'title': 'Telefone',
                              'currentValue': currentUser?.phone ?? '',
                              'keyboardType': TextInputType.phone,
                              'inputFormatters': [AppFormatters.phone],
                              'onSave': (String newValue) async {
                                final updated = currentUser!.copyWith(phone: newValue);
                                await _userViewModel.commands.saveUserData(updated);
                              },
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 8),

                      AccountOption(
                        icon: Icons.badge_outlined,
                        title: 'CPF',
                        trailing: _buildMissingIndicator(currentUser?.cpf),
                        onTap: () {
                          context.pushNamed(
                            IndigoRouteNames.editProfileField,
                            extra: {
                              'title': 'CPF',
                              'currentValue': currentUser?.cpf ?? '',
                              'keyboardType': TextInputType.number,
                              'inputFormatters': [AppFormatters.cpf],
                              'onSave': (String newValue) async {
                                final updated = currentUser!.copyWith(cpf: newValue);
                                await _userViewModel.commands.saveUserData(updated);
                              },
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 8),

                      AccountOption(
                        icon: Icons.cake_outlined,
                        title: 'Data de Nascimento',
                        trailing: _buildMissingIndicator(currentUser?.birthDate?.toString()),
                        onTap: () => context.pushNamed(IndigoRouteNames.editProfileDate),
                      ),
                      const SizedBox(height: 8),

                      AccountOption(
                        icon: Icons.directions_car_rounded,
                        title: 'CNH',
                        // CNH propositalmente sem o indicador de obrigatoriedade
                        onTap: () {
                          context.pushNamed(
                            IndigoRouteNames.editProfileField,
                            extra: {
                              'title': 'CNH',
                              'currentValue': currentUser?.driverLicense ?? '',
                              'keyboardType': TextInputType.number,
                              'inputFormatters': [AppFormatters.cnhLimit()],
                              'onSave': (String newValue) async {
                                final updated = currentUser!.copyWith(driverLicense: newValue);
                                await _userViewModel.commands.saveUserData(updated);
                              },
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 8),

                      _buildSectionTitle(context, 'Segurança'),
                      
                      AccountOption(
                        icon: Icons.lock_outline_rounded,
                        title: 'Mudar Senha',
                        onTap: () {
                          // TODO: Substitua pelo nome da sua rota de recuperar/mudar senha
                          // context.pushNamed(AuthRouteNames.forgotPassword);
                        },
                      ),
                      const SizedBox(height: 8),

                      AccountOption(
                        icon: Icons.delete_outline_rounded,
                        title: 'Excluir Conta',
                        iconColor: Colors.redAccent,
                        textColor: Colors.redAccent,
                        trailing: _isDeletingAccount ? const AnimatedThreeDots(color: Colors.redAccent) : null,
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                                  SizedBox(width: 8),
                                  Text('Excluir Conta?'),
                                ],
                              ),
                              content: const Text(
                                'Esta ação é irreversível. Todos os seus dados serão apagados permanentemente. Deseja continuar?',
                                style: TextStyle(fontSize: 15),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => context.pop(false),
                                  child: Text('Cancelar', style: TextStyle(color: colorScheme.onSurface)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                  ),
                                  onPressed: () => context.pop(true),
                                  child: const Text('Sim, Excluir'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            setState(() => _isDeletingAccount = true);

                            final success = await _userViewModel.commands.deleteUserAccount();

                            if (!context.mounted) return;

                            if (success) {
                              GoRouter.of(context).goNamed(AuthRouteNames.welcome);
                            } else {
                              setState(() => _isDeletingAccount = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Por segurança, saia do app, faça login novamente e tente excluir.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
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