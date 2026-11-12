import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/routes/indigo_routes.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../domain/models/user_entity.dart';
import '../../../controllers/user_viewmodel.dart';
import '../../../widgets/clean_header_background.dart';
import '../../../widgets/profile_info_tile.dart';

class ProfileView extends StatefulWidget {
  final UserViewModel userViewModel;
  final UserModel? user;

  const ProfileView({super.key, required this.userViewModel, this.user});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    widget.userViewModel.commands.fetchUser();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Watch((context) {
      final loggedUser = widget.userViewModel.state.user.value;
      final targetUser = widget.user ?? loggedUser;
      final bool isOwner = widget.userViewModel.commands.isOwner(targetUser);

      final nameText = targetUser?.name ?? 'Usuário';
      final initials = nameText.isNotEmpty ? nameText[0].toUpperCase() : 'U';

      const double avatarRadius = 120;
      const double avatarTop = 80;
      const double headerHeight = 265;

      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: CleanHeaderBackground(height: headerHeight),
                  ),
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, top: 8),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () => context.pop(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: avatarTop),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.scaffoldBackgroundColor,
                                  width: 5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: avatarRadius,
                                backgroundColor: colorScheme.primary,
                                backgroundImage:
                                    targetUser?.photoUrl != null &&
                                        targetUser!.photoUrl!.isNotEmpty
                                    ? NetworkImage(targetUser.photoUrl!)
                                    : null,
                                child:
                                    (targetUser?.photoUrl == null ||
                                        targetUser!.photoUrl!.isEmpty)
                                    ? Text(
                                        initials,
                                        style: TextStyle(
                                          color: colorScheme.onPrimary,
                                          fontSize: 56,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            if (isOwner)
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => context.pushNamed(
                                    IndigoRouteNames.editProfilePhoto,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.scaffoldBackgroundColor,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.14),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: GestureDetector(
                            onTap: isOwner
                                ? () {
                                    context.pushNamed(
                                      IndigoRouteNames.editProfileField,
                                      extra: {
                                        'title': 'Nome',
                                        'currentValue': targetUser?.name ?? '',
                                        'keyboardType': TextInputType.name,
                                        'inputFormatters': [
                                          AppFormatters.nameLimit(50),
                                        ],
                                        'onSave': (String newValue) async {
                                          final updated = targetUser!.copyWith(
                                            name: newValue,
                                          );
                                          await widget.userViewModel.commands
                                              .saveUserData(updated);
                                        },
                                      },
                                    );
                                  }
                                : null,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    nameText,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (isOwner) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(22),
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
                    ProfileInfoTile(
                      icon: Icons.email_outlined,
                      title: 'E-mail',
                      value: targetUser?.email ?? '',
                      canEdit: false,
                      reserveTrailingSpace: isOwner,
                    ),
                    ProfileInfoTile(
                      icon: Icons.phone_outlined,
                      title: 'Telefone',
                      value: targetUser?.phone ?? '',
                      canEdit: isOwner,
                      isRequired: true,
                      onTap: () {
                        context.pushNamed(
                          IndigoRouteNames.editProfileField,
                          extra: {
                            'title': 'Telefone',
                            'currentValue': targetUser?.phone ?? '',
                            'keyboardType': TextInputType.phone,
                            'inputFormatters': [AppFormatters.phone],
                            'onSave': (String newValue) async {
                              final updated = targetUser!.copyWith(
                                phone: newValue,
                              );
                              await widget.userViewModel.commands.saveUserData(
                                updated,
                              );
                            },
                          },
                        );
                      },
                    ),
                    ProfileInfoTile(
                      icon: Icons.badge_outlined,
                      title: 'CPF',
                      value: targetUser?.cpf ?? '',
                      canEdit: isOwner,
                      isRequired: true,
                      onTap: () {
                        context.pushNamed(
                          IndigoRouteNames.editProfileField,
                          extra: {
                            'title': 'CPF',
                            'currentValue': targetUser?.cpf ?? '',
                            'keyboardType': TextInputType.number,
                            'inputFormatters': [AppFormatters.cpf],
                            'onSave': (String newValue) async {
                              final updated = targetUser!.copyWith(
                                cpf: newValue,
                              );
                              await widget.userViewModel.commands.saveUserData(
                                updated,
                              );
                            },
                          },
                        );
                      },
                    ),
                    ProfileInfoTile(
                      icon: Icons.calendar_today_outlined,
                      title: 'Nascimento',
                      value: AppFormatters.formatDate(targetUser?.birthDate),
                      canEdit: isOwner,
                      isRequired: true,
                      onTap: () =>
                          context.pushNamed(IndigoRouteNames.editProfileDate),
                    ),
                    ProfileInfoTile(
                      icon: Icons.directions_car_rounded,
                      title: 'CNH',
                      value: targetUser?.driverLicense ?? '',
                      canEdit: isOwner,
                      isRequired: false,
                      onTap: () {
                        context.pushNamed(
                          IndigoRouteNames.editProfileField,
                          extra: {
                            'title': 'CNH',
                            'currentValue': targetUser?.driverLicense ?? '',
                            'keyboardType': TextInputType.number,
                            'inputFormatters': [AppFormatters.cnhLimit()],
                            'onSave': (String newValue) async {
                              final updated = targetUser!.copyWith(
                                driverLicense: newValue,
                              );
                              await widget.userViewModel.commands.saveUserData(
                                updated,
                              );
                            },
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
