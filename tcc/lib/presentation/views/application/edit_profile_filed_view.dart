import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../widgets/header_background.dart';
import '../../widgets/text_field.dart';
import '../../widgets/animated_three_dots.dart';

class EditProfileFieldView extends StatefulWidget {
  final String title;
  final String currentValue;
  final TextInputType keyboardType;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;
  final Future<void> Function(String newValue) onSave;

  const EditProfileFieldView({
    super.key,
    required this.title,
    required this.currentValue,
    required this.keyboardType,
    required this.onSave,
    this.hintText,
    this.inputFormatters,
  });

  @override
  State<EditProfileFieldView> createState() => _EditProfileFieldViewState();
}

class _EditProfileFieldViewState extends State<EditProfileFieldView> {
  late final TextEditingController _controller;
  
  final isLoading = signal(false);
  final errorMessage = signal<String?>(null);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _validateField(String value) {
    final cleanValue = value.trim();
    final lowerTitle = widget.title.toLowerCase();

    if (cleanValue.isEmpty) {
      errorMessage.value = 'O campo não pode estar vazio.';
      return false;
    }

    if (lowerTitle.contains('nome')) {
      if (cleanValue.length < 3) {
        errorMessage.value = 'O nome deve ter pelo menos 3 caracteres.';
        return false;
      }
    } else if (lowerTitle.contains('telefone') || lowerTitle.contains('celular') || lowerTitle.contains('whatsapp')) {
      final digits = cleanValue.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length != 11) {
        errorMessage.value = 'O telefone deve conter DDD + número (11 dígitos).';
        return false;
      }
    } else if (lowerTitle.contains('cpf')) {
      final digits = cleanValue.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length != 11) {
        errorMessage.value = 'O CPF deve conter exatamente 11 dígitos.';
        return false;
      }
    } else if (lowerTitle.contains('cnh')) {
      final digits = cleanValue.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length < 9) {
        errorMessage.value = 'Número de CNH inválido ou incompleto.';
        return false;
      }
    }

    errorMessage.value = null;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final router = GoRouter.of(context);

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
                    'Editar ${widget.title}',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  CustomTextField(
                    label: widget.title,
                    hintText: widget.hintText ?? 'Insira o novo dado',
                    controller: _controller,
                    keyboardType: widget.keyboardType,
                    inputFormatters: widget.inputFormatters,
                  ),

                  Watch((context) {
                    if (errorMessage.value == null) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                      child: Text(
                        errorMessage.value!,
                        style: TextStyle(
                          color: colorScheme.error,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 28),

                  Watch(
                    (context) => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading.value
                            ? null
                            : () async {
                                final newValue = _controller.text;

                                if (!_validateField(newValue)) {
                                  return;
                                }

                                try {
                                  isLoading.value = true;
                                  await widget.onSave(newValue.trim());
                                  
                                  if (!context.mounted) return;
                                  router.pop();
                                } catch (e) {
                                  errorMessage.value = 'Erro ao salvar. Tente novamente: $e';
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
                            : const Text(
                                'Salvar',
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
