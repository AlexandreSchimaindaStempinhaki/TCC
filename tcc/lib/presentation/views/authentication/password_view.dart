import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tcc/core/extensions/context_extensions.dart';
import 'package:tcc/presentation/widgets/animated_three_dots.dart';
import '../../widgets/header_background.dart';
import '../../widgets/text_field.dart';
import '../../../core/routes/auth_routes.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../presentation/controllers/authentication/auth_session_viewmodel.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _authViewModel = injector.get<AuthViewModel>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, digite seu e-mail.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    await _authViewModel.commands.sendPasswordResetEmail(email);

    final errorMessage = _authViewModel.session.message.value;

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-mail de redefinição de senha enviado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
      _authViewModel.session.clearMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AbsorbPointer(
      absorbing: _isLoading,
      child: Scaffold(
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
                      'Recuperar  Senha',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Digite o seu e-mail cadastrado para receber as instruções para redefinir sua senha.',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.secondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),

                    CustomTextField(
                      label: 'Email',
                      hintText: 'demo@gmail.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleResetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? AnimatedThreeDots(color: colorScheme.onSurface)
                            : const Text(
                                'Enviar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Lembrou sua senha?     ",
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.secondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.pushNamed(AuthRouteNames.login),
                          child: Text(
                            "Voltar ao Login",
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
      ),
    );
  }
}