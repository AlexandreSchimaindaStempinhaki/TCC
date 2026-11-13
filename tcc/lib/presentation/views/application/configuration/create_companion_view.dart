import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routes/indigo_routes.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../domain/models/company_entity.dart';
import '../../../controllers/company/company_list_viewmodel.dart';
import '../../../controllers/company/company_viewmodel.dart';
import '../../../widgets/animated_three_dots.dart';
import '../../../widgets/header_background.dart';
import '../../../widgets/text_field.dart';

class CreateCompanyView extends StatefulWidget {
  final CompanyModel? initialCompany;

  const CreateCompanyView({super.key, this.initialCompany});

  @override
  State<CreateCompanyView> createState() => _CreateCompanyViewState();
}

class _CreateCompanyViewState extends State<CreateCompanyView> {
  late final CompanyViewModel _companyViewModel;

  final _cnpjController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  File? _selectedLogoFile;

  final isLoading = signal(false);
  final errorMessage = signal<String?>(null);

  bool get isEditing => widget.initialCompany != null;

  @override
  void initState() {
    super.initState();
    _companyViewModel = injector.get<CompanyViewModel>();
    _companyViewModel.state.clearMessage();

    AppFormatters.cnpj.clear();
    AppFormatters.phone.clear();

    if (isEditing) {
      final company = widget.initialCompany!;
      _cnpjController.text = AppFormatters.cnpj.maskText(company.cnpj);
      _nameController.text = company.name;
      _emailController.text = company.email;
      _phoneController.text = AppFormatters.phone.maskText(company.phone);
    }
  }

  @override
  void dispose() {
    _cnpjController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    isLoading.dispose();
    errorMessage.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedLogoFile = File(pickedFile.path);
      });
    }
  }

  bool _validateFields() {
    final rawCnpj = _cnpjController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final rawPhone = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (rawCnpj.isEmpty || name.isEmpty || email.isEmpty || rawPhone.isEmpty) {
      errorMessage.value = 'Preencha todos os campos obrigatórios.';
      return false;
    }

    if (rawCnpj.length != 14) {
      errorMessage.value = 'O CNPJ deve conter exatamente 14 dígitos.';
      return false;
    }

    if (name.length < 3) {
      errorMessage.value = 'O nome da empresa deve ter pelo menos 3 caracteres.';
      return false;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      errorMessage.value = 'Informe um e-mail comercial válido.';
      return false;
    }

    if (rawPhone.length != 11) {
      errorMessage.value = 'O telefone deve conter DDD + número (11 dígitos).';
      return false;
    }

    errorMessage.value = null;
    return true;
  }

  void _handleBack(BuildContext context) {
    _companyViewModel.state.clearMessage();
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(IndigoRouteNames.account);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentLogoUrl = widget.initialCompany?.logoUrl;

    ImageProvider? avatarImage;
    if (_selectedLogoFile != null) {
      avatarImage = FileImage(_selectedLogoFile!);
    } else if (currentLogoUrl != null && currentLogoUrl.isNotEmpty) {
      avatarImage = NetworkImage(currentLogoUrl);
    }

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
                        onPressed: () => _handleBack(context),
                        tooltip: 'Voltar',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Editar  Empresa' : 'Cadastrar  Empresa',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEditing
                        ? 'Atualize as informações e a logo da sua organização abaixo.'
                        : 'Preencha os dados abaixo para registrar sua organização de transporte no Índigo.',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.secondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SELETOR DE LOGO DA EMPRESA
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickLogo,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 56,
                                backgroundColor:
                                    colorScheme.primary.withOpacity(0.1),
                                backgroundImage: avatarImage,
                                child: avatarImage == null
                                    ? Icon(
                                        Icons.domain_rounded,
                                        size: 48,
                                        color: colorScheme.primary,
                                      )
                                    : null,
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.scaffoldBackgroundColor,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 38,
                          child: OutlinedButton(
                            onPressed: _pickLogo,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              side: BorderSide(
                                color: colorScheme.secondary.withOpacity(0.5),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              avatarImage == null
                                  ? 'Escolher Logo (Opcional)'
                                  : 'Trocar Logo',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.secondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Na edição, o CNPJ fica bloqueado para toque pois é a chave do documento
                  IgnorePointer(
                    ignoring: isEditing,
                    child: Opacity(
                      opacity: isEditing ? 0.6 : 1.0,
                      child: CustomTextField(
                        label: isEditing ? 'CNPJ (Não editável)' : 'CNPJ',
                        hintText: '00.000.000/0000-00',
                        controller: _cnpjController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [AppFormatters.cnpj],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Nome da Empresa',
                    hintText: 'Ex: Transporte Universitário Ltda',
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    inputFormatters: [AppFormatters.nameLimit(60)],
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'E-mail Comercial',
                    hintText: 'contato@empresa.com.br',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Telefone',
                    hintText: '(00) 00000-0000',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [AppFormatters.phone],
                  ),

                  Watch((context) {
                    final localError = errorMessage.value;
                    final vmError = _companyViewModel.state.message.value;
                    final displayError = localError ?? vmError;

                    if (displayError == null) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 12.0, left: 4.0),
                      child: Text(
                        displayError,
                        style: TextStyle(
                          color: colorScheme.error,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 32),

                  Watch(
                    (context) => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading.value
                            ? null
                            : () async {
                                FocusScope.of(context).unfocus();
                                _companyViewModel.state.clearMessage();

                                if (!_validateFields()) return;

                                final rawCnpj = _cnpjController.text.replaceAll(
                                  RegExp(r'[^0-9]'),
                                  '',
                                );
                                final rawPhone = _phoneController.text
                                    .replaceAll(RegExp(r'[^0-9]'), '');

                                try {
                                  isLoading.value = true;
                                  bool success = false;

                                  if (isEditing) {
                                    final updatedCompany = widget
                                        .initialCompany!
                                        .copyWith(
                                          name: _nameController.text.trim(),
                                          email: _emailController.text.trim(),
                                          phone: rawPhone,
                                        );
                                    success = await _companyViewModel.commands
                                        .updateCompany(updatedCompany);
                                  } else {
                                    final newCompany = CompanyModel(
                                      ownerId: '',
                                      cnpj: rawCnpj,
                                      name: _nameController.text.trim(),
                                      email: _emailController.text.trim(),
                                      phone: rawPhone,
                                    );
                                    success = await _companyViewModel.commands
                                        .createCompany(newCompany);
                                  }

                                  if (!context.mounted) return;

                                  if (success) {
                                    if (_selectedLogoFile != null) {
                                      await _companyViewModel.commands
                                          .updateCompanyLogo(
                                            rawCnpj,
                                            _selectedLogoFile!,
                                          );
                                    }

                                    await injector
                                        .get<CompanyListViewModel>()
                                        .commands
                                        .fetchOwnedCompanies();

                                    if (!context.mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isEditing
                                              ? 'Empresa atualizada com sucesso!'
                                              : 'Empresa cadastrada com sucesso!',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );

                                    if (isEditing) {
                                      _handleBack(context);
                                    } else {
                                      context.goNamed(IndigoRouteNames.account);
                                    }
                                  }
                                } catch (e) {
                                  errorMessage.value = isEditing
                                      ? 'Erro ao atualizar empresa. Tente novamente.'
                                      : 'Erro ao cadastrar empresa. Tente novamente.';
                                } finally {
                                  if (context.mounted) {
                                    isLoading.value = false;
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading.value
                            ? AnimatedThreeDots(color: colorScheme.onSurface)
                            : Text(
                                isEditing
                                    ? 'Salvar Alterações'
                                    : 'Cadastrar Empresa',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}