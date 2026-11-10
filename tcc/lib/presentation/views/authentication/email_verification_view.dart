import 'dart:async';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/routes/auth_routes.dart';
import '../../../core/routes/indigo_routes.dart';
import '../../../core/typedefs/types_defs.dart';
import '../../controllers/authentication/auth_session_viewmodel.dart';
import '../../widgets/animated_three_dots.dart';
import '../../widgets/header_background.dart';

class EmailVerificationPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const EmailVerificationPage({super.key, required this.userData});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage>
    with WidgetsBindingObserver {
  late final AuthViewModel authController;

  final isLoadingButton = signal(false);
  final isResending = signal(false);
  final verificationError = signal<String?>(null);
  final userEmailSignal = signal<String>('Carregando e-mail...');

  final resendCooldown = signal<int>(0);
  Timer? _cooldownTimer;
  Timer? _expirationTimer;

  static const String _cooldownKey = 'resend_email_cooldown_target';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    authController = injector.get<AuthViewModel>();
    authController.session.clearMessage();

    _loadUserEmail();
    _checkExpirationTime();
    _startExpirationWatcher();
    _restoreOrCreateCooldown();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _expirationTimer?.cancel();
    _cooldownTimer?.cancel();
    userEmailSignal.dispose();
    isLoadingButton.dispose();
    isResending.dispose();
    verificationError.dispose();
    resendCooldown.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startExpirationWatcher();
      _restoreOrCreateCooldown(isInitial: false);
    }
  }

  void _loadUserEmail() {
    String? email = FirebaseAuth.instance.currentUser?.email;
    if ((email == null || email.isEmpty) && widget.userData != null) {
      email = widget.userData?['email'];
    }
    userEmailSignal.value = email ?? 'seu e-mail';
  }

  void _startExpirationWatcher() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.metadata.creationTime == null) return;

    final creationTimeUtc = user.metadata.creationTime!.toUtc();
    final limitTime = creationTimeUtc.add(
      const Duration(minutes: 30),
    ); // ou 30 min
    final remaining = limitTime.difference(DateTime.now().toUtc());

    _expirationTimer?.cancel();

    if (remaining.isNegative) {
      // Já expirou! Executa imediatamente
      _checkExpirationTime();
    } else {
      // Agenda a execução para o SEGUNDO EXATO da expiração
      _expirationTimer = Timer(remaining, () {
        _checkExpirationTime();
      });
    }
  }

  Future<bool> _checkExpirationTime() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.metadata.creationTime == null) return false;

    final creationTimeUtc = user.metadata.creationTime!.toUtc();
    final limitTime = creationTimeUtc.add(
      const Duration(minutes: 30),
    ); // ou 30 min

    if (DateTime.now().toUtc().isAfter(limitTime)) {
      _expirationTimer?.cancel();

      // 1. Tenta excluir no Firebase
      try {
        await authController.commands.deleteExpiredAccountCommand.executeWith(
          (),
        );
      } catch (e) {
        debugPrint('Erro ao tentar excluir no Firebase: $e');
      }

      await authController.commands.signOut();

      if (mounted) {
        context.goNamed(
          AuthPaths.login,
          extra:
              'Sua conta foi excluída porque se passaram 30 minutos. Por favor, refaça o cadastro.',
        );
      }
      return true;
    }
    return false;
  }

  Future<void> _restoreOrCreateCooldown({bool isInitial = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final targetMs = prefs.getInt(_cooldownKey);

    if (targetMs == null) {
      if (isInitial) _startCooldown(60);
      return;
    }

    final remaining = DateTime.fromMillisecondsSinceEpoch(
      targetMs,
    ).difference(DateTime.now()).inSeconds;

    if (remaining > 0) {
      _runCooldownTimer(remaining);
    } else {
      await prefs.remove(_cooldownKey);
      if (isInitial) {
        _startCooldown(60);
      } else {
        resendCooldown.value = 0;
      }
    }
  }

  Future<void> _startCooldown(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    final targetTime = DateTime.now().add(Duration(seconds: seconds));

    await prefs.setInt(_cooldownKey, targetTime.millisecondsSinceEpoch);
    _runCooldownTimer(seconds);
  }

  void _runCooldownTimer(int seconds) {
    resendCooldown.value = seconds;
    _cooldownTimer?.cancel();

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (resendCooldown.value > 1) {
        resendCooldown.value--;
      } else {
        resendCooldown.value = 0;
        timer.cancel();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_cooldownKey);
      }
    });
  }

  Future<void> _onCheckVerifiedPressed() async {
    if (isLoadingButton.value) return;

    try {
      isLoadingButton.value = true;
      verificationError.value = null;

      final isExpired = await _checkExpirationTime();
      if (isExpired) return;

      final result = await authController
          .commands
          .checkEmailVerifiedStatusCommand
          .executeWith(());

      if (!mounted) return;

      result.fold(
        onSuccess: (isVerified) {
          if (isVerified) {
            context.goNamed(IndigoRouteNames.home);
          } else {
            verificationError.value =
                'O seu e-mail ainda não foi verificado. Abra a caixa de entrada ou spam e clique no link.';
          }
        },
        onFailure: (failure) {
          verificationError.value = failure.msg;
        },
      );
    } catch (e) {
      verificationError.value = 'Erro ao verificar o status. Tente novamente.';
    } finally {
      if (mounted) {
        isLoadingButton.value = false;
      }
    }
  }

  Future<void> _onResendLinkPressed() async {
    if (isResending.value ||
        isLoadingButton.value ||
        resendCooldown.value > 0) {
      return;
    }

    try {
      isResending.value = true;
      verificationError.value = null;

      final isExpired = await _checkExpirationTime();
      if (isExpired) return;

      final email = userEmailSignal.value;
      final result = await authController
          .commands
          .sendEmailVerificationLinkCommand
          .executeWith(SendEmailVerificationLinkParams(email: email));

      if (!mounted) return;

      result.fold(
        onSuccess: (_) {
          _startCooldown(60);

          final colorScheme = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: Text(
                'Novo link de verificação enviado!',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
        onFailure: (failure) {
          verificationError.value = failure.msg;
        },
      );
    } catch (e) {
      verificationError.value = 'Erro ao reenviar o link de verificação.';
    } finally {
      if (mounted) {
        isResending.value = false;
      }
    }
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
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () async {
                          authController.session.clearMessage();
                          await authController.commands.signOut();
                          if (context.mounted) {
                            context.goNamed(AuthPaths.login);
                          }
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
                    'Verifique seu E-mail',
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

                  Watch(
                    (context) => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoadingButton.value
                            ? null
                            : _onCheckVerifiedPressed,
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

                  // Botão "Reenviar Link"
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
                            : _onResendLinkPressed,
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
    );
  }
}
