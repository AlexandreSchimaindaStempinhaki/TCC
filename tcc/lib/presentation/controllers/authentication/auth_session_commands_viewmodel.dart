import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/failure/failure.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/patterns/command.dart';
import '../../../core/typedefs/types_defs.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../data/repositories/authentication/i_auth_repository.dart';
import '../../../domain/models/authentication/auth_entities.dart';
import '../../commands/authentication/auth_commands.dart';
import '../../controllers/user_viewmodel.dart';
import 'auth_session_state_viewmodel.dart';

class AuthSessionCommands {
  final AuthSessionState state;
  final SignInCommand _signInCommand;
  final SignInWithGoogleCommand _signInWithGoogleCommand;
  final SignOutCommand _signOutCommand;
  final IAuthRepository _repository;
  final SendEmailVerificationLinkCommand _sendEmailVerificationLinkCommand;
  final SignUpWithVerifiedEmailCommand _signUpWithVerifiedEmailCommand;
  final CheckEmailVerifiedStatusCommand _checkEmailVerifiedStatusCommand;
  final DeleteExpiredAccountCommand _deleteExpiredAccountCommand;
  final ChangePasswordCommand _changePasswordCommand;
  final DeleteAccountCommand _deleteAccountCommand;
  final SendPasswordResetEmailCommand _sendPasswordResetEmailCommand;

  AuthSessionCommands({
    required this.state,
    required IAuthRepository repository,
    required SignInCommand signInCommand,
    required SignInWithGoogleCommand signInWithGoogleCommand,
    required SignOutCommand signOutCommand,
    required SendEmailVerificationLinkCommand sendEmailVerificationLinkCommand,
    required SignUpWithVerifiedEmailCommand signUpWithVerifiedEmailCommand,
    required CheckEmailVerifiedStatusCommand checkEmailVerifiedStatusCommand,
    required DeleteExpiredAccountCommand deleteExpiredAccountCommand,
    required ChangePasswordCommand changePasswordCommand,
    required DeleteAccountCommand deleteAccountCommand,
    required SendPasswordResetEmailCommand sendPasswordResetEmailCommand,
  }) : _repository = repository,
       _signInCommand = signInCommand,
       _signInWithGoogleCommand = signInWithGoogleCommand,
       _signOutCommand = signOutCommand,
       _sendEmailVerificationLinkCommand = sendEmailVerificationLinkCommand,
       _signUpWithVerifiedEmailCommand = signUpWithVerifiedEmailCommand,
       _checkEmailVerifiedStatusCommand = checkEmailVerifiedStatusCommand,
       _deleteExpiredAccountCommand = deleteExpiredAccountCommand,
       _changePasswordCommand = changePasswordCommand,
       _deleteAccountCommand = deleteAccountCommand,
       _sendPasswordResetEmailCommand = sendPasswordResetEmailCommand {
    _observeSignIn();
    _observeSignInWithGoogle();
    _observeSession();
    _observeSendVerificationLink();
    _observeSignUpWithVerifiedEmail();
    _observeCheckEmailVerifiedStatus();
    _observeDeleteExpiredAccount();
    _observeChangePassword();
    _observeDeleteAccount();
    _observeSendPasswordResetEmail();
  }

  // ========================================================
  //   GETTERS PARA WIDGETS USAREM DIRETAMENTE OS COMANDOS
  // ========================================================
  SignInCommand get signInCommand => _signInCommand;
  SignInWithGoogleCommand get signInWithGoogleCommand =>
      _signInWithGoogleCommand;
  SignOutCommand get signOutCommand => _signOutCommand;
  SendEmailVerificationLinkCommand get sendEmailVerificationLinkCommand =>
      _sendEmailVerificationLinkCommand;
  SignUpWithVerifiedEmailCommand get signUpWithVerifiedEmailCommand =>
      _signUpWithVerifiedEmailCommand;
  CheckEmailVerifiedStatusCommand get checkEmailVerifiedStatusCommand =>
      _checkEmailVerifiedStatusCommand;
  DeleteExpiredAccountCommand get deleteExpiredAccountCommand =>
      _deleteExpiredAccountCommand;
  ChangePasswordCommand get changePasswordCommand => _changePasswordCommand;
  DeleteAccountCommand get deleteAccountCommand => _deleteAccountCommand;
  SendPasswordResetEmailCommand get sendPasswordResetEmailCommand =>
      _sendPasswordResetEmailCommand;

  // ========================================================
  //   MÉTODOS PÚBLICOS (CHAMADOS PELOS WIDGETS)
  // ========================================================
  Future<void> signOut() async {
    state.clearMessage();
    await _signOutCommand.executeWith(());

    try {
      injector.get<UserViewModel>().state.user.value = null;
    } catch (_) {}
  }

  Future<void> signInWithGoogle() async {
    state.clearMessage();
    await _signInWithGoogleCommand.executeWith(());
  }

  Future<void> signIn(String email, String password) async {
    state.clearMessage();
    await _signInCommand.executeWith((email: email, password: password));
  }

  Future<void> sendEmailVerificationCode(String email) async {
    state.clearMessage();
    await _sendEmailVerificationLinkCommand.executeWith(
      SendEmailVerificationLinkParams(email: email),
    );
  }

