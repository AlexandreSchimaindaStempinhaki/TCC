import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../domain/models/company_entity.dart';
import '../../../widgets/animated_three_dots.dart';
import '../../../widgets/company_review_card.dart';
import '../../mixins/company_reviews_logic.dart';

class CompanyReviewsView extends StatefulWidget {
  final CompanyModel? company;

  const CompanyReviewsView({super.key, this.company});

  @override
  State<CompanyReviewsView> createState() => _CompanyReviewsViewState();
}

class _CompanyReviewsViewState extends State<CompanyReviewsView>
    with CompanyReviewsMixin {
  Color _barColorForStar(int star) {
    switch (star) {
      case 5:
        return const Color(0xFF57BB8A);
      case 4:
        return const Color(0xFF9ACE6A);
      case 3:
        return const Color(0xFFFFCF02);
      case 2:
        return const Color(0xFFFF9F02);
      default:
        return const Color(0xFFFF6F31);
    }
  }

  Widget _buildSummaryHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final distribution = ratingDistribution;
    final totalCount = totalReviewsCount;
    final avg = averageRating;
    final avgFormatted = avg.toStringAsFixed(1).replaceAll('.', ',');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.22 : 0.04,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 112,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  avgFormatted,
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w300,
                    height: 1.05,
                    color: colorScheme.onSurface,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    IconData iconData;
                    if (avg >= starValue) {
                      iconData = Icons.star_rounded;
                    } else if (avg >= starValue - 0.5) {
                      iconData = Icons.star_half_rounded;
                    } else {
                      iconData = Icons.star_rounded;
                    }
                    final isColored = avg >= starValue - 0.5;
                    return Icon(
                      iconData,
                      size: 18,
                      color: isColored
                          ? Colors.amber.shade700
                          : colorScheme.onSurfaceVariant.withOpacity(0.28),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Total: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Icon(
                      Icons.person_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$totalCount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [5, 4, 3, 2, 1].map((star) {
                final count = distribution[star] ?? 0;
                final ratio = allReviews.isNotEmpty
                    ? count / allReviews.length
                    : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        child: Text(
                          '$star',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            height: 12,
                            color: colorScheme.onSurface.withOpacity(0.07),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: count == 0
                                  ? 0.0
                                  : ratio.clamp(0.05, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _barColorForStar(star),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filters = <int?>[null, 5, 4, 3, 2, 1];
    final activeFilter = selectedStarFilter.value;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final star = filters[index];
          final isSelected = activeFilter == star;

          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setStarFilter(star),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : theme.dividerColor.withOpacity(0.6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (star != null) ...[
                    Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: isSelected ? Colors.white : Colors.amber.shade700,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    star == null
                        ? 'Todas (${allReviews.length})'
                        : '$star estrelas',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Watch((context) {
      final isLoading =
          companyViewModel.fetchCompanyReviewsCommand.isExecuting.value;
      final canRate = canCurrentUserRate;
      final reviews = filteredReviews;
      final company = targetCompany;
      final companyName = company?.name ?? 'Avaliações da Empresa';
      final userReview = currentUserReview;
      final activeFilter = selectedStarFilter.value;

      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
            onPressed: () => handleBack(context),
          ),
          title: Column(
            children: [
              Text(
                'Avaliações e Feedbacks',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              if (company != null)
                Text(
                  companyName,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          centerTitle: true,
          actions: [
            if (canRate)
              IconButton(
                tooltip: userReview != null
                    ? 'Editar minha avaliação'
                    : 'Avaliar empresa',
                icon: Icon(
                  userReview != null
                      ? Icons.rate_review_rounded
                      : Icons.add_comment_rounded,
                  color: colorScheme.onSurface,
                  size: 22,
                ),
                onPressed: () => openRateCompanyBottomSheet(context),
              ),
          ],
        ),
        body: isLoading && allReviews.isEmpty
            ? Center(child: AnimatedThreeDots(color: colorScheme.onSurface))
            : RefreshIndicator(
                color: colorScheme.onSurface,
                onRefresh: refreshReviews,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryHeader(context),
                      const SizedBox(height: 16),
                      _buildFilterChips(context),
                      const SizedBox(height: 18),
                      if (reviews.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: theme.dividerColor.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.star_border_rounded,
                                size: 44,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                activeFilter == null
                                    ? 'Nenhuma avaliação registrada ainda'
                                    : 'Nenhuma avaliação com $activeFilter estrelas',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              if (activeFilter == null && canRate) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Seja o primeiro a avaliar o serviço desta empresa.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: reviews.length,
                          itemBuilder: (context, index) {
                            final review = reviews[index];
                            return CompanyReviewCard(
                              key: ValueKey('${review.userId}_$index'),
                              review: review,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
      );
    });
  }
}