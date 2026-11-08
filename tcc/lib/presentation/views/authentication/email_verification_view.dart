import 'dart:async';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/routes/indigo_routes.dart';
import '../../controllers/authentication/auth_session_viewmodel.dart';
import '../../widgets/animated_three_dots.dart';
import '../../widgets/header_background.dart';
import '../../../core/routes/auth_routes.dart'; // Certifique-se de importar o AuthPaths para o botão voltar

class EmailVerificationPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const EmailVerificationPage({super.key, required this.userData});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  late final AuthViewModel authController;
  StreamSubscription<User?>? _authSubscription;

  final isLoadingButton = signal(false);
  final isResending = signal(false);
  final verificationError = signal<String?>(null);

  // Sinal reativo para exibir o e-mail do utilizador na interface
  final userEmailSignal = signal<String>('Carregando e-mail...');

  @override
  void initState() {
    super.initState();
    authController = injector.get<AuthViewModel>();
    authController.session.clearMessage();

    // Inicia a escuta da sessão para carregar o e-mail e enviar o link
    _loadUserEmail();
  }

  @override
  void dispose() {
    // Cancela o listener para evitar memory leaks
    _authSubscription?.cancel();
    super.dispose();
  }

  void _loadUserEmail() {
    // Escuta as mudanças de estado de autenticação em tempo real
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        userEmailSignal.value = user.email ?? widget.userData?['email'] ?? 'seu e-mail';
        // Dispara automaticamente assim que a sessão é confirmada
        _sendVerificationEmailIfNeeded(user); 
      } else {
        // Fallback caso o Firebase ainda esteja a processar o login
        userEmailSignal.value = widget.userData?['email'] ?? 'Carregando...';
      }
    });
  }

  Future<void> _sendVerificationEmailIfNeeded(User user) async {
    try {
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        debugPrint('📧 [EmailVerificationPage] E-mail de verificação enviado automaticamente!');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        debugPrint('⚠️ O e-mail já foi enviado recentemente.');
      }
    } catch (e) {
      verificationError.value = 'Não foi possível enviar o e-mail automático.';
    }
  }

  Future<void> _checkEmailVerified() async {
    // Trava para evitar múltiplos cliques simultâneos
    if (isLoadingButton.value) return; 

    try {
      isLoadingButton.value = true;
      verificationError.value = null;
      
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        verificationError.value = 'Sessão não encontrada. Por favor, faça login novamente.';
        return;
      }

      // Recarrega os dados do servidor para atualizar o status do e-mail
      await user.reload();
      user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        if (!mounted) return;
        // Sucesso! Avança para a Home do Índigo
        context.goNamed(IndigoRouteNames.home);
      } else {
        verificationError.value = 'O seu e-mail ainda não foi verificado. Abra a sua caixa de entrada e clique no link.';
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        verificationError.value = 'Sem ligação à internet.';
      } else {
        verificationError.value = 'Erro ao verificar o status. Tente novamente.';
      }
    } catch (e) {
      verificationError.value = 'Erro inesperado. Tente novamente.';
    } finally {
      if (mounted) {
        isLoadingButton.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                HeaderBackground(height: context.screenHeight * 0.3),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () async {
                          // Limpa mensagens e DESLOGA antes de voltar
                          authController.session.clearMessage();
                          await FirebaseAuth.instance.signOut();
                          
                          if (context.mounted) {
                             context.goNamed(AuthPaths.login); 
                          }
                        },
                        tooltip: 'Voltar e Cancelar Registo',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verifique o seu E-mail',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enviámos um link de confirmação para:',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Exibe o e-mail de forma reativa
                  Watch(
                    (context) => Text(
                      userEmailSignal.value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  Text(
                    'Abra a sua caixa de entrada (e verifique também a pasta de Spam) e clique no link para ativar a sua conta.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tratamento de erros na UI
                  Watch(
                    (context) =>
                        verificationError.value != null ||
                                authController.session.message.value != null
                            ? Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 16.0,
                                  left: 4.0,
                                ),
                                child: Text(
                                  verificationError.value ??
                                      authController.session.message.value ??
                                      '',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                  ),

                  // Botão "Já verifiquei o meu e-mail"
                  Watch(
                    (context) => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoadingButton.value ? null : _checkEmailVerified,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoadingButton.value
                            ? const AnimatedThreeDots(color: Colors.white)
                            : const Text(
                                'Já verifiquei o meu e-mail',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Botão "Reenviar Link"
                  Watch(
                    (context) => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: (isResending.value || isLoadingButton.value)
                            ? null
                            : () async {
                                try {
                                  isResending.value = true;
                                  verificationError.value = null;
                                  authController.session.clearMessage();

                                  // Obtém o utilizador atual do Firebase nativamente
                                  final user = FirebaseAuth.instance.currentUser;
                                  
                                  if (user != null) {
                                    await user.sendEmailVerification();
                                    
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Novo link de verificação enviado!'),
                                      ),
                                    );
                                  } else {
                                    verificationError.value = 'Utilizador não encontrado. Refaça o login.';
                                  }
                                } on FirebaseAuthException catch (e) {
                                  if (e.code == 'too-many-requests') {
                                    verificationError.value = 'Muitas tentativas. Aguarde alguns minutos antes de reenviar.';
                                  } else {
                                    verificationError.value = 'Erro ao reenviar o link. Tente novamente.';
                                  }
                                } finally {
                                  if (context.mounted) {
                                    isResending.value = false;
                                  }
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: colorScheme.primary,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isResending.value
                            ? AnimatedThreeDots(color: colorScheme.onSurface)
                            : Text(
                                'Reenviar Link',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}