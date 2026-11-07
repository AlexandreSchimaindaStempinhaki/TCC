import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/routes/indigo_routes.dart';
import '../../controllers/authentication/auth_session_viewmodel.dart';
import '../../widgets/animated_three_dots.dart';
import '../../widgets/header_background.dart';

class EmailVerificationPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const EmailVerificationPage({
    super.key,
    required this.userData,
  });

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  late final AuthViewModel authController;

  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final isLoadingButton = signal(false);
  final isResending = signal(false);
  final verificationError = signal<String?>(null);

  @override
  void initState() {
    super.initState();
    authController = injector.get<AuthViewModel>();
    authController.session.clearMessage();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _getOtpCode() {
    return _controllers.map((c) => c.text).join();
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
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          authController.session.clearMessage();
                          context.pop();
                        },
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
                    'Verificação',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Digite o código de 6 dígitos enviado para o seu e-mail.',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Aviso amigável sobre a pasta de Spam
                  Text(
                    'Não encontrou? Verifique também a sua caixa de Spam ou lixo eletrônico.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.secondary.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Campos OTP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 48,
                        height: 56,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            } else if (value.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),

                  Watch(
                    (context) => verificationError.value != null || authController.session.message.value != null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 16.0, left: 4.0),
                            child: Text(
                              verificationError.value ?? authController.session.message.value ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 32),

                  // Botão Confirmar
                  Watch(
                    (context) => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoadingButton.value
                            ? null
                            : () async {
                                verificationError.value = null;
                                authController.session.clearMessage();

                                final code = _getOtpCode();
                                if (code.length < 6) {
                                  verificationError.value = 'Preencha todos os 6 dígitos do código.';
                                  return;
                                }

                                final name = widget.userData?['name'] ?? '';
                                final email = widget.userData?['email'] ?? '';
                                final password = widget.userData?['password'] ?? '';

                                try {
                                  isLoadingButton.value = true;

                                  await authController.commands.signUpWithVerifiedEmail(
                                    name: name,
                                    email: email,
                                    password: password,
                                    code: code,
                                  );

                                  if (!context.mounted) return;

                                  if (authController.session.message.value != null) {
                                    verificationError.value = authController.session.message.value;
                                    return;
                                  }

                                  if (authController.session.isAuthenticated) {
                                    router.goNamed(IndigoRouteNames.home);
                                  } else {
                                    verificationError.value = 'Falha ao concluir o cadastro.';
                                  }
                                } catch (e) {
                                  if (!context.mounted) return;
                                  verificationError.value = 'Código inválido ou expirado.';
                                } finally {
                                  if (context.mounted) {
                                    isLoadingButton.value = false;
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
                        child: isLoadingButton.value
                            ? AnimatedThreeDots(color: colorScheme.onSurface)
                            : const Text(
                                'Confirmar e Criar Conta',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Botão Reenviar Código
                  Watch(
                    (context) => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: isResending.value
                            ? null
                            : () async {
                                final email = widget.userData?['email'];
                                if (email != null) {
                                  try {
                                    isResending.value = true;
                                    authController.session.clearMessage();
                                    
                                    await authController.commands.sendEmailVerificationCode(email);
                                    
                                    if (!context.mounted) return;
                                    
                                    if (authController.session.message.value != null) {
                                      verificationError.value = authController.session.message.value;
                                      return;
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Novo código enviado para o seu e-mail!')),
                                    );
                                  } catch (e) {
                                    verificationError.value = 'Erro ao reenviar o código.';
                                  } finally {
                                    if (context.mounted) {
                                      isResending.value = false;
                                    }
                                  }
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colorScheme.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isResending.value
                            ? AnimatedThreeDots(color: colorScheme.onSurface)
                            : Text(
                                'Reenviar Código',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
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