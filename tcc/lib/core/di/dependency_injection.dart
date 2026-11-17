import 'package:auto_injector/auto_injector.dart';
import 'package:tcc/data/repositories/trip/i_trip_repository.dart';
import 'package:tcc/domain/usecases/trip/i_trip_usecases.dart';
import 'package:tcc/domain/usecases/trip/trip_usecases_impl.dart';

import '../theme/theme_controller.dart';
import '../../data/repositories/boarding/boarding_repository_impl.dart';
import '../../data/repositories/boarding/i_boarding_repository.dart';
import '../../data/repositories/company_member/i_company_member_repository.dart';
import '../../data/repositories/route/i_route_repository.dart';
import '../../data/repositories/trip/trip_repository_impl.dart';
import '../../data/repositories/vehicle/i_vehicle_repository.dart';
import '../../data/services/boarding/boarding_service_impl.dart';
import '../../data/services/boarding/i_boarding_service.dart';
import '../../data/services/trip/i_trip_service.dart';
import '../../data/services/trip/trip_service_impl.dart';
import '../../domain/facades/boarding/boarding_facade_impl.dart';
import '../../domain/facades/boarding/i_boarding_facade.dart';
import '../../domain/facades/trip/i_trip_facade.dart';
import '../../domain/facades/trip/trip_facade_impl.dart';
import '../../domain/facades/user/i_user_use_case_facade.dart';
import '../../data/repositories/user/i_user_repositoy.dart';
import '../../data/repositories/user/user_repository_impl.dart';
import '../../data/services/user/i_user_firebase_service.dart';
import '../../data/services/user/user_firebase_service_impl.dart';
import '../../domain/facades/user/user_use_case_facade.dart';
import '../../domain/usecases/boarding/boarding_usecases_impl.dart';
import '../../domain/usecases/boarding/i_boarding_usecases.dart';
import '../../domain/usecases/user/i_user_usecases.dart';
import '../../domain/usecases/user/user_use_cases_impl.dart';
import '../../presentation/controllers/boarding/boarding_list_viewmodel.dart';
import '../../presentation/controllers/boarding/boarding_viewmodel.dart';
import '../../presentation/controllers/trip/trip_list_viewmodel.dart';
import '../../presentation/controllers/trip/trip_viewmodel.dart';
import '../../presentation/controllers/user/user_viewmodel.dart';
import '../../data/services/company/i_company_firebase_service.dart';
import '../../data/services/company/company_firebase_service_impl.dart';
import '../../data/repositories/company/i_company_repository.dart';
import '../../data/repositories/company/company_repository.dart';
import '../../domain/usecases/company/i_company_use_cases.dart';
import '../../domain/usecases/company/company_use_cases_impl.dart';
import '../../domain/facades/company/i_company_use_case_facade.dart';
import '../../domain/facades/company/company_use_case_facade_impl.dart';
import '../../presentation/controllers/company/company_viewmodel.dart';
import '../../presentation/controllers/company/company_list_viewmodel.dart';
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
import '../../data/services/company_member/i_company_member_service.dart';
import '../../data/services/company_member/company_member_service_impl.dart';
import '../../data/repositories/company_member/company_member_repository_impl.dart';
import '../../domain/usecases/company_member/i_company_member_usecases.dart';
import '../../domain/usecases/company_member/company_member_usecases_impl.dart';
import '../../domain/facades/company_member/i_company_member_facade.dart';
import '../../domain/facades/company_member/company_member_facade_impl.dart';
import '../../presentation/controllers/company_member/company_member_viewmodel.dart';
import '../../data/services/route/i_route_service.dart';
import '../../data/services/route/route_service_impl.dart';
import '../../data/repositories/route/route_repository_impl.dart';
import '../../domain/usecases/route/i_route_usecases.dart';
import '../../domain/usecases/route/route_usecases_impl.dart';
import '../../domain/facades/route/i_route_facade.dart';
import '../../domain/facades/route/route_facade_impl.dart';
import '../../presentation/controllers/route/route_viewmodel.dart';
import '../../presentation/controllers/route/route_list_viewmodel.dart';
import '../../data/services/vehicle/i_vehicle_service.dart';
import '../../data/services/vehicle/vehicle_service_impl.dart';
import '../../data/repositories/vehicle/vehicle_repository_impl.dart';
import '../../domain/usecases/vehicle/i_vehicle_usecases.dart';
import '../../domain/usecases/vehicle/vehicle_usecases_impl.dart';
import '../../domain/facades/vehicle/i_vehicle_facade.dart';
import '../../domain/facades/vehicle/vehicle_facade_impl.dart';
import '../../presentation/controllers/vehicle/vehicle_viewmodel.dart';
import '../../presentation/controllers/vehicle/vehicle_list_viewmodel.dart';

