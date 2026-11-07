import '../../../../core/typedefs/types_defs.dart';

import '../../../core/failure/failure.dart' show Failure, DefaultFailure;
import '../../../core/patterns/result.dart';
import '../../../data/repositories/authentication/i_auth_repository.dart';
import 'i_auth_usecases.dart';

final class SignInUseCase implements ISignInUseCase {
  final IAuthRepository _authRepository;

  SignInUseCase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  @override
  Future<AuthSessionResult> call(SignInParams params) async {
    // Simula uma chamada de rede com atraso
    await Future.delayed(const Duration(seconds: 2));
    return _authRepository.signIn(params.email, params.password);
  }
}

final class SignInWithGoogleUseCase implements ISignInWithGoogleUseCase {
  final IAuthRepository _authRepository;

  SignInWithGoogleUseCase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  @override
  Future<AuthSessionResult> call(NoParams params) async {
    // Simula uma chamada de rede com atraso
    await Future.delayed(const Duration(seconds: 1));
    return _authRepository.signInWithGoogle();
  }
}

final class SignOutUseCase implements ISignOutUseCase {
  final IAuthRepository _authRepository;

  SignOutUseCase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  @override
  Future<VoidResult> call(NoParams params) async {
    // Simula uma chamada de rede com atraso
    await Future.delayed(const Duration(seconds: 3));
    return _authRepository.signOut();
  }
}

final class SendEmailVerificationCodeUseCase
    implements ISendEmailVerificationCodeUseCase {
  final IAuthRepository _authRepository;

  SendEmailVerificationCodeUseCase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  @override
  Future<Result<void, Failure>> call(
    SendEmailVerificationCodeParams params,
  ) async {
    await Future.delayed(const Duration(seconds: 1));
    return _authRepository.sendEmailVerificationCode(params.email);
  }
}

final class SignUpWithVerifiedEmailUseCase
    implements ISignUpWithVerifiedEmailUseCase {
  final IAuthRepository _authRepository;

  SignUpWithVerifiedEmailUseCase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  @override
  Future<AuthSessionResult> call(SignUpWithVerifiedEmailParams params) async {
    // Validação estrita do código OTP de 6 dígitos antes de prosseguir
    if (params.code.length != 6) {
      return Error(
        DefaultFailure('O código de verificação deve conter 6 dígitos.'),
      );
    }

    await Future.delayed(const Duration(seconds: 2));
    return _authRepository.signUpWithVerifiedEmail(
      name: params.name,
      email: params.email,
      password: params.password,
    );
  }
}
