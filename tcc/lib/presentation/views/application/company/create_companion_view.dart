import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../domain/models/company_entity.dart';
import '../../../widgets/animated_three_dots.dart';
import '../../../widgets/header_background.dart';
import '../../../widgets/text_field.dart';
import '../../mixins/create_company_logic.dart';

class CreateCompanyView extends StatefulWidget {
  final CompanyModel? initialCompany;

  const CreateCompanyView({super.key, this.initialCompany});

  @override
  State<CreateCompanyView> createState() => _CreateCompanyViewState();
}

class _CreateCompanyViewState extends State<CreateCompanyView>
    with CreateCompanyMixin {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inverseColor = colorScheme.onSurface;
    final currentLogoUrl = widget.initialCompany?.logoUrl;

    ImageProvider? avatarImage;
    if (selectedLogoFile != null) {
      avatarImage = FileImage(selectedLogoFile!);
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
                        onPressed: () => handleBack(context),
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

                  // SELETOR DE LOGO MAIOR E COM CORES INVERSAS AO FUNDO
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: pickLogo,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 76,
                                backgroundColor: inverseColor.withOpacity(0.12),
                                backgroundImage: avatarImage,
                                child: avatarImage == null
                                    ? Icon(
                                        Icons.domain_rounded,
                                        size: 64,
                                        color: inverseColor,
                                      )
                                    : null,
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: inverseColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.scaffoldBackgroundColor,
                                    width: 2.5,
                                  ),
                                ),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  size: 18,
                                  color: theme.scaffoldBackgroundColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 38,
                          child: OutlinedButton(
                            onPressed: pickLogo,
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

                  IgnorePointer(
                    ignoring: isEditing,
                    child: Opacity(
                      opacity: isEditing ? 0.6 : 1.0,
                      child: CustomTextField(
                        label: isEditing ? 'CNPJ (Não editável)' : 'CNPJ',
                        hintText: '00.000.000/0000-00',
                        controller: cnpjController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [AppFormatters.cnpj],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Nome da Empresa',
                    hintText: 'Ex: Transporte Universitário Ltda',
                    controller: nameController,
                    keyboardType: TextInputType.name,
                    inputFormatters: [AppFormatters.nameLimit(60)],
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'E-mail Comercial',
                    hintText: 'contato@empresa.com.br',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Telefone',
                    hintText: '(00) 00000-0000',
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [AppFormatters.phone],
                  ),

                  Watch((context) {
                    final localError = errorMessage.value;
                    final vmError = companyViewModel.state.message.value;
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
                            : () => submitForm(context),
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