import 'package:signals_flutter/signals_flutter.dart';
import '../../domain/facades/i_user_use_case_facade.dart';
import '../commands/user_commands.dart';
import 'user_commands_viewmodel.dart';
import 'user_state_viewmodel.dart';

class UserViewModel {
  final IUserUseCaseFacade _facade;

  late final UserState _state;
  late final UserCommands _commands;
  late final Signal<bool> _loading;

  UserState get state => _state;
  UserCommands get commands => _commands;
  ReadonlySignal<bool> get loading => _loading.readonly();

  UserViewModel(this._facade) {
    _state = UserState();

    _commands = UserCommands(
      state: _state,
      getUserCommand: GetUserCommand(_facade),
      saveUserDataCommand: SaveUserDataCommand(_facade),
      updateProfilePictureCommand: UpdateProfilePictureCommand(_facade),
      deleteUserAccountCommand: DeleteUserAccountCommand(_facade),
    );

    _loading = signal(false);
  }

  // --- Comandos expostos diretamente para conveniência na UI ---
  GetUserCommand get getUserCommand => _commands.getUserCommand;
  SaveUserDataCommand get saveUserDataCommand => _commands.saveUserDataCommand;
  UpdateProfilePictureCommand get updateProfilePictureCommand => _commands.updateProfilePictureCommand;
  DeleteUserAccountCommand get deleteUserAccountCommand => _commands.deleteUserAccountCommand;
  
}