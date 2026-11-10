import '../../../../core/failure/failure.dart';
import '../../../../core/typedefs/types_defs.dart';

import '../local/auth_local_session_manager.dart';
import '../../../../domain/models/authentication/session_token.dart';

import '../../../../domain/models/authentication/auth_entities.dart';
import 'i_auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../../core/patterns/result.dart';

/// Serviço de autenticação que utiliza o FirebaseAuth.
class FirebaseAuthService implements IAuthService {
  /// Instância do FirebaseAuth (injetável para testes)
  final fb.FirebaseAuth _firebaseAuth;

  /// Gerenciador de sessão local
  final AuthLocalSessionManager _localSession;

  /// Signal reativo que mantém a sessão atual do usuário
  final Signal<AuthSession?> _currentSessionSignal = Signal<AuthSession?>(null);

  /// Construtor
  /// Se não for fornecido, usa a instância padrão do FirebaseAuth
  FirebaseAuthService({
    fb.FirebaseAuth? firebaseAuth,
    required AuthLocalSessionManager localSession,
  }) : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
       _localSession = localSession {
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
  }

  /// Método interno chamado sempre que o Firebase detecta mudança no usuário
  /// (login, logout, token renovado, etc)
  void _onAuthStateChanged(fb.User? user) async {
    if (user == null) {
      _currentSessionSignal.value = null;
      return;
    }

    // Se já existe sessão ativa, NÃO recrie
    if (_currentSessionSignal.value != null) {
      return;
    }

    // Aqui significa: usuário logou AGORA pela primeira vez
    final tokenStr = await user.getIdToken() ?? '';

    // expiração manual fixa (1h)
    final tokenExp = DateTime.now().add(const Duration(hours: 1));

    final session = AuthSession(
      user: User(
        id: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
      ),
      token: Token(value: tokenStr, expiresAt: tokenExp),
    );

    // salva sessão local
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

  // -----------------------------
  // Getters públicos
  // -----------------------------

  /// Retorna o Signal reativo da sessão
  @override
  Signal<AuthSession?> get currentSessionSignal => _currentSessionSignal;

  /// Retorna a sessão atual ou null se não houver usuário logado
  @override
  AuthSession? get currentSession => _currentSessionSignal.value;

  // -----------------------------
  // Métodos de autenticação
  // -----------------------------

  /// Login com email e senha
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

      // Mapeia os erros comuns do Firebase Auth para a sua Failure do AppMessages
      if (errorStr.contains('user-not-found') ||
          errorStr.contains('wrong-password') ||
          errorStr.contains('invalid-credential') ||
          errorStr.contains('invalid-email') ||
          errorStr.contains('user-mismatch')) {
        return Error(
          LoginFailure(),
        ); // Pega a mensagem do AppMessages.error.loginFailed
      }

      return Error(DefaultFailure());
    }
  }

  /// Login com conta do Google
  @override
  Future<AuthSessionResult> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        serverClientId:
            '760419209227-sirv8httdekg0mh1m86hnfjutsiajpcu.apps.googleusercontent.com',
      );
      final googleUser = await googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;

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
        ); // Pega a mensagem de cancelado
      }

      return Error(
        GoogleLoginFailedFailure(),
      ); // Pega a mensagem de falha do Google
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

  /// Cria a conta no Firebase, salva o nome, envia o e-mail e gera a sessão local
  @override
  Future<AuthSessionResult> signUpWithVerifiedEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Cria o usuário com e-mail e senha no Firebase Auth
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // 2. Atualiza o nome de exibição se fornecido
        if (name.isNotEmpty) {
          await user.updateDisplayName(name);
        }

        // 3. Dispara o envio do e-mail de verificação padrão do Firebase
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

  /// Checa o status atual da verificação de e-mail do usuário no Firebase
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

  /// Apaga a conta pendente no Firebase Auth e limpa as sessões locais se o tempo limite expirar
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

  /// Logout do usuário atual
  @override
  Future<VoidResult> signOut() async {
    await _localSession.clear();
    await _firebaseAuth.signOut();
    return Success(null);
  }

  /// Inicializa a sessão ao carregar o app
  /// Lê a sessão local primeiro e atualiza o Signal
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
}
