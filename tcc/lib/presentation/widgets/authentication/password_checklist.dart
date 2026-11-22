import 'package:flutter/material.dart';

class PasswordChecklist extends StatelessWidget {
  final String password;
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasNumber;
  final bool hasSymbol;
  final bool passwordsMatch;

  const PasswordChecklist({
    super.key,
    required this.password,
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasNumber,
    required this.hasSymbol,
    required this.passwordsMatch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequirementRow('Mínimo de 6 caracteres', hasMinLength, context),
        const SizedBox(height: 4),
        _buildRequirementRow('Pelo menos uma letra maiúscula', hasUppercase, context),
        const SizedBox(height: 4),
        _buildRequirementRow('Pelo menos um número', hasNumber, context),
        const SizedBox(height: 4),
        _buildRequirementRow('Pelo menos um caractere especial', hasSymbol, context),
        const SizedBox(height: 4),
        _buildRequirementRow('As senhas coincidem', passwordsMatch, context),
      ],
    );
  }

  Widget _buildRequirementRow(String text, bool met, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 16,
          color: met ? Colors.green : colorScheme.secondary.withOpacity(0.5),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: met ? colorScheme.onSurface : colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}