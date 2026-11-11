import '../../../../core/typedefs/types_defs.dart';
import '../../../core/failure/failure.dart';
import '../../../core/patterns/result.dart';
import '../../domain/models/user_entity.dart';
import '../usecases/i_user_usecases.dart';
import 'i_user_use_case_facade.dart';

class UserUseCaseFacadeImpl implements IUserUseCaseFacade {
  final IGetUserUseCase _getUserUseCase;
  final ISaveUserDataUseCase _saveUserDataUseCase;
  final IUpdateProfilePictureUseCase _updateProfilePictureUseCase;
  final IDeleteUserAccountUseCase _deleteUserAccountUseCase;

  UserUseCaseFacadeImpl({
    required IGetUserUseCase getUserUseCase,
    required ISaveUserDataUseCase saveUserDataUseCase,
    required IUpdateProfilePictureUseCase updateProfilePictureUseCase,
    required IDeleteUserAccountUseCase deleteUserAccountUseCase,
  }) : _getUserUseCase = getUserUseCase,
       _saveUserDataUseCase = saveUserDataUseCase,
       _updateProfilePictureUseCase = updateProfilePictureUseCase,
       _deleteUserAccountUseCase = deleteUserAccountUseCase;

  @override
  Future<Result<UserModel?, Failure>> getUser() {
    return _getUserUseCase();
  }

  @override
  Future<VoidResult> saveUserData(SaveUserDataParams params) {
    return _saveUserDataUseCase(params);
  }

  @override
  Future<Result<String, Failure>> updateProfilePicture(
    UpdateProfilePictureParams params,
  ) {
    return _updateProfilePictureUseCase(params);
  }

  @override
  Future<VoidResult> deleteUserAccount(NoParams params) {
    return _deleteUserAccountUseCase(params);
  }
}
