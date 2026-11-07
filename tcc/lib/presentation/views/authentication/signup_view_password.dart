import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/routes/auth_routes.dart';
import '../../controllers/authentication/auth_session_viewmodel.dart';
import '../../widgets/animated_three_dots.dart';
import '../../widgets/header_background.dart';
import '../../widgets/password_checklist.dart';
import '../../widgets/text_field.dart';

class SignupPasswordPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const SignupPasswordPage({
    super.key,
    required this.userData,
  });

  @override
  State<SignupPasswordPage> createState() => _SignupPasswordPageState();
}

class _SignupPasswordPageState extends State<SignupPasswordPage> {
  late final AuthViewModel authController;

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final isLoadingButton = signal(false);
  final passwordError = signal<String?>(null);

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _passwordSignal = signal('');
  final _confirmPasswordSignal = signal('');

  @override
  void initState() {
    super.initState();
    authController = injector.get<AuthViewModel>();
    // Limpa mensagens residuais anteriores
    authController.session.clearMessage();

    _passwordController.addListener(() {
      _passwordSignal.value = _passwordController.text;
    });
    _confirmPasswordController.addListener(() {
      _confirmPasswordSignal.value = _confirmPasswordController.text;
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordSignal.dispose();
    _confirmPasswordSignal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final router = GoRouter.of(context);

    final pwd = _passwordSignal.value;
    final confirmPwd = _confirmPasswordSignal.value;

    final hasMinLength = pwd.length >= 6;
    final hasUppercase = pwd.contains(RegExp(r'[A-Z]'));
    final hasNumber = pwd.contains(RegExp(r'[0-9]'));
    final hasSymbol = pwd.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    final passwordsMatch = pwd.isNotEmpty && pwd == confirmPwd;

    final isFormValid = hasMinLength && hasUppercase && hasNumber && hasSymbol && passwordsMatch;

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
                    'Criar Senha',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  CustomTextField(
                    label: 'Senha',
                    hintText: '••••••••',
                    controller: _passwordController,
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
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Confirmar Senha',
                    hintText: '••••••••',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: colorScheme.secondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  Watch(
                    (context) => PasswordChecklist(
                      password: pwd,
                      hasMinLength: hasMinLength,
                      hasUppercase: hasUppercase,
                      hasNumber: hasNumber,
                      hasSymbol: hasSymbol,
                      passwordsMatch: passwordsMatch,
                    ),
                  ),

                  Watch(
                    (context) => passwordError.value != null || authController.session.message.value != null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 12.0, left: 4.0),
                            child: Text(
                              passwordError.value ?? authController.session.message.value ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 28),

                  Watch(
                    (context) => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (isLoadingButton.value || !isFormValid)
                            ? null
                            : () async {
                                passwordError.value = null;
                                authController.session.clearMessage();

                                final email = widget.userData?['email'] ?? '';
                                final name = widget.userData?['name'] ?? '';

                                if (email.isEmpty) {
                                  passwordError.value = 'E-mail não encontrado. Reinicie o cadastro.';
                                  return;
                                }

                                try {
                                  isLoadingButton.value = true;

                                  // Dispara o envio do código e aguarda o término
                                  await authController.commands.sendEmailVerificationCode(email);

                                  if (!context.mounted) return;

                                  // Se houver erro retornado pelo state, exibe na tela e interrompe
                                  if (authController.session.message.value != null) {
                                    passwordError.value = authController.session.message.value;
                                    return;
                                  }

                                  router.pushNamed(
                                    AuthRouteNames.emailVerification,
                                    extra: {
                                      'name': name,
                                      'email': email,
                                      'password': pwd,
                                    },
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  passwordError.value = 'Não foi possível enviar o código de verificação.';
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}