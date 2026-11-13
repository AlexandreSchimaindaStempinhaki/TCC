import 'dart:io';
import '../../../domain/models/user_entity.dart';

abstract interface class IUserRemoteService {
  Future<void> saveUserData(UserModel user);
  Future<UserModel?> getUserData();
  Future<String> uploadProfileImage(File imageFile);
  Future<void> deleteUserAccountData();
}
