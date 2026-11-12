class AppMessages {
  static const error = _Error();
}

class _Error {
  const _Error();
  final String defaultError = 'Ocorreu um erro inesperado.';
  final String inputError = 'Entrada inválida.';
  final String apiLocalError = 'Erro de armazenamento de local.';

  final String emptyResultError = 'Nenhum resultado encontrado.';

  final String nullStringError = 'Valor nulo ou vazio não é permitido.';
  final String invalidDateError = 'Data inválida. Use o formato DD/MM/AAAA.';
  final String invalidEmailError = 'Email inválido.';
  final String maxDoubleError = 'Valor excede o máximo permitido.';
  final String minDoubleError = 'Valor é menor que o mínimo permitido.';
  final String longerStringError =
      'Valor excede o número máximo de caracteres.';
  final String shorterStringError =
      'Valor é menor que o número mínimo de caracteres.';
  final String lowerCharMissedError =
      'A senha deve conter pelo menos uma letra minúscula.';
  final String upperCharMissedError =
      'A senha deve conter pelo menos uma letra maiúscula.';
  final String specialCharMissedError =
      'A senha deve conter pelo menos um caractere especial.';
  final String digitMissedError = 'A senha deve conter pelo menos um dígito.';
  final String invalidPasswordError = 'Campo não pode ser vazio.';
  final String passwordMismatchError = 'As senhas não coincidem.';
  final String invalidPhoneError = 'Número de telefone inválido.';

  final String invalidInput =
      'Entrada inválida. Verifique os dados fornecidos.';

  final String loginFailed = 'E-mail ou senha incorretos.';
  final String googleLoginCancelled = 'Login com Google cancelado.';
  final String googleLoginFailed = 'Não foi possível entrar com o Google.';

  final String emailAlreadyInUse = 'Já existe uma conta cadastrada com este e-mail.';

  final String userNotFound = 'Usuário não encontrado na sessão.';
  final String networkError = 'Sem conexão com a internet. Verifique sua rede.';
  final String userCreationFailed = 'Falha ao criar o usuário no Firebase.';
  final String checkEmailStatusError = 'Erro ao consultar o status do e-mail.';
  final String resendEmailError = 'Erro ao enviar e-mail de verificação.';
  final String expiredAccountDeleteError = 'Erro ao remover conta expirada.';
  final String emailNotVerifiedYet = 'O seu e-mail ainda não foi verificado. Abra a caixa de entrada ou spam e clique no link.';
  final String verificationLinkSent = 'Novo link de verificação enviado com sucesso!';
  final String tooManyRequests = 'Muitas tentativas em pouco tempo. Aguarde alguns minutos antes de solicitar um novo link.';
  final String network = 'Sem conexão com a internet. Verifique sua rede.';
  final String requiresRecentLogin = 'Esta ação é sensível e exige que você faça login novamente.';
  final String invalidPassword = 'Senha incorreta';
}
