import 'dart:io';
import '../../../../core/typedefs/types_defs.dart';
import '../../../../core/patterns/i_usecases.dart';
import '../../../core/failure/failure.dart';
import '../../../core/patterns/result.dart';
import '../../domain/models/user_entity.dart';

class SaveUserDataParams {
  final UserModel user;
  const SaveUserDataParams({required this.user});
}

class UpdateProfilePictureParams {
  final File imageFile;
  const UpdateProfilePictureParams({required this.imageFile});
}

abstract interface class IGetUserUseCase {
  Future<Result<UserModel?, Failure>> call();
}

abstract interface class ISaveUserDataUseCase
    implements IUseCase<VoidResult, SaveUserDataParams> {}

abstract interface class IUpdateProfilePictureUseCase
    implements IUseCase<Result<String, Failure>, UpdateProfilePictureParams> {}

abstract interface class IDeleteUserAccountUseCase
    implements IUseCase<VoidResult, NoParams> {}
