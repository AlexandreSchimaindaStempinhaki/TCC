import 'dart:io';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/facades/route/i_route_facade.dart';
import '../../../domain/models/route_entity.dart';

class FetchAllRoutesCommand {
  final IRouteUseCaseFacade _facade;
  final isExecuting = signal(false);

  FetchAllRoutesCommand(this._facade);

  Future<List<RouteModel>> execute() async {
    isExecuting.value = true;
    try {
      return await _facade.fetchAllRoutes();
    } finally {
      isExecuting.value = false;
    }
  }
}

class FetchRoutesByCompanyCommand {
  final IRouteUseCaseFacade _facade;
  final isExecuting = signal(false);

  FetchRoutesByCompanyCommand(this._facade);

  Future<List<RouteModel>> execute(String companyCnpj) async {
    isExecuting.value = true;
    try {
      return await _facade.fetchRoutesByCompany(companyCnpj);
    } finally {
      isExecuting.value = false;
    }
  }
}

class GetRouteByIdCommand {
  final IRouteUseCaseFacade _facade;
  final isExecuting = signal(false);

  GetRouteByIdCommand(this._facade);

  Future<RouteModel?> execute(int routeId) async {
    isExecuting.value = true;
    try {
      return await _facade.getRouteById(routeId);
    } finally {
      isExecuting.value = false;
    }
  }
}

class CreateRouteCommand {
  final IRouteUseCaseFacade _facade;
  final isExecuting = signal(false);

  CreateRouteCommand(this._facade);

  Future<RouteModel> execute(RouteModel route, {File? imageFile}) async {
    isExecuting.value = true;
    try {
      return await _facade.createRoute(route, imageFile: imageFile);
    } finally {
      isExecuting.value = false;
    }
  }
}

class UpdateRouteCommand {
  final IRouteUseCaseFacade _facade;
  final isExecuting = signal(false);

  UpdateRouteCommand(this._facade);

  Future<RouteModel> execute(RouteModel route, {File? imageFile}) async {
    isExecuting.value = true;
    try {
      return await _facade.updateRoute(route, imageFile: imageFile);
    } finally {
      isExecuting.value = false;
    }
  }
}

class UpdateRouteImageCommand {
  final IRouteUseCaseFacade _facade;
  final isExecuting = signal(false);

  UpdateRouteImageCommand(this._facade);

  Future<String> execute(int routeId, File imageFile) async {
    isExecuting.value = true;
    try {
      return await _facade.updateRouteImage(routeId, imageFile);
    } finally {
      isExecuting.value = false;
    }
  }
}

class DeleteRouteCommand {
  final IRouteUseCaseFacade _facade;
  final isExecuting = signal(false);

  DeleteRouteCommand(this._facade);

  Future<void> execute(int routeId) async {
    isExecuting.value = true;
    try {
      await _facade.deleteRoute(routeId);
    } finally {
      isExecuting.value = false;
    }
  }
}