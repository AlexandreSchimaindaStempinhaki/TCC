import '../../../domain/facades/boarding/i_boarding_facade.dart';
import '../../commands/boarding_commands.dart';
import 'boarding_state_viewmodel.dart';
import 'boarding_viewmodel_commands.dart';

class BoardingViewModel {
  final IBoardingFacade _facade;

  late final BoardingState state;
  late final BoardingViewModelCommands commands;

  late final GetOrCreateDailyBoardingCommand getOrCreateDailyBoardingCommand;
  late final FetchUserBoardingHistoryCommand fetchUserBoardingHistoryCommand;
  late final WatchPassengerBoardingCommand watchPassengerBoardingCommand;
  late final SaveBoardingCommand saveBoardingCommand;
  late final UpdateBoardingAttendanceCommand updateBoardingAttendanceCommand;
  late final SetReadyForBoardingCommand setReadyForBoardingCommand;
  late final MarkBoardingOutcomeCommand markBoardingOutcomeCommand;
  late final RegisterBoardingNotificationCommand
      registerBoardingNotificationCommand;
  late final DeleteBoardingCommand deleteBoardingCommand;

  BoardingViewModel(this._facade) {
    state = BoardingState();
    getOrCreateDailyBoardingCommand = GetOrCreateDailyBoardingCommand(_facade);
    fetchUserBoardingHistoryCommand = FetchUserBoardingHistoryCommand(_facade);
    watchPassengerBoardingCommand = WatchPassengerBoardingCommand(_facade);
    saveBoardingCommand = SaveBoardingCommand(_facade);
    updateBoardingAttendanceCommand = UpdateBoardingAttendanceCommand(_facade);
    setReadyForBoardingCommand = SetReadyForBoardingCommand(_facade);
    markBoardingOutcomeCommand = MarkBoardingOutcomeCommand(_facade);
    registerBoardingNotificationCommand =
        RegisterBoardingNotificationCommand(_facade);
    deleteBoardingCommand = DeleteBoardingCommand(_facade);
    commands = BoardingViewModelCommands(this);
  }
}