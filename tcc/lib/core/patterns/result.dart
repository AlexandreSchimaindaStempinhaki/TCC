// Classe selada (sealed) que representa um resultado que pode ser sucesso ou erro.
// TOk: tipo do valor em caso de sucesso.
// TError: tipo do valor em caso de erro.
sealed class Result<TOk, TError> {
  const Result();

  // Indica se o resultado é sucesso
  bool get isSuccess => this is Success<TOk, TError>;

  // Indica se o resultado é erro
  bool get isFailure => this is Error<TOk, TError>;

  // Retorna o valor de sucesso ou null
  TOk? get successValueOrNull => switch (this) {
        Success(:final value) => value,
        _ => null,
      };

  // Retorna o valor de erro ou null
  TError? get failureValueOrNull => switch (this) {
        Error(:final value) => value,
        _ => null,
      };

  // Função que trata ambos os casos (sucesso e erro) usando pattern matching do Dart 3
  R fold<R>({
    required R Function(TOk okValue) onSuccess,
    required R Function(TError errorValue) onFailure,
  }) {
    return switch (this) {
      Success(:final value) => onSuccess(value),
      Error(:final value) => onFailure(value),
    };
  }
}

// Representa um sucesso com valor do tipo TOk
final class Success<TOk, TError> extends Result<TOk, TError> {
  final TOk value;
  const Success(this.value);
}

// Representa uma falha com valor do tipo TError
final class Error<TOk, TError> extends Result<TOk, TError> {
  final TError value;
  const Error(this.value);
}