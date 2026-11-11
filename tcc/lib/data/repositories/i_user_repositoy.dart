import 'dart:io';
import '../../../../core/typedefs/types_defs.dart';
import '../../../core/failure/failure.dart';
import '../../../core/patterns/result.dart';
import '../../domain/models/user_entity.dart';

abstract interface class IUserRepository {
  Future<VoidResult> saveUser(UserModel user);
  
  Future<Result<UserModel?, Failure>> getUser();
  
  Future<Result<String, Failure>> updateProfilePicture(File imageFile);
  
  Future<VoidResult> deleteAccount();
}