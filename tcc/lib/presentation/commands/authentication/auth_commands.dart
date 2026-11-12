import '../../../../core/failure/failure.dart';
import '../../../../core/typedefs/types_defs.dart';

import '../../../../core/patterns/command.dart';
import '../../../../core/patterns/result.dart';
import '../../../../domain/facades/authentication/i_auth_use_case_facade.dart';
import '../../../../../domain/models/authentication/auth_entities.dart';

final class SignInCommand
    extends ParameterizedCommand<AuthSession, Failure, SignInParams> {
  final IAuthUseCaseFacade _authUseCaseFacade;

  SignInCommand(this._authUseCaseFacade);

  @override
  Future<AuthSessionResult> execute() async {
    if (parameter == null ||
        parameter!.email.isEmpty ||
        parameter!.password.isEmpty) {
      return Error(InvalidInputFailure('Parâmetros de login inválidos.'));
    }

    return await _authUseCaseFacade.signInUseCase(parameter!);
  }
}

final class SignInWithGoogleCommand
    extends ParameterizedCommand<AuthSession, Failure, NoParams> {
  final IAuthUseCaseFacade _authUseCaseFacade;

  SignInWithGoogleCommand(this._authUseCaseFacade);

  @override
  Future<AuthSessionResult> execute() async {
    if (parameter == null) {
      return Error(
        InvalidInputFailure('Parâmetros de login Gooogle inválidos.'),
      );
    }
    return await _authUseCaseFacade.signInWithGoogleUseCase(parameter!);
  }
}

final class SignOutCommand
    extends ParameterizedCommand<void, Failure, NoParams> {
  final IAuthUseCaseFacade _authUseCaseFacade;

  SignOutCommand(this._authUseCaseFacade);

  @override
  Future<VoidResult> execute() async {
    if (parameter == null) {
      return Error(InvalidInputFailure('Erro ao realir sign-out.'));
    }
    return await _authUseCaseFacade.signOutUseCase(parameter!);
  }
}

final class SendEmailVerificationLinkCommand
    extends
        ParameterizedCommand<void, Failure, SendEmailVerificationLinkParams> {
  final IAuthUseCaseFacade _authUseCaseFacade;

  SendEmailVerificationLinkCommand(this._authUseCaseFacade);

  @override
  Future<Result<void, Failure>> execute() async {
    if (parameter == null || parameter!.email.isEmpty) {
      return Error(
        InvalidInputFailure(
          'Parâmetros de envio do link de verificação inválidos.',
        ),
      );
    }

    return await _authUseCaseFacade.sendEmailVerificationLinkUseCase(
      parameter!,
    );
  }
}

final class SignUpWithVerifiedEmailCommand
    extends
        ParameterizedCommand<
          AuthSession,
          Failure,
          SignUpWithVerifiedEmailParams
        > {
  final IAuthUseCaseFacade _authUseCaseFacade;

  SignUpWithVerifiedEmailCommand(this._authUseCaseFacade);

  @override
  Future<AuthSessionResult> execute() async {
    if (parameter == null ||
        parameter!.email.isEmpty ||
        parameter!.password.isEmpty ||
        parameter!.code.isEmpty) {
      return Error(
        InvalidInputFailure(
          'Parâmetros de registro com email verificado inválidos.',
        ),
      );
    }

    return await _authUseCaseFacade.signUpWithVerifiedEmailUseCase(parameter!);
  }
}

final class CheckEmailVerifiedStatusCommand
    extends ParameterizedCommand<bool, Failure, NoParams> {
  final IAuthUseCaseFacade _authUseCaseFacade;

  CheckEmailVerifiedStatusCommand(this._authUseCaseFacade);

  @override
  Future<Result<bool, Failure>> execute() async {
    if (parameter == null) {
      return Error(
        InvalidInputFailure('Parâmetros de verificação de e-mail inválidos.'),
      );
    }

    return await _authUseCaseFacade.checkEmailVerifiedStatusUseCase(parameter!);
  }
}

final class DeleteExpiredAccountCommand
    extends ParameterizedCommand<void, Failure, NoParams> {
  final IAuthUseCaseFacade _authUseCaseFacade;

  DeleteExpiredAccountCommand(this._authUseCaseFacade);

  @override
  Future<Result<void, Failure>> execute() async {
    if (parameter == null) {
      return Error(
        InvalidInputFailure('Parâmetros de exclusão de conta inválidos.'),
      );
    }

    return await _authUseCaseFacade.deleteExpiredAccountUseCase(parameter!);
  }
}

final class ChangePasswordCommand
    extends ParameterizedCommand<void, Failure, ChangePasswordParams> {
  final IAuthUseCaseFacade _authUseCaseFacade;

  ChangePasswordCommand(this._authUseCaseFacade);

  @override
  Future<Result<void, Failure>> execute() async {
    if (parameter == null ||
        parameter!.currentPassword.isEmpty ||
        parameter!.newPassword.isEmpty) {
      return Error(
        InvalidInputFailure('Parâmetros de alteração de senha inválidos.'),
      );
    }

    return await _authUseCaseFacade.changePasswordUseCase(parameter!);
  }
}

final class DeleteAccountCommand
    extends ParameterizedCommand<void, Failure, DeleteAccountParams> {
  final IAuthUseCaseFacade _authUseCaseFacade;

  DeleteAccountCommand(this._authUseCaseFacade);

  @override
  Future<Result<void, Failure>> execute() async {
    if (parameter == null || parameter!.currentPassword.isEmpty) {
      return Error(
        InvalidInputFailure('Parâmetros de exclusão de conta inválidos.'),
      );
    }

    return await _authUseCaseFacade.deleteAccountUseCase(parameter!);
  }
}

final class SendPasswordResetEmailCommand
    extends ParameterizedCommand<void, Failure, SendPasswordResetEmailParams> {
  final IAuthUseCaseFacade _authUseCaseFacade;

  SendPasswordResetEmailCommand(this._authUseCaseFacade);

  @override
  Future<Result<void, Failure>> execute() async {
    if (parameter == null || parameter!.email.isEmpty) {
      return Error(
        InvalidInputFailure('Parâmetros de recuperação de senha inválidos.'),
      );
    }

    return await _authUseCaseFacade.sendPasswordResetEmailUseCase(parameter!);
  }
}

final class ReauthenticateCommand
    extends ParameterizedCommand<void, Failure, String> {
  final IAuthUseCaseFacade _authUseCaseFacade;
  ReauthenticateCommand(this._authUseCaseFacade);

  @override
  Future<Result<void, Failure>> execute() async {
    return await _authUseCaseFacade.reauthenticateUseCase(parameter!);
  }
}