final injector = AutoInjector();

void setupDependencyInjection() {
  injector.addSingleton<ThemeController>(() => ThemeController());

  // User Module
  injector.addSingleton<IUserRemoteService>(UserRemoteServiceImpl.new);
  injector.addSingleton<IUserRepository>(UserRepositoryImpl.new);
  injector.addSingleton<IGetUserUseCase>(GetUserUseCase.new);
  injector.addSingleton<ISaveUserDataUseCase>(SaveUserDataUseCase.new);
  injector.addSingleton<IUpdateProfilePictureUseCase>(UpdateProfilePictureUseCase.new);
  injector.addSingleton<IDeleteUserAccountUseCase>(DeleteUserAccountUseCase.new);
  injector.addSingleton<IUserUseCaseFacade>(UserUseCaseFacadeImpl.new);

  // Company Module
  injector.addSingleton<ICompanyRemoteService>(CompanyRemoteServiceImpl.new);
  injector.addSingleton<ICompanyRepository>(CompanyRepositoryImpl.new);
  injector.addSingleton<ICreateCompanyUseCase>(CreateCompanyUseCase.new);
  injector.addSingleton<IFetchCompaniesByOwnerUseCase>(FetchCompaniesByOwnerUseCase.new);
  injector.addSingleton<IFetchCompaniesByMemberUseCase>(FetchCompaniesByMemberUseCase.new);
  injector.addSingleton<IUpdateCompanyUseCase>(UpdateCompanyUseCase.new);
  injector.addSingleton<IUpdateCompanyLogoUseCase>(UpdateCompanyLogoUseCase.new);
  injector.addSingleton<IDeleteCompanyUseCase>(DeleteCompanyUseCase.new);
  injector.addSingleton<ICompanyUseCaseFacade>(CompanyUseCaseFacadeImpl.new);

  // CompanyMember Module
  injector.addSingleton<ICompanyMemberService>(CompanyMemberServiceImpl.new);
  injector.addSingleton<ICompanyMemberRepository>(CompanyMemberRepositoryImpl.new);
  injector.addSingleton<IFetchCompanyMembersUseCase>(FetchCompanyMembersUseCaseImpl.new);
  injector.addSingleton<IFetchUserMembershipsUseCase>(FetchUserMembershipsUseCaseImpl.new);
  injector.addSingleton<IGetMemberLinkUseCase>(GetMemberLinkUseCaseImpl.new);
  injector.addSingleton<IAddCompanyMemberUseCase>(AddCompanyMemberUseCaseImpl.new);
  injector.addSingleton<IChangeCompanyMemberRoleUseCase>(ChangeCompanyMemberRoleUseCaseImpl.new);
  injector.addSingleton<IRemoveCompanyMemberUseCase>(RemoveCompanyMemberUseCaseImpl.new);
  injector.addSingleton<ICompanyMemberFacade>(CompanyMemberFacadeImpl.new);

  // Route Module
  injector.addSingleton<IRouteRemoteService>(RouteRemoteServiceImpl.new);
  injector.addSingleton<IRouteRepository>(RouteRepositoryImpl.new);
  injector.addSingleton<IFetchAllRoutesUseCase>(FetchAllRoutesUseCaseImpl.new);
  injector.addSingleton<IFetchRoutesByCompanyUseCase>(FetchRoutesByCompanyUseCaseImpl.new);
  injector.addSingleton<IGetRouteByIdUseCase>(GetRouteByIdUseCaseImpl.new);
  injector.addSingleton<ICreateRouteUseCase>(CreateRouteUseCaseImpl.new);
  injector.addSingleton<IUpdateRouteUseCase>(UpdateRouteUseCaseImpl.new);
  injector.addSingleton<IUpdateRouteImageUseCase>(UpdateRouteImageUseCaseImpl.new);
  injector.addSingleton<IDeleteRouteUseCase>(DeleteRouteUseCaseImpl.new);
  injector.addSingleton<IRequestToJoinRouteUseCase>(RequestToJoinRouteUseCaseImpl.new);
  injector.addSingleton<ICancelJoinRequestUseCase>(CancelJoinRequestUseCaseImpl.new);
  injector.addSingleton<IApprovePassengerInRouteUseCase>(ApprovePassengerInRouteUseCaseImpl.new);
  injector.addSingleton<IRemovePassengerFromRouteUseCase>(RemovePassengerFromRouteUseCaseImpl.new);
  injector.addSingleton<IFetchRouteUsersByIdsUseCase>(FetchRouteUsersByIdsUseCaseImpl.new);
  injector.addSingleton<IAssignDriverToRouteUseCase>(AssignDriverToRouteUseCaseImpl.new);
  injector.addSingleton<ITogglePassengerPresenceUseCase>(TogglePassengerPresenceUseCaseImpl.new);
  injector.addSingleton<IStartRouteTripUseCase>(StartRouteTripUseCaseImpl.new);
  injector.addSingleton<IFinishRouteTripUseCase>(FinishRouteTripUseCaseImpl.new);
  injector.addSingleton<IRouteUseCaseFacade>(RouteUseCaseFacadeImpl.new);

  // Vehicle Module
  injector.addSingleton<IVehicleService>(VehicleServiceImpl.new);
  injector.addSingleton<IVehicleRepository>(VehicleRepositoryImpl.new);
  injector.addSingleton<IFetchCompanyVehiclesUseCase>(FetchCompanyVehiclesUseCaseImpl.new);
  injector.addSingleton<IGetVehicleByIdUseCase>(GetVehicleByIdUseCaseImpl.new);
  injector.addSingleton<IFetchDriverVehiclesUseCase>(FetchDriverVehiclesUseCaseImpl.new);
  injector.addSingleton<ICreateVehicleUseCase>(CreateVehicleUseCaseImpl.new);
  injector.addSingleton<IUpdateVehicleUseCase>(UpdateVehicleUseCaseImpl.new);
  injector.addSingleton<IToggleVehicleStatusUseCase>(ToggleVehicleStatusUseCaseImpl.new);
  injector.addSingleton<IAssignVehicleDriverUseCase>(AssignVehicleDriverUseCaseImpl.new);
  injector.addSingleton<IDeleteVehicleUseCase>(DeleteVehicleUseCaseImpl.new);
  injector.addSingleton<IVehicleFacade>(VehicleFacadeImpl.new);

  // Authentication Module
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

  // Trip Module
  injector.addSingleton<ITripService>(TripServiceImpl.new);
  injector.addSingleton<ITripRepository>(TripRepositoryImpl.new);
  injector.addSingleton<IFetchTripsByRouteUseCase>(FetchTripsByRouteUseCaseImpl.new);
  injector.addSingleton<IFetchTripsByDriverUseCase>(FetchTripsByDriverUseCaseImpl.new);
  injector.addSingleton<IFetchTripsByCompanyUseCase>(FetchTripsByCompanyUseCaseImpl.new);
  injector.addSingleton<IGetTripByIdUseCase>(GetTripByIdUseCaseImpl.new);
  injector.addSingleton<IWatchTripByIdUseCase>(WatchTripByIdUseCaseImpl.new);
  injector.addSingleton<IWatchActiveTripsByRouteUseCase>(WatchActiveTripsByRouteUseCaseImpl.new);
  injector.addSingleton<ICreateTripUseCase>(CreateTripUseCaseImpl.new);
  injector.addSingleton<IGenerateScaledTripsUseCase>(GenerateScaledTripsUseCaseImpl.new);
  injector.addSingleton<IUpdateTripUseCase>(UpdateTripUseCaseImpl.new);
  injector.addSingleton<IStartTripUseCase>(StartTripUseCaseImpl.new);
  injector.addSingleton<IFinishTripUseCase>(FinishTripUseCaseImpl.new);
  injector.addSingleton<ICancelTripUseCase>(CancelTripUseCaseImpl.new);
  injector.addSingleton<IUpdateDriverLocationUseCase>(UpdateDriverLocationUseCaseImpl.new);
  injector.addSingleton<IMarkStopCompletedUseCase>(MarkStopCompletedUseCaseImpl.new);
  injector.addSingleton<ISetPassengerReadyAtStopUseCase>(SetPassengerReadyAtStopUseCaseImpl.new);
  injector.addSingleton<IDeleteTripUseCase>(DeleteTripUseCaseImpl.new);
  injector.addSingleton<ITripFacade>(TripFacadeImpl.new);


  // Boarding Module
  injector.addSingleton<IBoardingService>(BoardingServiceImpl.new);
  injector.addSingleton<IBoardingRepository>(BoardingRepositoryImpl.new);
  injector.addSingleton<IGetOrCreateDailyBoardingUseCase>(GetOrCreateDailyBoardingUseCaseImpl.new);
  injector.addSingleton<IFetchBoardingsByRouteAndDateUseCase>(FetchBoardingsByRouteAndDateUseCaseImpl.new);
  injector.addSingleton<IFetchBoardingsByTripUseCase>(FetchBoardingsByTripUseCaseImpl.new);
  injector.addSingleton<IFetchUserBoardingHistoryUseCase>(FetchUserBoardingHistoryUseCaseImpl.new);
  injector.addSingleton<IWatchPassengerBoardingUseCase>(WatchPassengerBoardingUseCaseImpl.new);
  injector.addSingleton<IWatchRouteBoardingsByDateUseCase>(WatchRouteBoardingsByDateUseCaseImpl.new);
  injector.addSingleton<ISaveBoardingUseCase>(SaveBoardingUseCaseImpl.new);
  injector.addSingleton<IUpdateBoardingAttendanceUseCase>(UpdateBoardingAttendanceUseCaseImpl.new);
  injector.addSingleton<ISetReadyForBoardingUseCase>(SetReadyForBoardingUseCaseImpl.new);
  injector.addSingleton<IMarkBoardingOutcomeUseCase>(MarkBoardingOutcomeUseCaseImpl.new);
  injector.addSingleton<IRegisterBoardingNotificationUseCase>(RegisterBoardingNotificationUseCaseImpl.new);
  injector.addSingleton<IDeleteBoardingUseCase>(DeleteBoardingUseCaseImpl.new);
  injector.addSingleton<IBoardingFacade>(BoardingFacadeImpl.new);

  // ViewModels
  injector.addSingleton<AuthViewModel>(AuthViewModel.new);
  injector.addSingleton<UserViewModel>(UserViewModel.new);
  injector.addSingleton<CompanyViewModel>(CompanyViewModel.new);
  injector.addSingleton<CompanyListViewModel>(CompanyListViewModel.new);
  injector.addSingleton<CompanyMemberViewModel>(CompanyMemberViewModel.new);
  injector.addSingleton<RouteViewModel>(RouteViewModel.new);
  injector.addSingleton<RouteListViewModel>(RouteListViewModel.new);
  injector.addSingleton<VehicleViewModel>(VehicleViewModel.new);
  injector.addSingleton<VehicleListViewModel>(VehicleListViewModel.new);
  injector.addSingleton<TripViewModel>(TripViewModel.new);
  injector.addSingleton<TripListViewModel>(TripListViewModel.new);

  injector.addSingleton<BoardingViewModel>(BoardingViewModel.new);
  injector.addSingleton<BoardingListViewModel>(BoardingListViewModel.new);

  injector.commit();
}