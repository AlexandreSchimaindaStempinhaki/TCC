import 'package:tcc/core/failure/failure.dart';
import 'package:tcc/core/patterns/result.dart';

import '../../../../core/typedefs/types_defs.dart';

abstract interface class IAuthUseCaseFacade {
  Future<AuthSessionResult> signInUseCase(SignInParams params);
  Future<AuthSessionResult> signInWithGoogleUseCase(NoParams params);
  Future<VoidResult> signOutUseCase(NoParams params);
  Future<Result<void, Failure>> sendEmailVerificationLinkUseCase(
    SendEmailVerificationLinkParams params,
  );
  Future<AuthSessionResult> signUpWithVerifiedEmailUseCase(
    SignUpWithVerifiedEmailParams params,
  );
  Future<Result<bool, Failure>> checkEmailVerifiedStatusUseCase(
    NoParams params,
  );
  Future<Result<void, Failure>> deleteExpiredAccountUseCase(NoParams params);
  Future<Result<void, Failure>> changePasswordUseCase(
    ChangePasswordParams params,
  );
  Future<Result<void, Failure>> deleteAccountUseCase(
    DeleteAccountParams params,
  );
  Future<Result<void, Failure>> sendPasswordResetEmailUseCase(
    SendPasswordResetEmailParams params,
  );
  Future<Result<void, Failure>> reauthenticateUseCase(String password);
  // Dados mock para fallback
  // CurrencyResult getMockCurrency();
  // CurrencyListResult getMockCurrencies();
  // HistoricalQuotesResult getMockHistoricalQuotes();
}
