import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/typedefs/types_defs.dart';
import '../../../core/failure/failure.dart' show Failure, DefaultFailure;
import '../../../core/patterns/result.dart';
import '../../../data/repositories/authentication/i_auth_repository.dart';
import '../../../data/repositories/i_user_repositoy.dart';
import '../../models/user_entity.dart';
import 'i_auth_usecases.dart';

final class SignInUseCase implements ISignInUseCase {
  final IAuthRepository _authRepository;

  SignInUseCase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  @override
  Future<AuthSessionResult> call(SignInParams params) async {
    await Future.delayed(const Duration(seconds: 2));
    return _authRepository.signIn(params.email, params.password);
  }
}

final class SignInWithGoogleUseCase implements ISignInWithGoogleUseCase {
  final IAuthRepository _authRepository;
  final IUserRepository _userRepository;

  SignInWithGoogleUseCase({
    required IAuthRepository authRepository,
    required IUserRepository userRepository,
  })  : _authRepository = authRepository,
        _userRepository = userRepository;

  @override
  Future<AuthSessionResult> call(NoParams params) async {
    await Future.delayed(const Duration(seconds: 1));

    final authResult = await _authRepository.signInWithGoogle();

    return await authResult.fold(
      onSuccess: (authSession) async {
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          final googleUser = UserModel(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            name: firebaseUser.displayName ?? 'Usuário Google',
            photoUrl: firebaseUser.photoURL,
          );

          await _userRepository.saveUser(googleUser);
        }

        return Success(authSession);
      },
      onFailure: (failure) => Error(failure),
    );
  }
}

final class SignOutUseCase implements ISignOutUseCase {
  final IAuthRepository _authRepository;

  SignOutUseCase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  @override
  Future<VoidResult> call(NoParams params) async {
    await Future.delayed(const Duration(seconds: 3));
    return _authRepository.signOut();
  }
}

final class SendEmailVerificationLinkUseCase
    implements ISendEmailVerificationLinkUseCase {
  final IAuthRepository _authRepository;

  SendEmailVerificationLinkUseCase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  @override
  Future<Result<void, Failure>> call(
    SendEmailVerificationLinkParams params,
  ) async {
    await Future.delayed(const Duration(seconds: 1));
    return _authRepository.sendEmailVerificationLink(params.email);
  }
}

final class SignUpWithVerifiedEmailUseCase
    implements ISignUpWithVerifiedEmailUseCase {
  final IAuthRepository _authRepository;
  final IUserRepository _userRepository;

  SignUpWithVerifiedEmailUseCase({
    required IAuthRepository authRepository,
    required IUserRepository userRepository,
  })  : _authRepository = authRepository,
        _userRepository = userRepository;

  @override
  Future<AuthSessionResult> call(SignUpWithVerifiedEmailParams params) async {
    final authResult = await _authRepository.signUpWithVerifiedEmail(
      name: params.name,
      email: params.email,
      password: params.password,
    );

    return await authResult.fold(
      onSuccess: (authSession) async {
        final firebaseUser = FirebaseAuth.instance.currentUser;

        if (firebaseUser == null) {
          return Error(
            DefaultFailure('Conta criada no Auth, mas o usuário ativo não foi encontrado.'),
          );
        }

        final initialUser = UserModel(
          uid: firebaseUser.uid,
          email: params.email,
          name: params.name,
        );

        final saveResult = await _userRepository.saveUser(initialUser);

        return saveResult.fold(
          onSuccess: (_) => Success(authSession),
          onFailure: (failure) => Error(
            DefaultFailure('Conta criada, mas falhou ao salvar perfil: ${failure.msg}'),
          ),
        );
      },
      onFailure: (failure) {
        return Error(failure);
      },
    );
  }
}

final class CheckEmailVerifiedStatusUseCase
    implements ICheckEmailVerifiedStatusUseCase {
  final IAuthRepository _authRepository;

  CheckEmailVerifiedStatusUseCase({required IAuthRepository authRepository,})
    : _authRepository = authRepository;

  @override
  Future<Result<bool, Failure>> call(NoParams params) async {
    return _authRepository.checkEmailVerifiedStatus();
  }
}

final class DeleteExpiredAccountUseCase
    implements IDeleteExpiredAccountUseCase {
  final IAuthRepository _authRepository;
  final IUserRepository _userRepository;

  DeleteExpiredAccountUseCase({required IAuthRepository authRepository, required IUserRepository userRepository})
    : _authRepository = authRepository, _userRepository = userRepository;

  @override
  Future<Result<void, Failure>> call(NoParams params) async {
    await _userRepository.deleteAccount();
    return _authRepository.deleteExpiredAccount();
  }
}