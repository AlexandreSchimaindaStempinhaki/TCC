import '../../../../core/typedefs/types_defs.dart';
import '../../../core/failure/failure.dart';
import '../../../core/patterns/result.dart';
import '../../domain/models/user_entity.dart';
import '../usecases/i_user_usecases.dart';

abstract interface class IUserUseCaseFacade {
  Future<Result<UserModel?, Failure>> getUser();
  Future<VoidResult> saveUserData(SaveUserDataParams params);
  Future<Result<String, Failure>> updateProfilePicture(
    UpdateProfilePictureParams params,
  );
  Future<VoidResult> deleteUserAccount(NoParams params);
}
