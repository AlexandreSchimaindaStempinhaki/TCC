import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/models/route_entity.dart';
import '../../../domain/models/user_entity.dart';

class RouteState {
  final route = signal<RouteModel?>(null);

  final passengers = signal<List<UserModel>>([]);
  final pendingPassengers = signal<List<UserModel>>([]);
  final confirmedPassengers = signal<List<UserModel>>([]);
  final driver = signal<UserModel?>(null);

  final message = signal<String?>(null);

  bool get hasRoute => route.value != null;
  bool get isTripActive => route.value?.isTripActive ?? false;

  void setRoute(RouteModel? routeModel) {
    route.value = routeModel;
    message.value = null;
  }

  void setPassengers(List<UserModel> list) {
    passengers.value = List<UserModel>.from(list);
  }

  void setPendingPassengers(List<UserModel> list) {
    pendingPassengers.value = List<UserModel>.from(list);
  }

  void setConfirmedPassengers(List<UserModel> list) {
    confirmedPassengers.value = List<UserModel>.from(list);
  }

  void setDriver(UserModel? driverModel) {
    driver.value = driverModel;
  }

  void clearRoute() {
    route.value = null;
    passengers.value = [];
    pendingPassengers.value = [];
    confirmedPassengers.value = [];
    driver.value = null;
    message.value = null;
  }

  void clearMessage() => message.value = null;

  void setMessage(String msg) => message.value = msg;
}