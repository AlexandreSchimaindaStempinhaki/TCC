import 'dart:io';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../core/failure/failure.dart';
import '../../../core/patterns/command.dart';
import '../../../domain/models/user_entity.dart';
import '../../domain/usecases/i_user_usecases.dart';
import '../commands/user_commands.dart';
import 'user_state_viewmodel.dart';

class UserCommands {
  final UserState state;
  final GetUserCommand _getUserCommand;
  final SaveUserDataCommand _saveUserDataCommand;
  final UpdateProfilePictureCommand _updateProfilePictureCommand;
  final DeleteUserAccountCommand _deleteUserAccountCommand;

  UserCommands({
    required this.state,
    required GetUserCommand getUserCommand,
    required SaveUserDataCommand saveUserDataCommand,
    required UpdateProfilePictureCommand updateProfilePictureCommand,
    required DeleteUserAccountCommand deleteUserAccountCommand,
  }) : _getUserCommand = getUserCommand,
       _saveUserDataCommand = saveUserDataCommand,
       _updateProfilePictureCommand = updateProfilePictureCommand,
       _deleteUserAccountCommand = deleteUserAccountCommand {
    _observeGetUser();
    _observeSaveUserData();
    _observeUpdateProfilePicture();
    _observeDeleteUserAccount();
  }

  // ========================================================
  //   GETTERS PARA WIDGETS USAREM DIRETAMENTE OS COMANDOS
  // ========================================================
  GetUserCommand get getUserCommand => _getUserCommand;
  SaveUserDataCommand get saveUserDataCommand => _saveUserDataCommand;
  UpdateProfilePictureCommand get updateProfilePictureCommand =>
      _updateProfilePictureCommand;
  DeleteUserAccountCommand get deleteUserAccountCommand =>
      _deleteUserAccountCommand;

  // ========================================================
  //   MÉTODOS PÚBLICOS (CHAMADOS PELOS WIDGETS)
  // ========================================================
  Future<void> fetchUser() async {
    if (_getUserCommand.isExecuting.value) {
      await _getUserCommand.call();
      return;
    }

    state.clearMessage();

    await _getUserCommand.call();
  }

  Future<void> saveUserData(UserModel user) async {
    state.clearMessage();
    await _saveUserDataCommand.executeWith(SaveUserDataParams(user: user));
  }

  Future<void> updateProfilePicture(File imageFile) async {
    state.clearMessage();
    await _updateProfilePictureCommand.executeWith(
      UpdateProfilePictureParams(imageFile: imageFile),
    );
  }

  Future<void> deleteUserAccount() async {
    state.clearMessage();
    await _deleteUserAccountCommand.execute();
  }

  // ========================================================
  //   MÉTODO GENÉRICO DE OBSERVAÇÃO DE COMANDOS
  // ========================================================
  void _observeCommand<T>(
    Command<T, Failure> command, {
    required void Function(T data) onSuccess,
    void Function(Failure err)? onFailure,
  }) {
    effect(() {
      if (command.isExecuting.value) return;

      final result = command.result.value;
      if (result == null) return;

      result.fold(
        onSuccess: (data) {
          state.clearMessage();
          onSuccess(data);
        },
        onFailure: (err) {
          state.setMessage(err.msg);
          if (onFailure != null) onFailure(err);
        },
      );
    });
  }

  // ========================================================
  //   OBSERVERS ESPECÍFICOS
  // ========================================================
  void _observeGetUser() {
    _observeCommand<UserModel?>(
      _getUserCommand,
      onSuccess: (user) {
        state.setUser(user);
      },
    );
  }

  void _observeSaveUserData() {
    _observeCommand<void>(
      _saveUserDataCommand,
      onSuccess: (_) {
        state.clearMessage();
      },
    );
  }

  void _observeUpdateProfilePicture() {
    _observeCommand<String>(
      _updateProfilePictureCommand,
      onSuccess: (fotoUrl) {
        // Atualiza localmente o model se ele já existir no state, adicionando a nova foto
        final currentUser = state.user.value;
        if (currentUser != null) {
          state.setUser(currentUser.copyWith(photoUrl: fotoUrl));
        }
      },
    );
  }

  void _observeDeleteUserAccount() {
    _observeCommand<void>(
      _deleteUserAccountCommand,
      onSuccess: (_) {
        state.clearUser();
      },
    );
  }
}
