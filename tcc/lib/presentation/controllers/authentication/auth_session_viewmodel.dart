import 'package:signals_flutter/signals_flutter.dart';

import '../../../data/repositories/authentication/i_auth_repository.dart';
import '../../../domain/facades/authentication/i_auth_use_case_facade.dart';
import '../../commands/authentication/auth_commands.dart';
import 'auth_session_commands_viewmodel.dart';
import 'auth_session_state_viewmodel.dart';

class AuthViewModel {
  final IAuthRepository _repository;
  late final AuthSessionState _session;
  late final AuthSessionCommands _commands;
  late final Signal<bool> _loading;

  AuthSessionState get session => _session;
  AuthSessionCommands get commands => _commands;
  ReadonlySignal<bool> get loading => _loading.readonly();

  AuthViewModel(this._repository, IAuthUseCaseFacade facade) {
    _session = AuthSessionState();

    _commands = AuthSessionCommands(
      repository: _repository,
      state: session,
      signInCommand: SignInCommand(facade),
      signInWithGoogleCommand: SignInWithGoogleCommand(facade),
      signOutCommand: SignOutCommand(facade),
      sendEmailVerificationLinkCommand: SendEmailVerificationLinkCommand(facade),
      signUpWithVerifiedEmailCommand: SignUpWithVerifiedEmailCommand(facade),
      checkEmailVerifiedStatusCommand: CheckEmailVerifiedStatusCommand(facade),
      deleteExpiredAccountCommand: DeleteExpiredAccountCommand(facade),
      changePasswordCommand: ChangePasswordCommand(facade),
      deleteAccountCommand: DeleteAccountCommand(facade),
      sendPasswordResetEmailCommand: SendPasswordResetEmailCommand(facade),
      reauthenticateCommand: ReauthenticateCommand(facade), // <--- ADICIONADO AQUI
    );

    _loading = signal(false);
  }

  SignInCommand get signInCommand => _commands.signInCommand;
  SignInWithGoogleCommand get signInWithGoogleCommand => _commands.signInWithGoogleCommand;
  SignOutCommand get signOutCommand => commands.signOutCommand;
  SendEmailVerificationLinkCommand get sendEmailVerificationLinkCommand => _commands.sendEmailVerificationLinkCommand;
  SignUpWithVerifiedEmailCommand get signUpWithVerifiedEmailCommand => _commands.signUpWithVerifiedEmailCommand;
  CheckEmailVerifiedStatusCommand get checkEmailVerifiedStatusCommand => _commands.checkEmailVerifiedStatusCommand;
  DeleteExpiredAccountCommand get deleteExpiredAccountCommand => _commands.deleteExpiredAccountCommand;
  ChangePasswordCommand get changePasswordCommand => _commands.changePasswordCommand;
  DeleteAccountCommand get deleteAccountCommand => _commands.deleteAccountCommand;
  SendPasswordResetEmailCommand get sendPasswordResetEmailCommand => _commands.sendPasswordResetEmailCommand;
  ReauthenticateCommand get reauthenticateCommand => _commands.reauthenticateCommand;
}