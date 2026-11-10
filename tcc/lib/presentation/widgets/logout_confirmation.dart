import 'package:flutter/material.dart';
import '../widgets/animated_three_dots.dart';

class LogoutConfirmation extends StatefulWidget {
  final String title;
  final String content;
  final String confirmText;
  final Future<void> Function()? onConfirm;

  const LogoutConfirmation({
    super.key,
    this.title = 'Sair da Conta',
    this.content = 'Tem certeza de que deseja sair da sua conta?',
    this.confirmText = 'Sair',
    this.onConfirm,
  });

  @override
  State<LogoutConfirmation> createState() => _LogoutConfirmationState();
}

class _LogoutConfirmationState extends State<LogoutConfirmation> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Text(
        widget.title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        widget.content,
        style: const TextStyle(fontSize: 15),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: isLoading
              ? null
              : () async {
                  if (widget.onConfirm != null) {
                    setState(() => isLoading = true);
                    try {
                      await widget.onConfirm!();
                    } finally {
                      if (mounted) setState(() => isLoading = false);
                    }
                  } else {
                    // Comportamento padrão (para telas antigas que só dão pop(true))
                    Navigator.of(context).pop(true);
                  }
                },
          child: isLoading
              ? AnimatedThreeDots(
                  color: colorScheme.error,
                )
              : Text(
                  widget.confirmText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}