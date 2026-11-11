import 'dart:async';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tcc/presentation/widgets/logout_confirmation.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../core/routes/auth_routes.dart';
import '../../../core/routes/indigo_routes.dart';
import '../../../core/typedefs/types_defs.dart';
import '../../controllers/authentication/auth_session_viewmodel.dart';
import '../authentication/email_verification_view.dart'; // <-- Adicione este import para reconhecer a classe

// Restringe diretamente ao State da EmailVerificationPage
mixin EmailVerificationLogic on State<EmailVerificationPage> {
  late final AuthViewModel authController;

  final isLoadingButton = signal(false);
  final isResending = signal(false);
  final verificationError = signal<String?>(null);
  final userEmailSignal = signal<String>('Carregando e-mail...');

  final resendCooldown = signal<int>(0);
  Timer? _cooldownTimer;
  Timer? _expirationTimer;

  static const String _cooldownKey = 'resend_email_cooldown_target';

  void initLogic() {
    authController = injector.get<AuthViewModel>();
    authController.session.clearMessage();

    _loadUserEmail();
    _checkExpirationTime();
    _startExpirationWatcher();
    _restoreOrCreateCooldown();
  }

  void disposeLogic() {
    _expirationTimer?.cancel();
    _cooldownTimer?.cancel();
    userEmailSignal.dispose();
    isLoadingButton.dispose();
    isResending.dispose();
    verificationError.dispose();
    resendCooldown.dispose();
  }

  void handleAppResumed() {
    _startExpirationWatcher();
    _restoreOrCreateCooldown(isInitial: false);
  }

  void _loadUserEmail() {
    // Como agora o mixin sabe que está em EmailVerificationPage, podemos usar widget.userData diretamente!
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
    final limitTime = creationTimeUtc.add(const Duration(minutes: 30));
    final remaining = limitTime.difference(DateTime.now().toUtc());

    _expirationTimer?.cancel();

    if (remaining.isNegative) {
      _checkExpirationTime();
    } else {
      _expirationTimer = Timer(remaining, () {
        _checkExpirationTime();
      });
    }
  }

  Future<bool> _checkExpirationTime() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.metadata.creationTime == null) return false;

    final creationTimeUtc = user.metadata.creationTime!.toUtc();
    final limitTime = creationTimeUtc.add(const Duration(minutes: 30));

    if (DateTime.now().toUtc().isAfter(limitTime)) {
      _expirationTimer?.cancel();

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

  Future<void> onCheckVerifiedPressed() async {
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

  Future<void> onResendLinkPressed() async {
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

  Future<void> onSignOutPressed() async {
    authController.session.clearMessage();
    await authController.commands.signOut();
    if (mounted) {
      context.goNamed(AuthPaths.login);
    }
  }

  Future<void> showCancelConfirmationDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return LogoutConfirmation(
          title: 'Cancelar  Cadastro',
          content:
              'Se você sair agora, sua conta será excluída e o cadastro cancelado. Deseja realmente continuar?',
          confirmText: 'Sim, cancelar',
          onConfirm: () async {
            try {
              await authController.commands.deleteExpiredAccountCommand
                  .executeWith(());
            } catch (e) {
              debugPrint('Erro ao excluir conta cancelada: $e');
            }

            await authController.commands.signOut();

            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }

            if (mounted) {
              context.goNamed(
                AuthPaths.login,
                extra: 'Cadastro cancelado com sucesso.',
              );
            }
          },
        );
      },
    );
  }
}
