import 'package:flutter/material.dart';
import '../../../domain/models/company_entity.dart';

class CompanyRequestsHeaderCard extends StatelessWidget {
  final CompanyModel company;
  final String formattedCnpj;
  final int totalPendingCount;
  final Color borderColor;
  final Color mutedSurface;

  const CompanyRequestsHeaderCard({
    super.key,
    required this.company,
    required this.formattedCnpj,
    required this.totalPendingCount,
    required this.borderColor,
    required this.mutedSurface,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasLogo =
        company.logoUrl != null && company.logoUrl!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 60,
              height: 60,
              child: hasLogo
                  ? Image.network(
                      company.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: mutedSurface,
                        child: Icon(
                          Icons.domain_rounded,
                          color: colorScheme.onSurface,
                          size: 28,
                        ),
                      ),
                    )
                  : Container(
                      color: mutedSurface,
                      child: Icon(
                        Icons.domain_rounded,
                        color: colorScheme.onSurface,
                        size: 28,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'CNPJ: $formattedCnpj',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: totalPendingCount > 0
                        ? const Color(0xFFD97706)
                        : const Color(0xFF15803D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    totalPendingCount == 0
                        ? 'Tudo em dia'
                        : '$totalPendingCount${totalPendingCount == 1 ? ' solicitação aguardando' : ' solicitações aguardando'}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
}