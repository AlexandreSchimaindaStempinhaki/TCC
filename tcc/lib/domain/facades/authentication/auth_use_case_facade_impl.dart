import '../../../../core/typedefs/types_defs.dart';

import '../../../core/failure/failure.dart' show Failure;
import '../../../core/patterns/result.dart';
import '../../usecases/authentication/i_auth_usecases.dart';
import 'i_auth_use_case_facade.dart';

class AuthUseCaseFacadeImpl implements IAuthUseCaseFacade {
  final ISignInUseCase _signInUseCase;
  final ISignInWithGoogleUseCase _signInWithGoogleUseCase;
  final ISignOutUseCase _signOutUseCase;
  final ISendEmailVerificationLinkUseCase _sendEmailVerificationLinkUseCase;
  final ISignUpWithVerifiedEmailUseCase _signUpWithVerifiedEmailUseCase;
  final ICheckEmailVerifiedStatusUseCase _checkEmailVerifiedStatusUseCase;
  final IDeleteExpiredAccountUseCase _deleteExpiredAccountUseCase;
  final IChangePasswordUseCase _changePasswordUseCase;
  final IDeleteAccountUseCase _deleteAccountUseCase;
  final ISendPasswordResetEmailUseCase _sendPasswordResetEmailUseCase;
  final IReauthenticateUseCase _reauthenticateUseCase;

  AuthUseCaseFacadeImpl({
    required ISignInUseCase signInUseCase,
    required ISignInWithGoogleUseCase signInWithGoogleUseCase,
    required ISignOutUseCase signOutUseCase,
    required ISendEmailVerificationLinkUseCase sendEmailVerificationLinkUseCase,
    required ISignUpWithVerifiedEmailUseCase signUpWithVerifiedEmailUseCase,
    required ICheckEmailVerifiedStatusUseCase checkEmailVerifiedStatusUseCase,
    required IDeleteExpiredAccountUseCase deleteExpiredAccountUseCase,
    required IChangePasswordUseCase changePasswordUseCase,
    required IDeleteAccountUseCase deleteAccountUseCase,
    required ISendPasswordResetEmailUseCase sendPasswordResetEmailUseCase,
    required IReauthenticateUseCase reauthenticateUseCase,
  }) : _signInUseCase = signInUseCase,
       _signInWithGoogleUseCase = signInWithGoogleUseCase,
       _signOutUseCase = signOutUseCase,
       _sendEmailVerificationLinkUseCase = sendEmailVerificationLinkUseCase,
       _signUpWithVerifiedEmailUseCase = signUpWithVerifiedEmailUseCase,
       _checkEmailVerifiedStatusUseCase = checkEmailVerifiedStatusUseCase,
       _deleteExpiredAccountUseCase = deleteExpiredAccountUseCase,
       _changePasswordUseCase = changePasswordUseCase,
       _deleteAccountUseCase = deleteAccountUseCase,
       _sendPasswordResetEmailUseCase = sendPasswordResetEmailUseCase,
       _reauthenticateUseCase = reauthenticateUseCase;

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
  Future<Result<void, Failure>> sendEmailVerificationLinkUseCase(
    SendEmailVerificationLinkParams params,
  ) {
    return _sendEmailVerificationLinkUseCase(params);
  }

  @override
  Future<AuthSessionResult> signUpWithVerifiedEmailUseCase(
    SignUpWithVerifiedEmailParams params,
  ) {
    return _signUpWithVerifiedEmailUseCase(params);
  }

  @override
  Future<Result<bool, Failure>> checkEmailVerifiedStatusUseCase(
    NoParams params,
  ) {
    return _checkEmailVerifiedStatusUseCase(params);
  }

  @override
  Future<Result<void, Failure>> deleteExpiredAccountUseCase(NoParams params) {
    return _deleteExpiredAccountUseCase(params);
  }

  @override
  Future<Result<void, Failure>> changePasswordUseCase(
    ChangePasswordParams params,
  ) {
    return _changePasswordUseCase(params);
  }

  @override
  Future<Result<void, Failure>> deleteAccountUseCase(
    DeleteAccountParams params,
  ) {
    return _deleteAccountUseCase(params);
  }

  @override
  Future<Result<void, Failure>> sendPasswordResetEmailUseCase(
    SendPasswordResetEmailParams params,
  ) {
    return _sendPasswordResetEmailUseCase(params);
  }

  @override
  Future<Result<void, Failure>> reauthenticateUseCase(String password) {
    return _reauthenticateUseCase(password);
  }
}
