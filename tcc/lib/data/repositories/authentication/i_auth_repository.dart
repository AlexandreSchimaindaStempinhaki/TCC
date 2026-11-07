import '../../../../core/typedefs/types_defs.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../domain/models/authentication/auth_entities.dart';
import '../../../core/patterns/result.dart';
import '../../../core/failure/failure.dart';

/// Interface para o repositório de autenticação
abstract class IAuthRepository {
  /// Retorna a sessão atual, ou null se não houver usuário logado
  AuthSession? get currentSession;

  /// Signal reativo da sessão atual
  Signal<AuthSession?> get sessionSignal;

  /// Login com email e senha
  Future<AuthSessionResult> signIn(String email, String password);

  /// login com Google
  Future<AuthSessionResult> signInWithGoogle();

  Future<Result<void, Failure>> sendEmailVerificationCode(String email);

  /// Cria o usuário de fato após a validação do e-mail
  Future<AuthSessionResult> signUpWithVerifiedEmail({
    required String name,
    required String email,
    required String password,
  });

  /// Logout do usuário atual
  Future<VoidResult> signOut();
}