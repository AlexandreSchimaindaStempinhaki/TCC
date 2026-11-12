import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:tcc/core/routes/auth_routes.dart';
import 'package:tcc/presentation/widgets/text_field.dart';
import '../../widgets/header_background.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../controllers/authentication/auth_session_viewmodel.dart';
import '../../../core/di/dependency_injection.dart';
import '../../widgets/animated_three_dots.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  late final AuthViewModel authController;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  final isLoading = signal(false);
  final signupError = signal<String?>(
    null,
  ); // Signal de erro padrão igual ao do login

  @override
  void initState() {
    super.initState();
    authController = injector.get<AuthViewModel>();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
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
                // Botão de Seta para Voltar dentro de um círculo preto posicionado no topo
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors
                            .black, // Círculo preto translúcido (ou use Colors.black puro)
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          authController.session.clearMessage();
                          context.pop();
                        },
                        tooltip: 'Alterar dados',
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
                    'Criar  Conta',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  CustomTextField(
                    label: 'Nome Completo',
                    hintText: 'Seu Nome',
                    controller: _nameController,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Email',
                    hintText: 'demo@gmail.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  // Exibição de erro padronizada alinhada à esquerda (igual ao login)
                  Watch((context) {
                    if (signupError.value == null)
                      return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        signupError.value!,
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
                                signupError.value = null;
                                final name = _nameController.text.trim();
                                final email = _emailController.text.trim();

                                // Critério: Preencha todos os campos
                                if (name.isEmpty || email.isEmpty) {
                                  signupError.value =
                                      'Preencha todos os campos.';
                                  return;
                                }

                                // Critério: O nome deve conter 2 ou mais caracteres
                                if (name.length < 2) {
                                  signupError.value =
                                      'O nome deve conter pelo menos 2 caracteres.';
                                  return;
                                }

                                // Critério: Respeitar estrutura padrão de e-mail
                                if (!_isValidEmail(email)) {
                                  signupError.value =
                                      'Insira um e-mail válido.';
                                  return;
                                }

                                try {
                                  isLoading.value = true;

                                  await Future.delayed(
                                    const Duration(milliseconds: 300),
                                  );

                                  if (!context.mounted) return;

                                  router.pushNamed(
                                    AuthRouteNames.signupPassword,
                                    extra: {'name': name, 'email': email},
                                  );
                                } catch (e) {
                                  signupError.value =
                                      'Ocorreu um erro inesperado.';
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
                                'Avançar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Já tem uma conta?   ",
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.secondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.pushNamed(AuthRouteNames.login);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "Entrar",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
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
