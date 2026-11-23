import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'core/di/dependency_injection.dart';
import 'core/network/network_status_service.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'data/services/notification/notification_service_impl.dart';
import 'firebase_options.dart';
import 'presentation/controllers/notifications/notification_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (_) {}

  setupDependencyInjection();

  final themeController = injector.get<ThemeController>();
  try {
    await themeController.loadTheme();
  } catch (_) {}

  // Checa internet sem travar o boot caso esteja offline
  await NetworkStatusService.checkConnection(force: true);

  if (NetworkStatusService.isConnected.value) {
    try {
      await injector
          .get<NotificationViewModel>()
          .commands
          .initialize()
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  runApp(
    Watch(
      (_) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Injustice App',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode.value,
        routerConfig: AppRouter.router,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pt', 'BR')],
      ),
    ),
  );
}