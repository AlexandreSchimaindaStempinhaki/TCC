import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../core/di/dependency_injection.dart';
import '../../controllers/user_viewmodel.dart';
import '../../widgets/circular_text_field.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late final UserViewModel _userViewModel;

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cpfController;
  late final TextEditingController _cnhController;
  
  DateTime? _selectedDate;
  File? _selectedImageFile;
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _userViewModel = injector.get<UserViewModel>();

    // Inicializa os controllers vazios
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _cpfController = TextEditingController();
    _cnhController = TextEditingController();

    // Dispara o comando original do ViewModel para buscar os dados do usuário no Firestore
    _userViewModel.commands.fetchUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cpfController.dispose();
    _cnhController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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

  String _getInitials(String name) {
    if (name.isEmpty) return 'US';
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return 'US';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Watch((context) {
      // Pega o usuário diretamente do estado reativo do ViewModel
      final currentUser = _userViewModel.state.user.value;

      // Assim que os dados chegam do Firestore, preenche os controllers uma única vez
      if (currentUser != null && !_isDataLoaded) {
        _nameController.text = currentUser.name;
        _emailController.text = currentUser.email;
        _phoneController.text = currentUser.phone ?? '';
        _cpfController.text = currentUser.cpf ?? '';
        _cnhController.text = currentUser.driverLicense ?? '';
        _selectedDate = currentUser.birthDate;
        _isDataLoaded = true;
      }

      final nameText = currentUser?.name ?? _nameController.text;
      final photoUrl = currentUser?.photoUrl;

      // Validações de nulo para os campos opcionais
      final bool isPhoneNull = currentUser?.phone == null || currentUser!.phone!.isEmpty;
      final bool isCpfNull = currentUser?.cpf == null || currentUser!.cpf!.isEmpty;
      final bool isDateNull = currentUser?.birthDate == null;
      final bool isCnhNull = currentUser?.driverLicense == null || currentUser!.driverLicense!.isEmpty;

      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Editar Dados Pessoais',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FOTO DE PERFIL
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: colorScheme.primary,
                      backgroundImage: _selectedImageFile != null
                          ? FileImage(_selectedImageFile!)
                          : (photoUrl != null && photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl) as ImageProvider
                              : null),
                      child: (_selectedImageFile == null && (photoUrl == null || photoUrl.isEmpty))
                          ? Text(
                              _getInitials(nameText),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: theme.cardColor,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.camera_alt_rounded,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Informações Pessoais',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 12),

              CircularTextField(
                label: 'Nome Completo',
                controller: _nameController,
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),

              CircularTextField(
                label: 'E-mail',
                controller: _emailController,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // TELEFONE
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircularTextField(
                    label: 'Telefone',
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      isPhoneNull ? 'Status: Não informado (Nulo)' : 'Status: Preenchido',
                      style: TextStyle(
                        fontSize: 12,
                        color: isPhoneNull ? Colors.orange[700] : Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // CPF
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircularTextField(
                    label: 'CPF',
                    controller: _cpfController,
                    icon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      isCpfNull ? 'Status: Não informado (Nulo)' : 'Status: Preenchido',
                      style: TextStyle(
                        fontSize: 12,
                        color: isCpfNull ? Colors.orange[700] : Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // DATA DE NASCIMENTO
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => _selectDate(context),
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Data de Nascimento',
                        labelStyle: TextStyle(color: colorScheme.secondary),
                        prefixIcon: Icon(Icons.cake_outlined, color: colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                      ),
                      child: Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                            : 'Selecione a data',
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedDate != null ? colorScheme.onSurface : colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      isDateNull ? 'Status: Não informada (Nula)' : 'Status: Preenchida',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDateNull ? Colors.orange[700] : Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // CNH
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircularTextField(
                    label: 'Carteira de Motorista - CNH',
                    hintText: 'Ex: 12345678900',
                    controller: _cnhController,
                    icon: Icons.directions_car_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      isCnhNull ? 'Status: Não informada (Nula)' : 'Status: Preenchida',
                      style: TextStyle(
                        fontSize: 12,
                        color: isCnhNull ? Colors.orange[700] : Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // BOTÃO SALVAR
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (currentUser == null) return;

                    final updatedUser = currentUser.copyWith(
                      name: _nameController.text.trim(),
                      email: _emailController.text.trim(),
                      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
                      cpf: _cpfController.text.trim().isEmpty ? null : _cpfController.text.trim(),
                      birthDate: _selectedDate,
                      driverLicense: _cnhController.text.trim().isEmpty ? null : _cnhController.text.trim(),
                    );

                    if (_selectedImageFile != null) {
                      await _userViewModel.commands.updateProfilePicture(_selectedImageFile!);
                    }

                    await _userViewModel.commands.saveUserData(updatedUser);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Alterações salvas com sucesso!'),
                          backgroundColor: colorScheme.primary,
                        ),
                      );
                      context.pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Salvar Alterações',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      );
    });
  }
}