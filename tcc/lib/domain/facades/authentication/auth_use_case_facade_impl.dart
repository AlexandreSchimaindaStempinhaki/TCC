import '../../../../core/typedefs/types_defs.dart';

import '../../../core/failure/failure.dart' show Failure;
import '../../../core/patterns/result.dart';
import '../../usecases/authentication/i_auth_usecases.dart';
import 'i_auth_use_case_facade.dart';

class AuthUseCaseFacadeImpl implements IAuthUseCaseFacade {
  final ISignInUseCase _signInUseCase;
  final ISignInWithGoogleUseCase _signInWithGoogleUseCase;
  final ISignOutUseCase _signOutUseCase;
  final ISendEmailVerificationCodeUseCase _sendEmailVerificationCodeUseCase;
  final ISignUpWithVerifiedEmailUseCase _signUpWithVerifiedEmailUseCase;

  AuthUseCaseFacadeImpl({
    required ISignInUseCase signInUseCase,
    required ISignInWithGoogleUseCase signInWithGoogleUseCase,
    required ISignOutUseCase signOutUseCase,
    required ISendEmailVerificationCodeUseCase sendEmailVerificationCodeUseCase,
    required ISignUpWithVerifiedEmailUseCase signUpWithVerifiedEmailUseCase,
  }) : _signInUseCase = signInUseCase,
       _signInWithGoogleUseCase = signInWithGoogleUseCase,
       _signOutUseCase = signOutUseCase,
       _sendEmailVerificationCodeUseCase = sendEmailVerificationCodeUseCase,
       _signUpWithVerifiedEmailUseCase = signUpWithVerifiedEmailUseCase;

  @override
  Future<AuthSessionResult> signInUseCase(SignInParams params) {
    return _signInUseCase(params);
  }

  @override
  Future<AuthSessionResult> signInWithGoogleUseCase(NoParams params) {
    return _signInWithGoogleUseCase(params);
  }

  @override
  Future<VoidResult> signOutUseCase(NoParams params) {
    return _signOutUseCase(params);
  }

  @override
  Future<Result<void, Failure>> sendEmailVerificationCodeUseCase(
    SendEmailVerificationCodeParams params,
  ) {
    return _sendEmailVerificationCodeUseCase(params);
  }

  @override
  Future<AuthSessionResult> signUpWithVerifiedEmailUseCase(
    SignUpWithVerifiedEmailParams params,
  ) {
    return _signUpWithVerifiedEmailUseCase(params);
  }
}