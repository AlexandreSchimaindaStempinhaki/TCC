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
import '../../controllers/company/company_list_viewmodel.dart';
import '../../controllers/company/company_viewmodel.dart';
import '../../views/application/configuration/create_companion_view.dart';

mixin CreateCompanyMixin on State<CreateCompanyView> {
  late final CompanyViewModel companyViewModel;

  final cnpjController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  File? selectedLogoFile;

  final isLoading = signal(false);
  final errorMessage = signal<String?>(null);

  bool get isEditing => widget.initialCompany != null;

  @override
  void initState() {
    super.initState();
    companyViewModel = injector.get<CompanyViewModel>();
    companyViewModel.state.clearMessage();

    AppFormatters.cnpj.clear();
    AppFormatters.phone.clear();

    if (isEditing) {
      final company = widget.initialCompany!;
      cnpjController.text = AppFormatters.cnpj.maskText(company.cnpj);
      nameController.text = company.name;
      emailController.text = company.email;
      phoneController.text = AppFormatters.phone.maskText(company.phone);
    }
  }

  @override
  void dispose() {
    cnpjController.dispose();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    isLoading.dispose();
    errorMessage.dispose();
    super.dispose();
  }

  Future<void> pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedLogoFile = File(pickedFile.path);
      });
    }
  }

  bool validateFields() {
    final rawCnpj = cnpjController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final rawPhone = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');

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

  void handleBack(BuildContext context) {
    companyViewModel.state.clearMessage();
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.goNamed(IndigoRouteNames.account);
    }
  }

  void showTopSnackBar(BuildContext context, String message) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomMargin = context.screenHeight - topPadding - 150;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          elevation: 6,
          margin: EdgeInsets.only(
            bottom: bottomMargin > 0 ? bottomMargin : 20,
            left: 20,
            right: 20,
          ),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> submitForm(BuildContext context) async {
    FocusScope.of(context).unfocus();
    companyViewModel.state.clearMessage();
    errorMessage.value = null;

    if (!validateFields()) return;

    final rawCnpj = cnpjController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final rawPhone = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');

    try {
      isLoading.value = true;
      bool success = false;

      if (isEditing) {
        final updatedCompany = widget.initialCompany!.copyWith(
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          phone: rawPhone,
        );
        success = await companyViewModel.commands.updateCompany(
          updatedCompany,
        );
      } else {
        final newCompany = CompanyModel(
          ownerId: '',
          cnpj: rawCnpj,
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          phone: rawPhone,
        );
        success = await companyViewModel.commands.createCompany(newCompany);
      }

      if (!success) {
        errorMessage.value =
            companyViewModel.state.message.value ??
            (isEditing
                ? 'Não foi possível atualizar a empresa.'
                : 'Não foi possível cadastrar a empresa.');
        return;
      }

      if (selectedLogoFile != null) {
        try {
          await companyViewModel.commands.updateCompanyLogo(
            rawCnpj,
            selectedLogoFile!,
          );
        } catch (_) {}
      }

      try {
        await injector
            .get<CompanyListViewModel>()
            .commands
            .fetchOwnedCompanies();
      } catch (_) {}

      if (!context.mounted) return;

      showTopSnackBar(
        context,
        isEditing
            ? 'Empresa atualizada com sucesso!'
            : 'Empresa cadastrada com sucesso!',
      );

      handleBack(context);
    } catch (e) {
      errorMessage.value = 'Erro inesperado: $e';
    } finally {
      if (mounted) {
        isLoading.value = false;
      }
    }
  }
}