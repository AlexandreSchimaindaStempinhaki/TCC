import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/models/user_entity.dart';

class UserState {
  final user = signal<UserModel?>(null);

  final message = signal<String?>(null);

  bool get hasUser => user.value != null;

  /// Define os dados do usuário
  void setUser(UserModel? userModel) {
    user.value = userModel;
    message.value = null;
  }

  void clearUser() {
    user.value = null;
    message.value = null;
  }

  void clearMessage() => message.value = null;

  void setMessage(String msg) => message.value = msg;
}