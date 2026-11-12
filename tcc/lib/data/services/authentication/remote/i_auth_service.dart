import '../../../../core/failure/failure.dart';
import '../../../../core/patterns/result.dart';

import '../../../../core/typedefs/types_defs.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../../domain/models/authentication/auth_entities.dart';

abstract interface class IAuthService {
  Signal<AuthSession?> get currentSessionSignal;

  AuthSession? get currentSession => null;

  Future<void> initSession();

  Future<AuthSessionResult> signIn(String email, String password);

  Future<AuthSessionResult> signInWithGoogle();

  Future<Result<void, Failure>> sendEmailVerificationLink(String email);

  Future<AuthSessionResult> signUpWithVerifiedEmail({
    required String name,
    required String email,
    required String password,
  });

  Future<Result<bool, Failure>> checkEmailVerifiedStatus();

  Future<Result<void, Failure>> deleteExpiredAccount();

  Future<VoidResult> signOut();

  Future<Result<void, Failure>> reauthenticateWithPassword(String password);

  Future<Result<void, Failure>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<Result<void, Failure>> deleteAccount(String currentPassword);

  Future<Result<void, Failure>> sendPasswordResetEmail(String email);
}