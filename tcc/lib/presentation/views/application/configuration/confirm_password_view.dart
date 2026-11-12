import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../widgets/header_background.dart';
import '../../../widgets/text_field.dart';
import '../../../widgets/animated_three_dots.dart';

class ConfirmPasswordView extends StatefulWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final bool isDestructive;
  
  // Executa a ação e retorna a mensagem de erro em caso de falha, ou null em caso de sucesso.
  final Future<String?> Function(String password) onConfirm;

  const ConfirmPasswordView({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onConfirm,
    this.buttonText = 'Confirmar',
    this.isDestructive = false,
  });

  @override
  State<ConfirmPasswordView> createState() => _ConfirmPasswordViewState();
}

class _ConfirmPasswordViewState extends State<ConfirmPasswordView> {
  late final TextEditingController _controller;
  
  final isLoading = signal(false);
  final errorMessage = signal<String?>(null);
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    isLoading.dispose();
    errorMessage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                    widget.title,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.secondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  CustomTextField(
                    label: 'Senha Atual',
                    hintText: '••••••••',
                    controller: _controller,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: colorScheme.secondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
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
                                final password = _controller.text.trim();

                                if (password.isEmpty) {
                                  errorMessage.value = 'Por favor, digite sua senha.';
                                  return;
                                }

                                try {
                                  isLoading.value = true;
                                  errorMessage.value = null;

                                  final error = await widget.onConfirm(password);
                                  
                                  if (!context.mounted) return;

                                  if (error != null) {
                                    errorMessage.value = error;
                                  }
                                } catch (e) {
                                  errorMessage.value = 'Erro ao processar. Tente novamente.';
                                } finally {
                                  if (context.mounted) {
                                    isLoading.value = false;
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.isDestructive 
                              ? Colors.redAccent 
                              : colorScheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading.value
                            ? AnimatedThreeDots(
                                color: widget.isDestructive 
                                    ? Colors.white 
                                    : colorScheme.onPrimary,
                              )
                            : Text(
                                widget.buttonText,
                                style: const TextStyle(
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