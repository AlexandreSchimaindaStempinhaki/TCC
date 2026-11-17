import '../../../domain/facades/trip/i_trip_facade.dart';
import '../../commands/trip_commands.dart';
import 'trip_list_state_viewmodel.dart';
import 'trip_list_viewmodel_commands.dart';

class TripListViewModel {
  final ITripFacade _facade;

  late final TripListState state;
  late final TripListViewModelCommands commands;

  late final FetchTripsByRouteCommand fetchTripsByRouteCommand;
  late final FetchTripsByDriverCommand fetchTripsByDriverCommand;
  late final FetchTripsByCompanyCommand fetchTripsByCompanyCommand;
  late final WatchActiveTripsByRouteCommand watchActiveTripsByRouteCommand;

  TripListViewModel(this._facade) {
    state = TripListState();
    fetchTripsByRouteCommand = FetchTripsByRouteCommand(_facade);
    fetchTripsByDriverCommand = FetchTripsByDriverCommand(_facade);
    fetchTripsByCompanyCommand = FetchTripsByCompanyCommand(_facade);
    watchActiveTripsByRouteCommand = WatchActiveTripsByRouteCommand(_facade);
    commands = TripListViewModelCommands(this);
  }
}