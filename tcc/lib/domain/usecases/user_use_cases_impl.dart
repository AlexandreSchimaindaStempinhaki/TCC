import '../../../../core/typedefs/types_defs.dart';
import '../../../core/failure/failure.dart' show Failure, DefaultFailure;
import '../../../core/patterns/result.dart';
import '../../domain/models/user_entity.dart';
import '../../data/repositories/i_user_repositoy.dart';
import 'i_user_usecases.dart';

final class GetUserUseCase implements IGetUserUseCase {
  final IUserRepository _userRepository;

  GetUserUseCase({required IUserRepository userRepository})
      : _userRepository = userRepository;

  @override
  Future<Result<UserModel?, Failure>> call() async {
    return _userRepository.getUser();
  }
}

final class SaveUserDataUseCase implements ISaveUserDataUseCase {
  final IUserRepository _userRepository;

  SaveUserDataUseCase({required IUserRepository userRepository})
      : _userRepository = userRepository;

  @override
  Future<VoidResult> call(SaveUserDataParams params) async {
    return _userRepository.saveUser(params.user);
  }
}

final class UpdateProfilePictureUseCase implements IUpdateProfilePictureUseCase {
  final IUserRepository _userRepository;

  UpdateProfilePictureUseCase({required IUserRepository userRepository})
      : _userRepository = userRepository;

  @override
  Future<Result<String, Failure>> call(UpdateProfilePictureParams params) async {
    if (!params.imageFile.existsSync()) {
      return Error(
        DefaultFailure('O arquivo de imagem selecionado não foi encontrado.'),
      );
    }
    return _userRepository.updateProfilePicture(params.imageFile);
  }
}

final class DeleteUserAccountUseCase implements IDeleteUserAccountUseCase {
  final IUserRepository _userRepository;

  DeleteUserAccountUseCase({required IUserRepository userRepository})
      : _userRepository = userRepository;

  @override
  Future<VoidResult> call(NoParams params) async {
    return _userRepository.deleteAccount();
  }
}