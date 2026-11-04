import 'package:flutter/material.dart';
import '../../domain/models/authentication/auth_entities.dart';
import '../failure/failure.dart';
// import '../../domain/models/account_entity.dart';

import '../patterns/result.dart';

// typedefs para tipo Result
// typedefs para autenticação
typedef VoidResult = Result<void, Failure>;
typedef AuthSessionResult = Result<AuthSession, Failure>;


// typedfs para parâmetros
// tipos usadoos para modulo de autenticação
typedef NoParams = ();
typedef SignInParams = ({String email, String password});
typedef SignUpParams =
    ({String? name,String email, String password});

// // typedefs para tipo Result
// typedef AccountResult = Result<Account, Failure>;
// typedef CharacterResult = Result<Character,Failure>;
// typedef ListCharacterResult = Result<List<Character>, Failure>;

//typedfs para parâmetros
// typedef AccountParams = ({Account account});

// tipos usadoos Conta de Usuario
typedef AccountNameParams = ({String accountName});
// tipos usados para Personagem
// typedef CharacterIdParams = ({String id});
// typedef CharacterParams = ({Character character});

// typedefs para ser usados em componentes de UI
typedef FormFieldControl = ({
  GlobalKey<FormFieldState> key,
  FocusNode focus,
  TextEditingController controller,
});