import 'dart:io';

import 'package:flutter/material.dart';
import '../../domain/models/authentication/auth_entities.dart';
import '../../domain/models/company_entity.dart';
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
typedef SignUpParams = ({String? name, String email, String password});

class SendEmailVerificationLinkParams {
  final String email;
  const SendEmailVerificationLinkParams({required this.email});
}

class SignUpWithVerifiedEmailParams {
  final String name;
  final String email;
  final String password;
  final String code;

  const SignUpWithVerifiedEmailParams({
    required this.name,
    required this.email,
    required this.password,
    required this.code,
  });
}

class ChangePasswordParams {
  final String currentPassword;
  final String newPassword;

  ChangePasswordParams({
    required this.currentPassword,
    required this.newPassword,
  });
}

class DeleteAccountParams {
  final String currentPassword;

  DeleteAccountParams({required this.currentPassword});
}

class SendPasswordResetEmailParams {
  final String email;

  SendPasswordResetEmailParams({required this.email});
}

class CreateCompanyParams {
  final CompanyModel company;
  const CreateCompanyParams({required this.company});
}

class FetchCompaniesByOwnerParams {
  final String? ownerId;
  const FetchCompaniesByOwnerParams({this.ownerId});
}

class FetchCompaniesByMemberParams {
  final String? memberId;
  const FetchCompaniesByMemberParams({this.memberId});
}

class UpdateCompanyParams {
  final CompanyModel company;
  const UpdateCompanyParams({required this.company});
}

class UpdateCompanyLogoParams {
  final String cnpj;
  final File imageFile;
  const UpdateCompanyLogoParams({required this.cnpj, required this.imageFile});
}

class DeleteCompanyParams {
  final String cnpj;
  const DeleteCompanyParams({required this.cnpj});
}

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
