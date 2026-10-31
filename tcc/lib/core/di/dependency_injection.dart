import 'package:get_it/get_it.dart';
import '../theme/theme_controller.dart';

final injector = GetIt.instance;

void setupDependencyInjection() {
  injector.registerLazySingleton<ThemeController>(() => ThemeController());


}