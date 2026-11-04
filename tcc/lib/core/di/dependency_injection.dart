import 'package:auto_injector/auto_injector.dart';

import '../theme/theme_controller.dart';
import '../../data/repositories/authentication/auth_repository_impl.dart';
import '../../data/repositories/authentication/i_auth_repository.dart';
import '../../data/services/authentication/local/auth_local_session_manager.dart';
import '../../data/services/authentication/local/i_local_session_store.dart';
import '../../data/services/authentication/local/shared_pref_local_session_service.dart';
import '../../data/services/authentication/remote/firebase_auth_service.dart';
import '../../data/services/authentication/remote/i_auth_service.dart';
import '../../domain/facades/authentication/auth_use_case_facade_impl.dart';
import '../../domain/facades/authentication/i_auth_use_case_facade.dart';
import '../../domain/usecases/authentication/i_auth_usecases.dart';
import '../../domain/usecases/authentication/auth_use_cases.impl.dart';
import '../../presentation/controllers/authentication/auth_session_viewmodel.dart';

final injector = AutoInjector();

void setupDependencyInjection() {
  injector.addSingleton<ThemeController>(() => ThemeController());

  // modulo de autenticação
  injector.addSingleton<ILocalSessionStore>(SharedPrefLocalSessionService.new);
  injector.addSingleton<AuthLocalSessionManager>(AuthLocalSessionManager.new);
  injector.addSingleton<IAuthService>(FirebaseAuthService.new);
  injector.addSingleton<IAuthRepository>(AuthRepositoryImpl.new);

  // use cases
  injector.addSingleton<ISignUpUseCase>(SignUpUseCase.new);
  injector.addSingleton<ISignInUseCase>(SignInUseCase.new);
  injector.addSingleton<ISignInWithGoogleUseCase>(SignInWithGoogleUseCase.new);
  injector.addSingleton<ISignOutUseCase>(SignOutUseCase.new);
  injector.addSingleton<IAuthUseCaseFacade>(AuthUseCaseFacadeImpl.new);

  // viewmodels (gerais)
  injector.addSingleton<AuthViewModel>(AuthViewModel.new);

  injector.commit();
}
