import '../../../../domain/models/authentication/session_token.dart';

abstract class ILocalSessionStore {
  Future<void> save(SessionToken? token);
  Future<SessionToken?> read();
  Future<void> clear();
}