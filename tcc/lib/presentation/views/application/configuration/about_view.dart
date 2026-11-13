import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tcc/core/routes/indigo_routes.dart';

import '../../../../core/constants/app_assets.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  Widget _buildInfoRow(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),

                Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
          onPressed: () => context.pushNamed(IndigoRouteNames.account),
        ),
        title: Text(
          'Sobre o Aplicativo',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          children: [
            // HEADER COM LOGO E NOME DO APP
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceTint,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                AppAssets.logo,
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Índigo',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Versão 1.0.0',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Projeto Acadêmico',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Este aplicativo foi desenvolvido como Trabalho de Conclusão de Curso (TCC) focado em gestão de transporte contratual.',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),

                  Center(
                    child: Column(
                      children: [
                        SizedBox(height: 24),
                        Container(
                          width: 200,
                          height: 200,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceTint,
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            AppAssets.perfil,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Alexandre Schimainda Stempinhaki',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Desenvolvedor',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildInfoRow(
                    context,
                    title: 'Curso',
                    subtitle: 'Técnico em Informática',
                  ),
                  _buildInfoRow(
                    context,
                    title: 'Instituição',
                    subtitle: 'Instituto Federal do Paraná (IFPR)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // RODAPÉ / COPYRIGHT
            Text(
              '© ${DateTime.now().year} Índigo App. Todos os direitos reservados.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
