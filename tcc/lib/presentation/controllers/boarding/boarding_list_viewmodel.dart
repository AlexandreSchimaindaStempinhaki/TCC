import '../../../domain/facades/boarding/i_boarding_facade.dart';
import '../../commands/boarding_commands.dart';
import 'boarding_list_state_viewmodel.dart';
import 'boarding_list_viewmodel_commands.dart';

class BoardingListViewModel {
  final IBoardingFacade _facade;

  late final BoardingListState state;
  late final BoardingListViewModelCommands commands;

  late final FetchBoardingsByRouteAndDateCommand
      fetchBoardingsByRouteAndDateCommand;
  late final FetchBoardingsByTripCommand fetchBoardingsByTripCommand;
  late final WatchRouteBoardingsByDateCommand watchRouteBoardingsByDateCommand;
  late final MarkBoardingOutcomeCommand markBoardingOutcomeCommand;

  BoardingListViewModel(this._facade) {
    state = BoardingListState();
    fetchBoardingsByRouteAndDateCommand =
        FetchBoardingsByRouteAndDateCommand(_facade);
    fetchBoardingsByTripCommand = FetchBoardingsByTripCommand(_facade);
    watchRouteBoardingsByDateCommand =
        WatchRouteBoardingsByDateCommand(_facade);
    markBoardingOutcomeCommand = MarkBoardingOutcomeCommand(_facade);
    commands = BoardingListViewModelCommands(this);
  }
}