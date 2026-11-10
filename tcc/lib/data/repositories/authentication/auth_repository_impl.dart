import '../../../../core/typedefs/types_defs.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/failure/failure.dart';
import '../../../core/patterns/result.dart';
import '../../../domain/models/authentication/auth_entities.dart';
import '../../services/authentication/remote/i_auth_service.dart';
import 'i_auth_repository.dart';

/// Implementação concreta do repositório de autenticação
/// Encapsula o AuthService e fornece acesso reativo à sessão
class AuthRepositoryImpl implements IAuthRepository {
  /// Serviço de autenticação subjacente
  final IAuthService _authService;

  AuthRepositoryImpl(this._authService);

  /// Retorna a sessão atual (ou null se não houver usuário logado)
  @override
  AuthSession? get currentSession => _authService.currentSession;

  /// Signal reativo da sessão, repassa do service
  @override
  Signal<AuthSession?> get sessionSignal => _authService.currentSessionSignal;

  /// Realiza login com email e senha
  @override
  Future<AuthSessionResult> signIn(String email, String password) {
    return _authService.signIn(email, password);
  }

  /// Realiza login com Google
  @override
  Future<AuthSessionResult> signInWithGoogle() {
    return _authService.signInWithGoogle();
  }

  /// Reenvia o e-mail de verificação
  @override
  Future<Result<void, Failure>> sendEmailVerificationLink(String email) async {
    return await _authService.sendEmailVerificationLink(email);
  }

  /// Registro de usuário com email e senha
  @override
  Future<AuthSessionResult> signUpWithVerifiedEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    return await _authService.signUpWithVerifiedEmail(
      name: name,
      email: email,
      password: password,
    );
  }

  /// Checa se o e-mail foi verificado
  @override
  Future<Result<bool, Failure>> checkEmailVerifiedStatus() async {
    return await _authService.checkEmailVerifiedStatus();
  }

  /// Exclui a conta expirada após 30 minutos
  @override
  Future<Result<void, Failure>> deleteExpiredAccount() async {
    return await _authService.deleteExpiredAccount();
  }

  /// Logout do usuário atual
  @override
  Future<VoidResult> signOut() {
    return _authService.signOut();
  }
}