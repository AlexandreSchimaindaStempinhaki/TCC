import '../messages/app_messages.dart';

sealed class Failure implements Exception {
  final String msg;
  Failure(this.msg);

  @override
  String toString() => '$runtimeType: $msg!!!';
}

class DefaultFailure extends Failure {
  DefaultFailure([String? msg]) : super(msg ?? AppMessages.error.defaultError);
}

class ApiLocalFailure extends Failure {
  ApiLocalFailure([String? msg])
    : super(msg ?? AppMessages.error.apiLocalError);
}

class EmptyResultFailure extends Failure {
  EmptyResultFailure([String? msg])
    : super(msg ?? AppMessages.error.emptyResultError);
}

class InputFailure extends Failure {
  InputFailure([String? msg]) : super(msg ?? AppMessages.error.inputError);
}

class InvalidDate extends Failure {
  InvalidDate([String? msg]) : super(msg ?? AppMessages.error.invalidDateError);
}

class InvalidEmail extends Failure {
  InvalidEmail([String? msg])
    : super(msg ?? AppMessages.error.invalidEmailError);
}

class InvalidPassword extends Failure {
  InvalidPassword([String? msg])
    : super(msg ?? AppMessages.error.invalidPasswordError);
}

class PasswordNotConfirmed extends Failure {
  PasswordNotConfirmed([String? msg])
    : super(msg ?? AppMessages.error.passwordMismatchError);
}

class InvalidPhone extends Failure {
  InvalidPhone([String? msg])
    : super(msg ?? AppMessages.error.invalidPhoneError);
}

class InvalidInputFailure extends Failure {
  InvalidInputFailure([String? msg])
      : super('${AppMessages.error.invalidInput}: ${msg ?? ''}');
      
}

class LoginFailure extends Failure {
  LoginFailure([String? msg]) : super(msg ?? AppMessages.error.loginFailed);
}

class GoogleLoginCancelledFailure extends Failure {
  GoogleLoginCancelledFailure([String? msg]) : super(msg ?? AppMessages.error.googleLoginCancelled);
}

class GoogleLoginFailedFailure extends Failure {
  GoogleLoginFailedFailure([String? msg]) : super(msg ?? AppMessages.error.googleLoginFailed);
}

class EmailAlreadyInUseFailure extends Failure {
  EmailAlreadyInUseFailure([String? msg]) : super(msg ?? AppMessages.error.emailAlreadyInUse);
}

class UserNotFoundFailure extends Failure {
  UserNotFoundFailure([String? msg]) : super(msg ?? AppMessages.error.userNotFound);
}

class NetworkFailure extends Failure {
  NetworkFailure([String? msg]) : super(msg ?? AppMessages.error.network);
}

class TooManyRequestsFailure extends Failure {
  TooManyRequestsFailure([String? msg]) : super(msg ?? AppMessages.error.tooManyRequests);
}

class RequiresRecentLoginFailure extends Failure {
  RequiresRecentLoginFailure([String? msg])
      : super(msg ?? AppMessages.error.requiresRecentLogin);
}

class PasswordConfirmationFailure extends Failure {
  PasswordConfirmationFailure([String? msg])
      : super(msg ?? AppMessages.error.invalidPassword);
}