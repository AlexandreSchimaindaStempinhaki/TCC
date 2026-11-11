import '../../../../core/failure/failure.dart';
import '../../../../core/typedefs/types_defs.dart';
import '../../../../core/patterns/command.dart';
import '../../../../core/patterns/result.dart';
import '../../domain/facades/i_user_use_case_facade.dart';
import '../../../../domain/models/user_entity.dart';
import '../../domain/usecases/i_user_usecases.dart';

final class GetUserCommand extends Command<UserModel?, Failure> {
  final IUserUseCaseFacade _userUseCaseFacade;

  GetUserCommand(this._userUseCaseFacade);

  @override
  Future<Result<UserModel?, Failure>> execute() async {
    return await _userUseCaseFacade.getUser();
  }
}

final class SaveUserDataCommand
    extends ParameterizedCommand<void, Failure, SaveUserDataParams> {
  final IUserUseCaseFacade _userUseCaseFacade;

  SaveUserDataCommand(this._userUseCaseFacade);

  @override
  Future<VoidResult> execute() async {
    if (parameter == null) {
      return Error(
        InvalidInputFailure('Parâmetros de salvamento de usuário inválidos.'),
      );
    }
    return await _userUseCaseFacade.saveUserData(parameter!);
  }
}

final class UpdateProfilePictureCommand
    extends ParameterizedCommand<String, Failure, UpdateProfilePictureParams> {
  final IUserUseCaseFacade _userUseCaseFacade;

  UpdateProfilePictureCommand(this._userUseCaseFacade);

  @override
  Future<Result<String, Failure>> execute() async {
    if (parameter == null || !parameter!.imageFile.existsSync()) {
      return Error(
        InvalidInputFailure('Arquivo de imagem inválido ou não fornecido.'),
      );
    }
    return await _userUseCaseFacade.updateProfilePicture(parameter!);
  }
}

final class DeleteUserAccountCommand
    extends ParameterizedCommand<void, Failure, NoParams> {
  final IUserUseCaseFacade _userUseCaseFacade;

  DeleteUserAccountCommand(this._userUseCaseFacade);

  @override
  Future<VoidResult> execute() async {
    if (parameter == null) {
      return Error(
        InvalidInputFailure('Parâmetros inválidos para exclusão da conta.'),
      );
    }
    return await _userUseCaseFacade.deleteUserAccount(parameter!);
  }
}
