import 'package:flutter/material.dart';
import '../../domain/models/company_review_entity.dart';

class CompanyReviewCard extends StatefulWidget {
  final CompanyReviewModel review;
  final String? formattedDate;

  const CompanyReviewCard({
    super.key,
    required this.review,
    this.formattedDate,
  });

  @override
  State<CompanyReviewCard> createState() => _CompanyReviewCardState();
}

class _CompanyReviewCardState extends State<CompanyReviewCard> {
  bool _isExpanded = false;

  Widget _buildStarRow(int rating, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isFilled = index < rating;
        return Icon(
          Icons.star_rounded,
          size: 15,
          color: isFilled
              ? Colors.amber.shade700
              : colorScheme.onSurfaceVariant.withOpacity(0.28),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final userName = widget.review.userName.trim().isNotEmpty
        ? widget.review.userName.trim()
        : 'Passageiro';
    final userPhoto = widget.review.userPhotoUrl;
    final rating = widget.review.rating.round().clamp(1, 5);
    final comment = (widget.review.description ?? '').trim();
    final dateText = (widget.formattedDate ?? '').trim();

    final initial = userName[0].toUpperCase();
    final isLongComment = comment.length > 155;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.5),
        ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: colorScheme.primary.withOpacity(0.14),
                backgroundImage:
                    (userPhoto != null && userPhoto.trim().isNotEmpty)
                        ? NetworkImage(userPhoto.trim())
                        : null,
                child: (userPhoto == null || userPhoto.trim().isEmpty)
                    ? Text(
                        initial,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildStarRow(rating, colorScheme),
                        if (dateText.isNotEmpty)
                          Text(
                            dateText,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              maxLines: (_isExpanded || !isLongComment) ? null : 3,
              overflow: (_isExpanded || !isLongComment)
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: colorScheme.onSurface.withOpacity(0.9),
              ),
            ),
            if (isLongComment) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 30,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    side: BorderSide(
                      color: theme.dividerColor.withOpacity(0.7),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _isExpanded ? 'Mostrar menos' : 'Mostrar mais',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}