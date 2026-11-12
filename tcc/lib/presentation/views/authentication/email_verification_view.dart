import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../widgets/animated_three_dots.dart';
import '../../widgets/header_background.dart';
import '../mixins/email_verification_logic.dart';

class EmailVerificationPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const EmailVerificationPage({super.key, required this.userData});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage>
    with WidgetsBindingObserver, EmailVerificationLogic {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initLogic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disposeLogic();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      handleAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // PopScope impede a saída direta e chama o pop-up de confirmação
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await showCancelConfirmationDialog();
      },
      child: Scaffold(
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
                          onPressed: showCancelConfirmationDialog,
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
                      'Verifique  seu  E-mail',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Enviamos um link de confirmação para:',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Watch(
                      (context) => Text(
                        userEmailSignal.value,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Abra sua caixa de entrada (e verifique também a pasta de Spam) e clique no link para ativar sua conta. O cadastro expira em 30 minutos.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    Watch(
                      (context) => verificationError.value != null
                          ? Padding(
                              padding: const EdgeInsets.only(
                                bottom: 16.0,
                                left: 4.0,
                              ),
                              child: Text(
                                verificationError.value!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    // Botão "Já verifiquei meu e-mail"
                    Watch(
                      (context) => SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoadingButton.value
                              ? null
                              : onCheckVerifiedPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoadingButton.value
                              ? const AnimatedThreeDots(color: Colors.white)
                              : const Text(
                                  'Já verifiquei meu e-mail',
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

                    Watch(
                      (context) => SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed:
                              (isResending.value ||
                                  isLoadingButton.value ||
                                  resendCooldown.value > 0)
                              ? null
                              : onResendLinkPressed,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: resendCooldown.value > 0
                                  ? colorScheme.secondary.withOpacity(0.4)
                                  : colorScheme.primary,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isResending.value
                              ? AnimatedThreeDots(color: colorScheme.onSurface)
                              : Text(
                                  resendCooldown.value > 0
                                      ? 'Reenviar Link (${resendCooldown.value}s)'
                                      : 'Reenviar Link',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: resendCooldown.value > 0
                                        ? colorScheme.secondary
                                        : colorScheme.primary,
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
      ),
    );
  }
}
