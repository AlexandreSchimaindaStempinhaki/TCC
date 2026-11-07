import 'package:tcc/core/failure/failure.dart';
import 'package:tcc/core/patterns/result.dart';

import '../../../../core/typedefs/types_defs.dart';

abstract interface class IAuthUseCaseFacade {
  Future<AuthSessionResult> signInUseCase(SignInParams params);
  Future<AuthSessionResult> signInWithGoogleUseCase(NoParams params);
  Future<VoidResult> signOutUseCase(NoParams params);
  Future<Result<void, Failure>> sendEmailVerificationCodeUseCase(
    SendEmailVerificationCodeParams params,
  );
  Future<AuthSessionResult> signUpWithVerifiedEmailUseCase(
    SignUpWithVerifiedEmailParams params,
  );
  // Dados mock para fallback
  // CurrencyResult getMockCurrency();
  // CurrencyListResult getMockCurrencies();
  // HistoricalQuotesResult getMockHistoricalQuotes();
}