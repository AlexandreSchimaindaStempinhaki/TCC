import 'dart:io';
import '../../../../core/typedefs/types_defs.dart';
import '../../../core/failure/failure.dart';
import '../../../core/patterns/result.dart';
import '../../domain/models/user_entity.dart';
import '../services/firebase/i_user_firebase_service.dart';
import 'i_user_repositoy.dart';

final class UserRepositoryImpl implements IUserRepository {
  final IUserRemoteService _remoteService;

  UserRepositoryImpl({required IUserRemoteService remoteService})
    : _remoteService = remoteService;

  @override
  Future<VoidResult> saveUser(UserModel user) async {
    try {
      await _remoteService.saveUserData(user);
      return const Success(null);
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }

  @override
  Future<Result<UserModel?, Failure>> getUser() async {
    try {
      final user = await _remoteService.getUserData();
      return Success(user);
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }

  @override
  Future<Result<String, Failure>> updateProfilePicture(File imageFile) async {
    try {
      final fotoUrl = await _remoteService.uploadProfileImage(imageFile);

      return Success(fotoUrl);
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }

  @override
  Future<VoidResult> deleteAccount() async {
    try {
      await _remoteService.deleteUserAccountData();
      return const Success(null);
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }
}
