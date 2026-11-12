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

  /// Login com Google
  Future<AuthSessionResult> signInWithGoogle();

  /// Reenvia o e-mail de verificação
  Future<Result<void, Failure>> sendEmailVerificationLink(String email);

  /// Cria o usuário de fato no Firebase
  Future<AuthSessionResult> signUpWithVerifiedEmail({
    required String name,
    required String email,
    required String password,
  });

  /// Checa se o e-mail do usuário atual já foi verificado
  Future<Result<bool, Failure>> checkEmailVerifiedStatus();

  /// Apaga a conta pendente caso ultrapasse o tempo limite de 30 minutos
  Future<Result<void, Failure>> deleteExpiredAccount();

  /// Logout do usuário atual
  Future<VoidResult> signOut();

  Future<Result<void, Failure>> reauthenticateWithPassword(String password);

  Future<Result<void, Failure>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<Result<void, Failure>> deleteAccount(String currentPassword);

  Future<Result<void, Failure>> sendPasswordResetEmail(String email);
}