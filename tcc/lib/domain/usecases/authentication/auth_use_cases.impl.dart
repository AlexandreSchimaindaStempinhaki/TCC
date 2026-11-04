import '../../../../core/typedefs/types_defs.dart';

import '../../../data/repositories/authentication/i_auth_repository.dart';
import 'i_auth_usecases.dart';

final class SignInUseCase implements ISignInUseCase {
  final IAuthRepository _authRepository;
  
  SignInUseCase({required IAuthRepository authRepository})
      : _authRepository = authRepository;

  @override
  Future<AuthSessionResult> call(SignInParams params) async {
    // Simula uma chamada de rede com atraso
    await Future.delayed(const Duration(seconds: 2));
    return _authRepository.signIn(params.email, params.password);

  }
}

final class SignInWithGoogleUseCase implements ISignInWithGoogleUseCase {
  final IAuthRepository _authRepository;
  
  SignInWithGoogleUseCase({required IAuthRepository authRepository})
      : _authRepository = authRepository;

  @override
  Future<AuthSessionResult> call(NoParams params) async {
    // Simula uma chamada de rede com atraso
    await Future.delayed(const Duration(seconds: 1));
    return _authRepository.signInWithGoogle();
  }
} 

final class SignOutUseCase implements ISignOutUseCase {
  final IAuthRepository _authRepository;
  
  SignOutUseCase({required IAuthRepository authRepository})
      : _authRepository = authRepository;

  @override
  Future<VoidResult> call(NoParams params) async {
    // Simula uma chamada de rede com atraso
    await Future.delayed(const Duration(seconds: 3));
    return _authRepository.signOut();
  }
} 

final class SignUpUseCase implements ISignUpUseCase {
  final IAuthRepository _authRepository;
  
  SignUpUseCase({required IAuthRepository authRepository})
      : _authRepository = authRepository;

  @override
  Future<AuthSessionResult> call(SignUpParams params) async {
    // Simula uma chamada de rede com atraso
    await Future.delayed(const Duration(seconds: 2));
    return _authRepository.signUp(
      name: params.name,
      email: params.email,
      password: params.password,
    );
  }
}