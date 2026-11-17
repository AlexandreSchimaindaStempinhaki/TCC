import '../../../domain/facades/trip/i_trip_facade.dart';
import '../../commands/trip_commands.dart';
import 'trip_state_viewmodel.dart';
import 'trip_viewmodel_commands.dart';

class TripViewModel {
  final ITripFacade _facade;

  late final TripState state;
  late final TripViewModelCommands commands;

  late final GetTripByIdCommand getTripByIdCommand;
  late final WatchTripByIdCommand watchTripByIdCommand;
  late final CreateTripCommand createTripCommand;
  late final GenerateScaledTripsCommand generateScaledTripsCommand;
  late final UpdateTripCommand updateTripCommand;
  late final StartTripCommand startTripCommand;
  late final FinishTripCommand finishTripCommand;
  late final CancelTripCommand cancelTripCommand;
  late final UpdateDriverLocationCommand updateDriverLocationCommand;
  late final MarkStopCompletedCommand markStopCompletedCommand;
  late final SetPassengerReadyAtStopCommand setPassengerReadyAtStopCommand;
  late final DeleteTripCommand deleteTripCommand;

  TripViewModel(this._facade) {
    state = TripState();
    getTripByIdCommand = GetTripByIdCommand(_facade);
    watchTripByIdCommand = WatchTripByIdCommand(_facade);
    createTripCommand = CreateTripCommand(_facade);
    generateScaledTripsCommand = GenerateScaledTripsCommand(_facade);
    updateTripCommand = UpdateTripCommand(_facade);
    startTripCommand = StartTripCommand(_facade);
    finishTripCommand = FinishTripCommand(_facade);
    cancelTripCommand = CancelTripCommand(_facade);
    updateDriverLocationCommand = UpdateDriverLocationCommand(_facade);
    markStopCompletedCommand = MarkStopCompletedCommand(_facade);
    setPassengerReadyAtStopCommand = SetPassengerReadyAtStopCommand(_facade);
    deleteTripCommand = DeleteTripCommand(_facade);
    commands = TripViewModelCommands(this);
  }
}