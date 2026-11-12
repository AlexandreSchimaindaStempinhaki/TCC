import '../../../../core/failure/failure.dart';
import '../../../../core/typedefs/types_defs.dart';

import '../local/auth_local_session_manager.dart';
import '../../../../domain/models/authentication/session_token.dart';

import '../../../../domain/models/authentication/auth_entities.dart';
import 'i_auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/patterns/result.dart';

class FirebaseAuthService implements IAuthService {
  final fb.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final AuthLocalSessionManager _localSession;

  final Signal<AuthSession?> _currentSessionSignal = Signal<AuthSession?>(null);

  FirebaseAuthService({
    fb.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    required AuthLocalSessionManager localSession,
  }) : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _localSession = localSession {
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(fb.User? user) async {
    if (user == null) {
      _currentSessionSignal.value = null;
      return;
    }

    if (_currentSessionSignal.value != null) {
      return;
    }

    final tokenStr = await user.getIdToken() ?? '';
    final tokenExp = DateTime.now().add(const Duration(hours: 1));

    final session = AuthSession(
      user: User(
        id: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
      ),
      token: Token(value: tokenStr, expiresAt: tokenExp),
    );

    final sessionToken = SessionToken(
      uid: session.user.id,
      name: session.user.name,
      email: session.user.email,
      value: tokenStr,
      expiresAt: tokenExp,
      refreshToken: null,
      provider: AuthProvider.firebase,
    );

    await _localSession.setToken(sessionToken);

    _currentSessionSignal.value = session;
  }

  @override
  Signal<AuthSession?> get currentSessionSignal => _currentSessionSignal;

  @override
  AuthSession? get currentSession => _currentSessionSignal.value;

  @override
  Future<AuthSessionResult> signIn(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        final tokenStr = await user.getIdToken() ?? '';
        final tokenExp = DateTime.now().add(const Duration(hours: 1));

        final session = AuthSession(
          user: User(
            id: user.uid,
            name: user.displayName ?? '',
            email: user.email ?? '',
          ),
          token: Token(value: tokenStr, expiresAt: tokenExp),
        );

        final sessionToken = SessionToken(
          uid: session.user.id,
          name: session.user.name,
          email: session.user.email,
          value: tokenStr,
          expiresAt: tokenExp,
          refreshToken: null,
          provider: AuthProvider.firebase,
        );

        await _localSession.setToken(sessionToken);

        return Success(session);
      }

      return Error(LoginFailure());
    } catch (e) {
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('user-not-found') ||
          errorStr.contains('wrong-password') ||
          errorStr.contains('invalid-credential') ||
          errorStr.contains('invalid-email') ||
          errorStr.contains('user-mismatch')) {
        return Error(
          LoginFailure(),
        ); 
      }

