import 'package:signals_flutter/signals_flutter.dart';

import '../../../domain/models/authentication/auth_entities.dart';

enum AuthStatus { 
  unauthenticated, 
  authenticated,   
  expired          
}

class AuthSessionState {
  final status = signal<AuthStatus>(AuthStatus.unauthenticated);

  final session = signal<AuthSession?>(null);

  final message = signal<String?>(null);

  bool get isAuthenticated {
    return status.value == AuthStatus.authenticated &&
      session.value != null &&
      session.value!.isValid;
  }
  
  bool get isExpired => status.value == AuthStatus.expired;

  void setAuthenticated(AuthSession authSession) {
    session.value = authSession;     
    status.value = AuthStatus.authenticated; 
    message.value = null;             
  }

  void setUnauthenticated({String? msg}) {
    session.value = null;                  
    status.value = AuthStatus.unauthenticated; 
    message.value = msg;                   
  }

  void setExpired({String? msg}) {
    status.value = AuthStatus.expired;    
    message.value = msg ?? 'Sessão expirada'; 
  }

  void clearMessage() => message.value = null;

  void setMessage(String msg) => message.value = msg;
}