import 'package:auto_injector/auto_injector.dart';

import '../../data/repositories/company_repository.dart';
import '../../data/services/firebase/company_firebase_service_impl.dart';
import '../../data/services/firebase/i_company_firebase_service.dart';
import '../../domain/facades/i_user_use_case_facade.dart';
import '../../data/repositories/i_user_repositoy.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../data/services/firebase/i_user_firebase_service.dart';
import '../../data/services/firebase/user_firebase_service_impl.dart';
import '../../domain/facades/user_use_case_facade.dart';
import '../../domain/usecases/company_use_cases_impl.dart';
import '../../domain/usecases/i_company_use_cases.dart';
import '../../domain/usecases/i_user_usecases.dart';
import '../../domain/usecases/user_use_cases_impl.dart';
import '../../presentation/controllers/company/company_viewmodel.dart';
import '../../presentation/controllers/user/user_viewmodel.dart';
import '../../data/repositories/i_company_repository.dart';
import '../../domain/facades/i_company_use_case_facade.dart';
import '../../domain/facades/company_use_case_facade_impl.dart';
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
import '../../presentation/commands/authentication/auth_commands.dart';
import '../../presentation/controllers/authentication/auth_session_viewmodel.dart';

final injector = AutoInjector();

void setupDependencyInjection() {
  injector.addSingleton<ThemeController>(() => ThemeController());

  // Módulo de Usuário
  injector.addSingleton<IUserRemoteService>(UserRemoteServiceImpl.new);
  injector.addSingleton<IUserRepository>(UserRepositoryImpl.new);
  injector.addSingleton<IGetUserUseCase>(GetUserUseCase.new);
  injector.addSingleton<ISaveUserDataUseCase>(SaveUserDataUseCase.new);
  injector.addSingleton<IUpdateProfilePictureUseCase>(UpdateProfilePictureUseCase.new);
  injector.addSingleton<IDeleteUserAccountUseCase>(DeleteUserAccountUseCase.new);
  injector.addSingleton<IUserUseCaseFacade>(UserUseCaseFacadeImpl.new);

  // Módulo de Empresa
  injector.addSingleton<CompanyService>(CompanyServiceImpl.new);
  injector.addSingleton<ICompanyRepository>(CompanyRepositoryImpl.new);
  injector.addSingleton<ICreateCompanyUseCase>(CreateCompanyUseCase.new);
  injector.addSingleton<IFetchCompaniesByOwnerUseCase>(FetchCompaniesByOwnerUseCase.new);
  injector.addSingleton<IFetchCompaniesByMemberUseCase>(FetchCompaniesByMemberUseCase.new);
  injector.addSingleton<IUpdateCompanyUseCase>(UpdateCompanyUseCase.new);
  injector.addSingleton<IDeleteCompanyUseCase>(DeleteCompanyUseCase.new);
  injector.addSingleton<ICompanyUseCaseFacade>(CompanyUseCaseFacadeImpl.new);

  // Módulo de Autenticação
  injector.addSingleton<ILocalSessionStore>(SharedPrefLocalSessionService.new);
  injector.addSingleton<AuthLocalSessionManager>(AuthLocalSessionManager.new);
  injector.addSingleton<IAuthService>(FirebaseAuthService.new);
  injector.addSingleton<IAuthRepository>(AuthRepositoryImpl.new);
  injector.addSingleton<ISendEmailVerificationLinkUseCase>(SendEmailVerificationLinkUseCase.new);
  injector.addSingleton<ISignUpWithVerifiedEmailUseCase>(SignUpWithVerifiedEmailUseCase.new);
  injector.addSingleton<ICheckEmailVerifiedStatusUseCase>(CheckEmailVerifiedStatusUseCase.new);
  injector.addSingleton<IDeleteExpiredAccountUseCase>(DeleteExpiredAccountUseCase.new);
  injector.addSingleton<ISignInUseCase>(SignInUseCase.new);
  injector.addSingleton<ISignInWithGoogleUseCase>(SignInWithGoogleUseCase.new);
  injector.addSingleton<ISignOutUseCase>(SignOutUseCase.new);
  injector.addSingleton<IChangePasswordUseCase>(ChangePasswordUseCase.new);
  injector.addSingleton<IDeleteAccountUseCase>(DeleteAccountUseCase.new);
  injector.addSingleton<ISendPasswordResetEmailUseCase>(SendPasswordResetEmailUseCase.new);
  injector.addSingleton<IReauthenticateUseCase>(ReauthenticateUseCase.new);
  injector.addSingleton<ReauthenticateCommand>(ReauthenticateCommand.new);
  injector.addSingleton<IAuthUseCaseFacade>(AuthUseCaseFacadeImpl.new);

  // Viewmodels
  injector.addSingleton<AuthViewModel>(AuthViewModel.new);
  injector.addSingleton<UserViewModel>(UserViewModel.new);
  injector.addSingleton<CompanyViewModel>(CompanyViewModel.new);

  injector.commit();
}