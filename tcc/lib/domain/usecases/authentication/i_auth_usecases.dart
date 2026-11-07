import 'package:tcc/core/failure/failure.dart';

import '../../../../core/typedefs/types_defs.dart';

import '../../../../core/patterns/i_usecases.dart';
import '../../../core/patterns/result.dart';

abstract interface class ISignInUseCase
    implements IUseCase<AuthSessionResult, SignInParams> {}

abstract interface class ISignInWithGoogleUseCase
    implements IUseCase<AuthSessionResult, NoParams> {}

abstract interface class ISignOutUseCase
    implements IUseCase<VoidResult, NoParams> {}

abstract interface class ISendEmailVerificationCodeUseCase {
  Future<Result<void, Failure>> call(SendEmailVerificationCodeParams params);
}

abstract interface class ISignUpWithVerifiedEmailUseCase {
  Future<AuthSessionResult> call(SignUpWithVerifiedEmailParams params);
}
