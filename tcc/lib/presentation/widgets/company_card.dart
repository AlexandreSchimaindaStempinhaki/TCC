import 'package:flutter/material.dart';
import '../../domain/models/company_entity.dart';

class CompanyCard extends StatelessWidget {
  final CompanyModel company;
  final VoidCallback onTap;

  const CompanyCard({
    super.key,
    required this.company,
    required this.onTap,
  });

  String _formatCnpj(String cnpj) {
    final digits = cnpj.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 14) return cnpj;
    return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.${digits.substring(5, 8)}/${digits.substring(8, 12)}-${digits.substring(12, 14)}';
  }

  String _formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7, 11)}';
    } else if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6, 10)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasLogo = company.logoUrl != null && company.logoUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Dismissible(
        key: ValueKey(company.cnpj),
        direction: DismissDirection.horizontal,
        // Arrastar para a DIREITA (startToEnd) -> Excluir
        background: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
              SizedBox(width: 8),
              Text(
                'Excluir',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        // Arrastar para a ESQUERDA (endToStart) -> Editar
        secondaryBackground: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Editar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.edit_outlined, color: Colors.white, size: 28),
            ],
          ),
        ),
        child: Material(
          color: theme.cardColor,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        hasLogo
                            ? Image.network(
                                company.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: colorScheme.primaryContainer
                                      .withOpacity(0.3),
                                  child: Icon(
                                    Icons.domain_rounded,
                                    size: 56,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primaryContainer
                                          .withOpacity(0.5),
                                      colorScheme.surfaceContainerHighest
                                          .withOpacity(0.5),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Icon(
                                  Icons.domain_rounded,
                                  size: 64,
                                  color: colorScheme.primary,
                                ),
                              ),
                        // Gradiente sutil de sobreposição na base do banner para transição limpa
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.06),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                company.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  company.rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'CNPJ: ${_formatCnpj(company.cnpj)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}