  Future<void> signUpWithVerifiedEmail({
    required String name,
    required String email,
    required String password,
    required String code,
  }) async {
    state.clearMessage();
    await _signUpWithVerifiedEmailCommand.executeWith(
      SignUpWithVerifiedEmailParams(
        name: name,
        email: email,
        password: password,
        code: code,
      ),
    );
  }

  Future<void> checkEmailVerifiedStatus() async {
    state.clearMessage();
    await _checkEmailVerifiedStatusCommand.executeWith(());
  }

  Future<void> deleteExpiredAccount() async {
    state.clearMessage();
    await _deleteExpiredAccountCommand.executeWith(());
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    state.clearMessage();
    await _changePasswordCommand.executeWith(
      ChangePasswordParams(
        currentPassword: currentPassword, 
        newPassword: newPassword,
      ),
    );
  }

  Future<void> deleteAccount(String currentPassword) async {
    state.clearMessage();
    await _deleteAccountCommand.executeWith(
      DeleteAccountParams(currentPassword: currentPassword),
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state.clearMessage();
    await _sendPasswordResetEmailCommand.executeWith(
      SendPasswordResetEmailParams(email: email),
    );
  }

  Future<void> _fetchUserAfterAuthentication() async {
    try {
      await injector.get<UserViewModel>().commands.fetchUser();
    } catch (e) {
      state.setMessage('Não foi possível carregar os dados do usuário: $e');
    }
  }

  // ========================================================
  //   MÉTODO GENÉRICO DE OBSERVAÇÃO DE COMANDOS
  // ========================================================
  void _observeCommand<T>(
    Command<T, Failure> command, {
    required void Function(T data) onSuccess,
    void Function(Failure err)? onFailure,
  }) {
    effect(() {
      if (command.isExecuting.value) return;

      final result = command.result.value;
      if (result == null) return;

      result.fold(
        onSuccess: (data) {
          state.clearMessage();
          onSuccess(data);
        },
        onFailure: (err) {
          state.setMessage(err.msg);
          if (onFailure != null) onFailure(err);
        },
      );
    });
  }

  // ========================================================
  //   OBSERVERS ESPECÍFICOS (COM ATUALIZAÇÃO DE USUÁRIO)
  // ========================================================
  void _observeSignInWithGoogle() {
    _observeCommand<AuthSession>(
      _signInWithGoogleCommand,
      onSuccess: (authSession) {
        state.setAuthenticated(authSession);
        unawaited(_fetchUserAfterAuthentication());
      },
      onFailure: (err) {
        state.setUnauthenticated(msg: err.msg);
      },
    );
  }

  void _observeSignIn() {
    _observeCommand<AuthSession>(
      _signInCommand,
      onSuccess: (authSession) {
        state.setAuthenticated(authSession);

        unawaited(_fetchUserAfterAuthentication());
      },
      onFailure: (err) {
        state.setUnauthenticated(msg: err.msg);
      },
    );
  }

  void _observeSendVerificationLink() {
    _observeCommand<void>(
      _sendEmailVerificationLinkCommand,
      onSuccess: (_) {
        state.clearMessage();
      },
      onFailure: (err) {
        state.setMessage(err.msg);
      },
    );
  }

  void _observeSignUpWithVerifiedEmail() {
    _observeCommand<AuthSession>(
      _signUpWithVerifiedEmailCommand,
      onSuccess: (authSession) {
        state.setAuthenticated(authSession);

        unawaited(_fetchUserAfterAuthentication());
      },
      onFailure: (err) {
        state.setUnauthenticated(msg: err.msg);
      },
    );
  }

  void _observeCheckEmailVerifiedStatus() {
    _observeCommand<bool>(
      _checkEmailVerifiedStatusCommand,
      onSuccess: (_) {
        state.clearMessage();
      },
      onFailure: (err) {
        state.setMessage(err.msg);
      },
    );
  }

  void _observeDeleteExpiredAccount() {
    _observeCommand<void>(
      _deleteExpiredAccountCommand,
      onSuccess: (_) {
        state.setUnauthenticated();
        try {
          injector.get<UserViewModel>().state.user.value = null;
        } catch (_) {}
      },
      onFailure: (err) {
        state.setMessage(err.msg);
      },
    );
  }

  void _observeChangePassword() {
    _observeCommand<void>(
      _changePasswordCommand,
      onSuccess: (_) {
        state.clearMessage();
      },
      onFailure: (err) {
        state.setMessage(err.msg);
      },
    );
  }

  void _observeDeleteAccount() {
    _observeCommand<void>(
      _deleteAccountCommand,
      onSuccess: (_) {
        state.setUnauthenticated();
        try {
          injector.get<UserViewModel>().state.user.value = null;
        } catch (_) {}
      },
      onFailure: (err) {
        state.setMessage(err.msg);
      },
    );
  }

  void _observeSendPasswordResetEmail() {
    _observeCommand<void>(
      _sendPasswordResetEmailCommand,
      onSuccess: (_) {
        state.clearMessage();
      },
      onFailure: (err) {
        state.setMessage(err.msg);
      },
    );
  }

  void _observeSession() {
    effect(() {
      final authSession = _repository.sessionSignal.value;

      if (authSession == null) {
        state.setUnauthenticated();
      } else if (authSession.token.isExpired) {
        state.setExpired(msg: 'Sessão expirada');
        unawaited(_repository.signOut());
        try {
          injector.get<UserViewModel>().state.user.value = null;
        } catch (_) {}
      } else {
        state.setAuthenticated(authSession);
      }
    });
  }
}