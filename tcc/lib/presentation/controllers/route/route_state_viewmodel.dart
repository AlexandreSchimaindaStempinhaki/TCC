import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/models/route_entity.dart';

class RouteState {
  final route = signal<RouteModel?>(null);

  final message = signal<String?>(null);

  bool get hasRoute => route.value != null;

  void setRoute(RouteModel? routeModel) {
    route.value = routeModel;
    message.value = null;
  }

  void clearRoute() {
    route.value = null;
    message.value = null;
  }

  void clearMessage() => message.value = null;

  void setMessage(String msg) => message.value = msg;
}