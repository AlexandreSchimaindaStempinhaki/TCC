import 'package:flutter/material.dart';
import '../../domain/models/company_entity.dart';

class LinkedCompanyCard extends StatelessWidget {
  final CompanyModel company;
  final String role;
  final VoidCallback? onTap;

  const LinkedCompanyCard({
    super.key,
    required this.company,
    required this.role,
    this.onTap,
  });

  String _formatCnpj(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 14) return raw;
    return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.${digits.substring(5, 8)}/${digits.substring(8, 12)}-${digits.substring(12)}';
  }

  String _formatPhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return raw;

    // Remove o DDI +55 caso esteja salvo junto com o número
    if (digits.length > 11 && digits.startsWith('55')) {
      digits = digits.substring(2);
    }

    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    } else if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    } else if (digits.length == 9) {
      return '${digits.substring(0, 5)}-${digits.substring(5)}';
    } else if (digits.length == 8) {
      return '${digits.substring(0, 4)}-${digits.substring(4)}';
    }
    return raw;
  }

  _RoleBadgeStyle _getRoleBadgeStyle(String role, ColorScheme colorScheme) {
    switch (role) {
      case 'CEO':
        return const _RoleBadgeStyle(
          backgroundColor: Color(0xFFD97706), // Âmbar sólido/fosco
          textColor: Colors.white,
        );
      case 'Gerente':
        return const _RoleBadgeStyle(
          backgroundColor: Color(0xFF7C3AED), // Roxo sólido/fosco
          textColor: Colors.white,
        );
      case 'Motorista':
        return const _RoleBadgeStyle(
          backgroundColor: Color(0xFF0D9488), // Teal sólido/fosco
          textColor: Colors.white,
        );
      default: // Passageiro
        return _RoleBadgeStyle(
          backgroundColor: colorScheme.primary, // Cor primária sólida
          textColor: colorScheme.onPrimary,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final roleStyle = _getRoleBadgeStyle(role, colorScheme);

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Logo da Empresa
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.4),
                  ),
                  image: (company.logoUrl != null &&
                          company.logoUrl!.trim().isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(company.logoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (company.logoUrl == null ||
                        company.logoUrl!.trim().isEmpty)
                    ? Icon(
                        Icons.directions_bus_filled_rounded,
                        color: colorScheme.primary,
                        size: 30,
                      )
                    : null,
              ),
              const SizedBox(width: 14),

              // Informações da Empresa + Badge de Cargo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            company.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Badge de Cargo Preenchida/Fosca e Sem Ícone
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: roleStyle.backgroundColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            role,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: roleStyle.textColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'CNPJ: ${_formatCnpj(company.cnpj)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          company.rating > 0
                              ? '${company.rating.toStringAsFixed(1)} (${company.ratingCount})'
                              : 'Sem avaliações',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (company.phone.trim().isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatPhone(company.phone),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleBadgeStyle {
  final Color backgroundColor;
  final Color textColor;

  const _RoleBadgeStyle({
    required this.backgroundColor,
    required this.textColor,
  });
}