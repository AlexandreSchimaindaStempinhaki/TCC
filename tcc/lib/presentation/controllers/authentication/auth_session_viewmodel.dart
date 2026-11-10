import 'package:signals_flutter/signals_flutter.dart';

import '../../../data/repositories/authentication/i_auth_repository.dart';
import '../../../domain/facades/authentication/i_auth_use_case_facade.dart';
import '../../commands/authentication/auth_commands.dart';
import 'auth_session_commands_viewmodel.dart';
import 'auth_session_state_viewmodel.dart';

/// ViewModel responsável por gerenciar o estado de autenticação
/// Mantém o estado da sessão e o loading de forma reativa usando signals
class AuthViewModel {
  /// repositoty necessário para saber o estado da sessão
  final IAuthRepository _repository;

  /// Estado da sessão (usuário, token e status)
  late final AuthSessionState _session;

  /// dispara os commands e effects
  late final AuthSessionCommands _commands;

  /// Signal de loading para indicar operações em andamento
  late final Signal<bool> _loading;

  /// Getter público para acessar o estado da sessão
  AuthSessionState get session => _session;

  /// Getter público para acessar o estado da sessão
  AuthSessionCommands get commands => _commands;

  /// Getter público para acessar o signal de loading
  ReadonlySignal<bool> get loading => _loading.readonly();

  /// Construtor que recebe o repositório de autenticação
  /// Inicializa os signals e cria um efeito reativo para atualizar a sessão
  AuthViewModel(this._repository, IAuthUseCaseFacade facade) {
    // Estado reativo da sessão (usuário, token e status)
    _session = AuthSessionState();

    // dispara os commands e effects
    _commands = AuthSessionCommands(
      repository: _repository,
      state: session,
      signInCommand: SignInCommand(facade),
      signInWithGoogleCommand: SignInWithGoogleCommand(facade),
      signOutCommand: SignOutCommand(facade),
      sendEmailVerificationLinkCommand: SendEmailVerificationLinkCommand(
        facade,
      ),
      signUpWithVerifiedEmailCommand: SignUpWithVerifiedEmailCommand(facade),
      checkEmailVerifiedStatusCommand: CheckEmailVerifiedStatusCommand(facade),
      deleteExpiredAccountCommand: DeleteExpiredAccountCommand(facade),
    );

    // Signal para indicar operações em andamento (login, registro, logout)
    _loading = signal(false);
  }

  // --- Comandos expostos ---
  SignInCommand get signInCommand => _commands.signInCommand;
  SignInWithGoogleCommand get signInWithGoogleCommand =>
      _commands.signInWithGoogleCommand;
  SignOutCommand get signOutCommand => commands.signOutCommand;
  SendEmailVerificationLinkCommand get sendEmailVerificationLinkCommand =>
      _commands.sendEmailVerificationLinkCommand;
  SignUpWithVerifiedEmailCommand get signUpWithVerifiedEmailCommand =>
      _commands.signUpWithVerifiedEmailCommand;
  CheckEmailVerifiedStatusCommand get checkEmailVerifiedStatusCommand =>
      _commands.checkEmailVerifiedStatusCommand;
  DeleteExpiredAccountCommand get deleteExpiredAccountCommand =>
      _commands.deleteExpiredAccountCommand;
}