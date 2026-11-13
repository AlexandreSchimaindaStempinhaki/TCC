import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../controllers/user/user_viewmodel.dart';
import '../../../widgets/header_background.dart';
import '../../../widgets/animated_three_dots.dart';

class EditProfilePhotoView extends StatefulWidget {
  const EditProfilePhotoView({super.key});

  @override
  State<EditProfilePhotoView> createState() => _EditProfilePhotoViewState();
}

class _EditProfilePhotoViewState extends State<EditProfilePhotoView> {
  late final UserViewModel _userViewModel;
  File? _selectedImageFile;

  final isLoading = signal(false);

  @override
  void initState() {
    super.initState();
    _userViewModel = injector.get<UserViewModel>();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final router = GoRouter.of(context);
    final currentUser = _userViewModel.state.user.value;

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
                        onPressed: () => context.pop(),
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
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Centralizado para a foto
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Foto  de  Perfil',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  CircleAvatar(
                    radius: 150,
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    backgroundImage: _selectedImageFile != null
                        ? FileImage(_selectedImageFile!)
                        : (currentUser?.photoUrl != null &&
                                  currentUser!.photoUrl!.isNotEmpty
                              ? NetworkImage(currentUser.photoUrl!)
                                    as ImageProvider
                              : null),
                    child:
                        (_selectedImageFile == null &&
                            (currentUser?.photoUrl == null ||
                                currentUser!.photoUrl!.isEmpty))
                        ? Icon(
                            Icons.person,
                            size: 80,
                            color: colorScheme.primary,
                          )
                        : null,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      label: Text(
                        'Escolher da Galeria',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.secondary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        side: BorderSide(
                          color: colorScheme.secondary.withOpacity(
                            0.5,
                          ), 
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  Watch(
                    (context) => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading.value || _selectedImageFile == null
                            ? null
                            : () async {
                                try {
                                  isLoading.value = true;
                                  await _userViewModel.commands
                                      .updateProfilePicture(
                                        _selectedImageFile!,
                                      );

                                  if (!context.mounted) return;
                                  router.pop();
                                } finally {
                                  if (context.mounted) isLoading.value = false;
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading.value
                            ? AnimatedThreeDots(color: colorScheme.onSurface)
                            : const Text(
                                'Salvar Nova Foto',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