      return Error(DefaultFailure());
    }
  }

  @override
  Future<AuthSessionResult> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        serverClientId:
            '760419209227-sirv8httdekg0mh1m86hnfjutsiajpcu.apps.googleusercontent.com',
      );
      final googleUser = await googleSignIn.authenticate();

      final googleAuth = await googleUser.authentication;

      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.idToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user == null) {
        return Error(GoogleLoginFailedFailure());
      }

      final tokenStr = await user.getIdToken() ?? '';
      final tokenExp = DateTime.now().add(const Duration(hours: 1));

      final session = AuthSession(
        user: User(
          id: user.uid,
          name: user.displayName ?? '',
          email: user.email ?? '',
        ),
        token: Token(value: tokenStr, expiresAt: tokenExp),
      );

      final sessionToken = SessionToken(
        uid: session.user.id,
        name: session.user.name,
        email: session.user.email,
        value: tokenStr,
        expiresAt: tokenExp,
        refreshToken: null,
        provider: AuthProvider.google,
      );

      await _localSession.setToken(sessionToken);

      return Success(session);
    } catch (e) {
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('canceled')) {
        return Error(
          GoogleLoginCancelledFailure(),
        );
      }

      return Error(
        GoogleLoginFailedFailure(),
      ); 
    }
  }

  @override
  Future<Result<void, Failure>> sendEmailVerificationLink(String email) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
      return const Success(null);
    } catch (e) {
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('too-many-requests')) {
        return Error(TooManyRequestsFailure());
      }

      return Error(DefaultFailure(e.toString()));
    }
  }

  @override
  Future<AuthSessionResult> signUpWithVerifiedEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        if (name.isNotEmpty) {
          await user.updateDisplayName(name);
        }

        if (!user.emailVerified) {
          await user.sendEmailVerification();
        }

        final tokenStr = await user.getIdToken() ?? '';
        final tokenExp = DateTime.now().add(const Duration(hours: 1));

        final session = AuthSession(
          user: User(id: user.uid, name: name, email: email),
          token: Token(value: tokenStr, expiresAt: tokenExp),
        );

        final sessionToken = SessionToken(
          uid: session.user.id,
          name: session.user.name,
          email: session.user.email,
          value: tokenStr,
          expiresAt: tokenExp,
          refreshToken: null,
          provider: AuthProvider.firebase,
        );

        await _localSession.setToken(sessionToken);

        return Success(session);
      }

      return Error(DefaultFailure('Falha ao criar usuário'));
    } catch (e) {
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('email-already-in-use')) {
        return Error(EmailAlreadyInUseFailure());
      }

      return Error(DefaultFailure(e.toString()));
    }
  }

  @override
  Future<Result<bool, Failure>> checkEmailVerifiedStatus() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Error(UserNotFoundFailure());
      }

      await user.reload();
      final updatedUser = _firebaseAuth.currentUser;

      return Success(updatedUser?.emailVerified ?? false);
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        return Error(NetworkFailure());
      }
      return Error(DefaultFailure(e.message ?? e.toString()));
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> deleteExpiredAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) { 
        await user.delete();
      }
      return const Success(null);
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return Error(RequiresRecentLoginFailure());
      }
      return Error(DefaultFailure(e.message ?? 'Erro ao excluir conta.'));
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('requires-recent-login')) {
        return Error(RequiresRecentLoginFailure());
      }
      return Error(DefaultFailure(e.toString()));
    }
  }

  @override
  Future<VoidResult> signOut() async {
    await _localSession.clear();
    await _firebaseAuth.signOut();
    return const Success(null);
  }

  @override
  Future<void> initSession() async {
    final token = await _localSession.getValidToken();

    if (token != null) {
      _currentSessionSignal.value = AuthSession(
        user: User(
          id: token.uid,
          name: token.name ?? '',
          email: token.email ?? '',
        ),
        token: Token(value: token.value, expiresAt: token.expiresAt),
      );
    }
  }

  @override
  Future<Result<void, Failure>> reauthenticateWithPassword(String password) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || user.email == null) {
        return Error(UserNotFoundFailure());
      }

      final credential = fb.EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      return const Success(null);
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return Error(PasswordConfirmationFailure());
      }
      if (e.code == 'too-many-requests') {
        return Error(TooManyRequestsFailure());
      }
      return Error(DefaultFailure(e.message ?? 'Não foi possível validar sua senha.'));
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final reauthResult = await reauthenticateWithPassword(currentPassword);
      if (reauthResult is Error) {
        return reauthResult;
      }

      final user = _firebaseAuth.currentUser;
      if (user == null) {
         return Error(UserNotFoundFailure());
      }

      await user.updatePassword(newPassword);
      return const Success(null);
    } on fb.FirebaseAuthException catch (e) {
      return Error(DefaultFailure('Erro ao atualizar a senha: ${e.message}'));
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> deleteAccount(String currentPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Error(UserNotFoundFailure());
      }

      final reauthResult = await reauthenticateWithPassword(currentPassword);
      if (reauthResult is Error) {
        return reauthResult;
      }

      await _firestore.collection('users').doc(user.uid).delete();
      
      await user.delete();
      
      await _localSession.clear();
      _currentSessionSignal.value = null;
      
      return const Success(null);
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return const Success(null);
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
         return Error(UserNotFoundFailure());
      }
      return Error(DefaultFailure(e.message ?? 'Erro ao enviar e-mail de redefinição.'));
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }
}