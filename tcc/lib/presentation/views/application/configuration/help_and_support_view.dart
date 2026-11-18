import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../widgets/help_question_option.dart';
import '../../../../core/constants/app_assets.dart';

class HelpFaqItem {
  final String question;
  final String answer;
  final IconData icon;

  const HelpFaqItem({
    required this.question,
    required this.answer,
    required this.icon,
  });
}

class HelpFaqCategory {
  final String title;
  final List<HelpFaqItem> items;

  const HelpFaqCategory({
    required this.title,
    required this.items,
  });
}

class HelpAndSupportView extends StatelessWidget {
  const HelpAndSupportView({super.key});

  static const String supportEmail = 'alex04schi@gmail.com';

  static const List<HelpFaqCategory> _categories = [
    HelpFaqCategory(
      title: 'Primeiros Passos',
      items: [
        HelpFaqItem(
          icon: Icons.person_outline_rounded,
          question: 'Como completar meu perfil para entrar em uma rota?',
          answer:
              'Acesse Configurações > Perfil e preencha seu Nome, CPF, Telefone e Data de Nascimento. Caso você atue como motorista, preencha também o número da sua CNH. O CPF e o telefone são indispensáveis para que as empresas identifiquem seu vínculo.',
        ),
        HelpFaqItem(
          icon: Icons.pin_drop_outlined,
          question: 'Como definir meu Endereço e Ponto de Embarque?',
          answer:
              'Vá em Configurações > Endereço e Pontos de Parada. Informe seu endereço residencial ou selecione diretamente no mapa o local exato onde você aguarda o veículo (Ponto de Embarque) e o seu destino (Ponto de Desembarque). Esses pontos são usados pelo motorista para calcular a ordem das paradas e o tempo estimado de chegada (ETA).',
        ),
      ],
    ),
    HelpFaqCategory(
      title: 'Rotas e Embarque',
      items: [
        HelpFaqItem(
          icon: Icons.alt_route_rounded,
          question: 'Como encontrar e solicitar entrada em uma rota?',
          answer:
              'Na aba de Rotas, pesquise pela empresa ou destino desejado e toque em "Solicitar Entrada". O CEO ou Gerente da empresa receberá seu pedido e, assim que aprovado, a rota ficará disponível na sua tela inicial.',
        ),
        HelpFaqItem(
          icon: Icons.calendar_month_outlined,
          question: 'Como funciona a confirmação de presença (Ida e Volta)?',
          answer:
              'Por padrão, sua presença diária nos dias de operação da rota já fica confirmada automaticamente. Caso você não vá utilizar o transporte em algum dia ou trecho específico, basta abrir a rota, selecionar a data no calendário e desmarcar "Vou na Ida" ou "Vou na Volta".',
        ),
        HelpFaqItem(
          icon: Icons.hail_rounded,
          question: 'Para que serve o botão "Estou pronto para o embarque"?',
          answer:
              'Quando estiver no ponto aguardando o veículo, ative a opção "Estou pronto para o embarque". O motorista verá um indicador em tempo real na lista de paradas confirmando que você já está posicionado no local.',
        ),
      ],
    ),
    HelpFaqCategory(
      title: 'Viagens e Notificações',
      items: [
        HelpFaqItem(
          icon: Icons.location_searching_rounded,
          question: 'Como acompanhar a localização do motorista e os alertas?',
          answer:
              'Assim que o motorista inicia a viagem, você recebe um aviso de "Viagem Iniciada" e pode acompanhar o deslocamento em tempo real. O sistema calcula a distância até o seu ponto e envia alertas automáticos quando faltarem aproximadamente 30, 20, 10 e 5 minutos, além de avisar quando a van chegar ao seu ponto.',
        ),
        HelpFaqItem(
          icon: Icons.directions_bus_outlined,
          question: 'O que acontece se houver mais passageiros que assentos?',
          answer:
              'Quando o número de passageiros confirmados no dia ultrapassa a capacidade do veículo, o sistema escalona a operação automaticamente dividindo a rota em grupos (ex: Van 1, Van 2). O seu card da viagem indicará em qual grupo você foi alocado.',
        ),
      ],
    ),
    HelpFaqCategory(
      title: 'Motorista e Empresas',
      items: [
        HelpFaqItem(
          icon: Icons.play_circle_outline_rounded,
          question: 'Como iniciar, conduzir e finalizar uma viagem?',
          answer:
              'Na rota em que você está escalado como Motorista, toque em "Iniciar Viagem". Mantenha o compartilhamento de localização ativo para atualizar o ETA dos passageiros. Conforme passar pelos pontos, marque cada parada como concluída e, ao chegar ao destino final, toque em "Finalizar Viagem".',
        ),
        HelpFaqItem(
          icon: Icons.badge_outlined,
          question: 'Onde vejo as empresas vinculadas e o meu cargo?',
          answer:
              'Em Configurações > Empresas Vinculadas, você visualiza todas as empresas às quais está conectado, com uma etiqueta indicando se você atua como CEO, Gerente, Motorista ou Passageiro. Toque no card da empresa para abrir a página principal dela.',
        ),
        HelpFaqItem(
          icon: Icons.domain_add_rounded,
          question: 'Como cadastrar uma empresa, veículos e gerentes?',
          answer:
              'Em Configurações > Cadastrar Empresa, informe os dados e o CNPJ. Como CEO ou Gerente, acesse o painel da empresa para cadastrar os veículos da frota (placa, modelo e capacidade de lugares), criar rotas, aprovar passageiros e promover membros aos cargos de Gerente ou Motorista.',
        ),
        HelpFaqItem(
          icon: Icons.star_outline_rounded,
          question: 'Como funcionam as avaliações das empresas?',
          answer:
              'Logo após concluir sua primeira viagem em uma empresa, o aplicativo exibirá um convite para você avaliar o serviço de 1 a 5 estrelas e deixar um comentário opcional. Você também pode visualizar ou atualizar sua nota a qualquer momento na página da empresa.',
        ),
      ],
    ),
  ];

  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (MapEntry<String, String> e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }

  Future<void> _openEmailApp(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: _encodeQueryParameters(<String, String>{
        'subject': 'Suporte Índigo - Dúvida / Ajuda',
        'body': 'Olá, preciso de ajuda com o aplicativo Índigo:\n\n',
      }),
    );

    try {
      final launched = await launchUrl(
        emailLaunchUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        final fallback = await launchUrl(
          emailLaunchUri,
          mode: LaunchMode.platformDefault,
        );
        if (!fallback && context.mounted) {
          _copyEmail(context);
        }
      }
    } catch (_) {
      if (context.mounted) {
        _copyEmail(context);
      }
    }
  }

  void _copyEmail(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: supportEmail));

    final messenger = ScaffoldMessenger.of(context);
    // Remove qualquer SnackBar anterior para não empilhar vários cliques seguidos
    messenger.clearSnackBars();

    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'E-mail copiado para a área de transferência!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(0xFF16A34A), // Verde sólido
        behavior: SnackBarBehavior.fixed, // Cobre toda a largura inferior
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        duration: Duration(seconds: 2),
      ),
    );
  }

  ImageProvider _resolveProfileImage(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return NetworkImage(pathOrUrl);
    }
    return AssetImage(pathOrUrl);
  }

  BoxDecoration _accountStyleDecoration(ThemeData theme) {
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    double topPadding = 20,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPadding, 20, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Ajuda e Suporte',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Topo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: _accountStyleDecoration(theme),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: colorScheme.surface,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Guia Completo do Aplicativo',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Toque nas opções abaixo para abrir o passo a passo de cada funcionalidade.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Container Principal das Dúvidas
            Container(
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: _accountStyleDecoration(theme),
              child: Column(
                children: [
                  for (int cIndex = 0;
                      cIndex < _categories.length;
                      cIndex++) ...[
                    _buildSectionTitle(
                      context,
                      _categories[cIndex].title,
                      topPadding: cIndex == 0 ? 12 : 20,
                    ),
                    for (int iIndex = 0;
                        iIndex < _categories[cIndex].items.length;
                        iIndex++) ...[
                      HelpQuestionOption(
                        icon: _categories[cIndex].items[iIndex].icon,
                        question: _categories[cIndex].items[iIndex].question,
                        answer: _categories[cIndex].items[iIndex].answer,
                      ),
                      const SizedBox(height: 4),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rodapé de Contato
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: _accountStyleDecoration(theme),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: _resolveProfileImage(AppAssets.perfil),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Qualquer dúvida, entre em contato com o suporte',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => _openEmailApp(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 18,
                              color: colorScheme.onSurface,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                supportEmail,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),
                            InkWell(
                              onTap: () => _copyEmail(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.copy_rounded,
                                  size: 17,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
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