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

abstract interface class ISendEmailVerificationLinkUseCase {
  Future<Result<void, Failure>> call(SendEmailVerificationLinkParams params);
}

abstract interface class ISignUpWithVerifiedEmailUseCase {
  Future<AuthSessionResult> call(SignUpWithVerifiedEmailParams params);
}

abstract interface class ICheckEmailVerifiedStatusUseCase {
  Future<Result<bool, Failure>> call(NoParams params);
}

abstract interface class IDeleteExpiredAccountUseCase {
  Future<Result<void, Failure>> call(NoParams params);
}