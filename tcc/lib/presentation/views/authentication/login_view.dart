import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../widgets/animated_three_dots.dart';
import '../../widgets/header_background.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/routes/auth_routes.dart';
import '../../../core/routes/indigo_routes.dart';
import '../../widgets/text_field.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../presentation/controllers/authentication/auth_session_viewmodel.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final AuthViewModel authController;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final isLoadingButton = signal(false);
  final isLoadingGoogle = signal(false);

  final loginError = signal<String?>(null);

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    authController = injector.get<AuthViewModel>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final extraMessage = GoRouterState.of(context).extra as String?;
      if (extraMessage != null && extraMessage.isNotEmpty) {
        final colorScheme = Theme.of(context).colorScheme;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: colorScheme.error,
            content: Text(
              extraMessage,
              style: TextStyle(
                color: colorScheme.onError,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
            HeaderBackground(height: context.screenHeight * 0.3),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- CAMPO DE E-MAIL ---
                  CustomTextField(
                    label: 'Email',
                    hintText: 'demo@gmail.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

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

                  Watch(
                    (context) => loginError.value != null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                            child: Text(
                              loginError.value!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 16),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        context.pushNamed(AuthRouteNames.password);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Esqueceu a senha?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Watch(
                    (context) => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoadingButton.value
                            ? null
                            : () async {
                                loginError.value = null;

                                if (_emailController.text.isEmpty ||
                                    _passwordController.text.isEmpty) {
                                  loginError.value =
                                      'Preencha todos os campos.';
                                  return;
                                }

                                try {
                                  isLoadingButton.value = true;
                                  final router = GoRouter.of(context);

                                  await authController.commands.signIn(
                                    _emailController.text.trim(),
                                    _passwordController.text.trim(),
                                  );

                                  if (!context.mounted) return;

                                  if (authController.session.message.value !=
                                      null) {
                                    loginError.value =
                                        authController.session.message.value!;
                                    return;
                                  }

                                  final auth =
                                      authController.session.session.value;
                                  if (auth == null) {
                                    loginError.value =
                                        'Falha ao autenticar usuário.';
                                  } else {
                                    router.goNamed(IndigoRouteNames.home);
                                  }
                                } catch (e) {
                                  if (!context.mounted) return;
                                  loginError.value =
                                      'E-mail ou senha incorretos.';
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
                                'Entrar',
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
                    children: [
                      Expanded(
                        child: Divider(color: theme.dividerColor, thickness: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          'Ou continue com',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: theme.dividerColor, thickness: 1),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Watch(
                    (context) => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: isLoadingGoogle.value
                            ? null
                            : () async {
                                loginError.value = null;

                                try {
                                  isLoadingGoogle.value = true;
                                  final router = GoRouter.of(context);

                                  await authController.commands
                                      .signInWithGoogle();

                                  if (!context.mounted) return;

                                  if (authController.session.message.value !=
                                      null) {
                                    loginError.value =
                                        authController.session.message.value!;
                                    return;
                                  }

                                  final auth =
                                      authController.session.session.value;
                                  if (auth == null) {
                                    loginError.value =
                                        'Login com Google cancelado ou falhou.';
                                    return;
                                  }

                                  router.goNamed(IndigoRouteNames.home);
                                } catch (e) {
                                  if (!context.mounted) return;
                                  loginError.value =
                                      'Não foi possível entrar com o Google.';
                                } finally {
                                  if (context.mounted) {
                                    isLoadingGoogle.value = false;
                                  }
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: theme.primaryColor,
                            width: 0.75,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoadingGoogle.value
                            ? AnimatedThreeDots(color: colorScheme.onSurface)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(AppAssets.googleLogo, height: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Google',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Não tem uma conta? ",
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.secondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.pushNamed(AuthRouteNames.signup);
                        },
                        child: Text(
                          "Cadastre-se",
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
