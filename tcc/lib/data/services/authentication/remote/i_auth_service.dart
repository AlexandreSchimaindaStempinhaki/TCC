import '../../../../core/failure/failure.dart';
import '../../../../core/patterns/result.dart';

import '../../../../core/typedefs/types_defs.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../../domain/models/authentication/auth_entities.dart';

abstract interface class IAuthService {
  /// Retorna a sessão atual, ou null se não houver usuário logado
  /// um Signal para reatividade
  Signal<AuthSession?> get currentSessionSignal;

  AuthSession? get currentSession => null;

  /// Inicializa a sessão carregando token local
  Future<void> initSession();

  /// Login com email e senha
  Future<AuthSessionResult> signIn(String email, String password);

  /// Login com Google
  Future<AuthSessionResult> signInWithGoogle();

  /// Reenvia o e-mail de verificação para o usuário atual
  Future<Result<void, Failure>> sendEmailVerificationLink(String email);

  /// Cria o usuário com nome, e-mail e senha no Firebase
  Future<AuthSessionResult> signUpWithVerifiedEmail({
    required String name,
    required String email,
    required String password,
  });

  /// Checa se o e-mail do usuário atual já foi verificado
  Future<Result<bool, Failure>> checkEmailVerifiedStatus();

  /// Apaga a conta pendente caso ultrapasse o limite de 30 minutos
  Future<Result<void, Failure>> deleteExpiredAccount();

  /// Logout do usuário atual
  Future<VoidResult> signOut();
}