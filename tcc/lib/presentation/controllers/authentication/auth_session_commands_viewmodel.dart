import 'dart:async';

import '../../../core/failure/failure.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/patterns/command.dart';
import '../../../core/typedefs/types_defs.dart';
import '../../../data/repositories/authentication/i_auth_repository.dart';
import '../../../domain/models/authentication/auth_entities.dart';
import '../../commands/authentication/auth_commands.dart';
import 'auth_session_state_viewmodel.dart';

class AuthSessionCommands {
  final AuthSessionState state;
  final SignInCommand _signInCommand;
  final SignInWithGoogleCommand _signInWithGoogleCommand;
  final SignOutCommand _signOutCommand;
  final IAuthRepository _repository;
  final SendEmailVerificationCodeCommand _sendEmailVerificationCodeCommand;
  final SignUpWithVerifiedEmailCommand _signUpWithVerifiedEmailCommand;

  AuthSessionCommands({
    required this.state,
    required IAuthRepository repository,
    required SignInCommand signInCommand,
    required SignInWithGoogleCommand signInWithGoogleCommand,
    required SignOutCommand signOutCommand,
    required SendEmailVerificationCodeCommand sendEmailVerificationCodeCommand,
    required SignUpWithVerifiedEmailCommand signUpWithVerifiedEmailCommand,
  })  : _repository = repository,
        _signInCommand = signInCommand,
        _signInWithGoogleCommand = signInWithGoogleCommand,
        _signOutCommand = signOutCommand,
        _sendEmailVerificationCodeCommand = sendEmailVerificationCodeCommand,
        _signUpWithVerifiedEmailCommand = signUpWithVerifiedEmailCommand {
    // Observadores que reagem automaticamente ao término dos comandos
    _observeSignIn();
    _observeSignInWithGoogle();
    _observeSession();
    _observeSendVerificationCode();
    _observeSignUpWithVerifiedEmail(); 
  }

  // ========================================================
  //   GETTERS PARA WIDGETS USAREM DIRETAMENTE OS COMANDOS
  // ========================================================
  SignInCommand get signInCommand => _signInCommand;
  SignInWithGoogleCommand get signInWithGoogleCommand => _signInWithGoogleCommand;
  SignOutCommand get signOutCommand => _signOutCommand;
  SendEmailVerificationCodeCommand get sendEmailVerificationCodeCommand => _sendEmailVerificationCodeCommand;
  SignUpWithVerifiedEmailCommand get signUpWithVerifiedEmailCommand => _signUpWithVerifiedEmailCommand;

  // ========================================================
  //   MÉTODOS PÚBLICOS (CHAMADOS PELOS WIDGETS)
  // ========================================================
  Future<void> signOut() async {
    state.clearMessage();
    await _signOutCommand.executeWith(());
  }

  Future<void> signInWithGoogle() async {
    state.clearMessage();
    await _signInWithGoogleCommand.executeWith(());
  }

  Future<void> signIn(String email, String password) async {
    state.clearMessage();
    await _signInCommand.executeWith((email: email, password: password));
  }

  // Envia o código de 6 dígitos para o e-mail
  Future<void> sendEmailVerificationCode(String email) async {
    state.clearMessage();
    await _sendEmailVerificationCodeCommand.executeWith(
      SendEmailVerificationCodeParams(email: email),
    );
  }

  // Finaliza o cadastro após validar o código OTP
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
  //   OBSERVERS ESPECÍFICOS
  // ========================================================
  void _observeSignInWithGoogle() {
    _observeCommand<AuthSession>(
      _signInWithGoogleCommand,
      onSuccess: (authSession) {
        state.setAuthenticated(authSession);
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
      },
      onFailure: (err) {
        state.setUnauthenticated(msg: err.msg);
      },
    );
  }

  void _observeSendVerificationCode() {
    _observeCommand<void>(
      _sendEmailVerificationCodeCommand,
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
      },
      onFailure: (err) {
        state.setUnauthenticated(msg: err.msg);
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
      } else {
        state.setAuthenticated(authSession);
      }
    });
  }
}