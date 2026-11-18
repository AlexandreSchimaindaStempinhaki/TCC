import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../domain/models/company_entity.dart';
import '../../../domain/models/company_review_entity.dart';
import '../../controllers/company/company_viewmodel.dart';
import '../../controllers/user/user_viewmodel.dart';
import '../application/company/company_reviews_view.dart';

mixin CompanyReviewsMixin on State<CompanyReviewsView> {
  late final CompanyViewModel companyViewModel;
  late final UserViewModel userViewModel;

  final selectedStarFilter = signal<int?>(null);

  CompanyModel? get targetCompany {
    final selected = companyViewModel.state.selectedCompany.value;
    final initial = widget.company;
    if (selected != null && initial != null) {
      final cleanSelected = selected.cnpj.replaceAll(RegExp(r'\D'), '');
      final cleanInitial = initial.cnpj.replaceAll(RegExp(r'\D'), '');
      if (cleanSelected == cleanInitial) return selected;
    }
    return initial ?? selected;
  }

  List<CompanyReviewModel> get allReviews =>
      companyViewModel.state.companyReviews.value;

  List<CompanyReviewModel> get filteredReviews {
    final filter = selectedStarFilter.value;
    if (filter == null) return allReviews;
    return allReviews
        .where((r) => r.rating.round().clamp(1, 5) == filter)
        .toList();
  }

  double get averageRating {
    final reviews = allReviews;
    if (reviews.isNotEmpty) {
      final sum = reviews.fold<double>(0.0, (acc, r) => acc + r.rating);
      return sum / reviews.length;
    }
    final comp = targetCompany;
    if (comp != null && comp.ratingCount > 0) {
      return comp.rating;
    }
    return 0.0;
  }

  int get totalReviewsCount {
    final reviews = allReviews;
    if (reviews.isNotEmpty) return reviews.length;
    return targetCompany?.ratingCount ?? 0;
  }

  Map<int, int> get ratingDistribution {
    final counts = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final review in allReviews) {
      final star = review.rating.round().clamp(1, 5);
      counts[star] = (counts[star] ?? 0) + 1;
    }
    return counts;
  }

  CompanyReviewModel? get currentUserReview {
    final currentUser = userViewModel.state.user.value;
    if (currentUser == null) return null;

    final uid = currentUser.uid.trim();
    final cpf = (currentUser.cpf ?? '').replaceAll(RegExp(r'\D'), '');

    for (final review in allReviews) {
      final rUserId = review.userId.trim();
      final rClean = rUserId.replaceAll(RegExp(r'\D'), '');
      if (rUserId == uid || (cpf.isNotEmpty && rClean == cpf)) {
        return review;
      }
    }
    return null;
  }

  bool get canCurrentUserRate {
    final currentUser = userViewModel.state.user.value;
    final comp = targetCompany;
    if (currentUser == null || comp == null) return false;

    final uid = currentUser.uid.trim();
    final cpf = (currentUser.cpf ?? '').replaceAll(RegExp(r'\D'), '');
    final ownerClean = comp.ownerId.replaceAll(RegExp(r'\D'), '');

    // Dono da empresa não avalia a própria empresa
    if (comp.ownerId.trim() == uid ||
        (cpf.isNotEmpty && ownerClean == cpf)) {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    companyViewModel = injector.get<CompanyViewModel>();
    userViewModel = injector.get<UserViewModel>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshReviews();
    });
  }

  @override
  void dispose() {
    selectedStarFilter.dispose();
    super.dispose();
  }

  Future<void> refreshReviews() async {
    final cnpj = targetCompany?.cnpj ?? '';
    if (cnpj.trim().isNotEmpty) {
      await companyViewModel.commands.fetchCompanyReviews(cnpj);
    }
  }

  void setStarFilter(int? star) {
    selectedStarFilter.value = star;
  }

  void handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    }
  }

  String formatReviewDate(DateTime date) {
    const months = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;
    return '$day de $month de $year';
  }

  void _showFeedbackSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor:
            isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.fixed,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> openRateCompanyBottomSheet(BuildContext context) async {
    final comp = targetCompany;
    final currentUser = userViewModel.state.user.value;

    if (comp == null || currentUser == null) {
      _showFeedbackSnackBar(
        context,
        'Faça login para avaliar esta empresa.',
        isError: true,
      );
      return;
    }

    final existing = currentUserReview;
    int selectedStars = existing != null
        ? existing.rating.round().clamp(1, 5)
        : 5;
    final commentController = TextEditingController(
      text: existing?.description ?? '',
    );

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colorScheme = theme.colorScheme;

        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    existing != null
                        ? 'Editar sua Avaliação'
                        : 'Avaliar ${comp.name}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Toque nas estrelas para definir sua nota e conte como foi sua experiência.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        final isFilled = starValue <= selectedStars;
                        return IconButton(
                          onPressed: () {
                            setModalState(() {
                              selectedStars = starValue;
                            });
                          },
                          iconSize: 38,
                          icon: Icon(
                            Icons.star_rounded,
                            color: isFilled
                                ? Colors.amber.shade700
                                : colorScheme.onSurfaceVariant.withOpacity(
                                    0.28,
                                  ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    maxLength: 400,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Escreva um comentário sobre pontualidade, veículos e atendimento (opcional)...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      filled: true,
                      fillColor: theme.scaffoldBackgroundColor.withOpacity(0.6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: theme.dividerColor.withOpacity(0.6),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Watch((_) {
                    final isSaving = companyViewModel
                        .rateCompanyCommand
                        .isExecuting
                        .value;

                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                final cleanCpf = (currentUser.cpf ?? '')
                                    .replaceAll(RegExp(r'\D'), '');
                                final userId = cleanCpf.isNotEmpty
                                    ? cleanCpf
                                    : currentUser.uid.trim();

                                final success = await companyViewModel.commands
                                    .rateCompany(
                                      cnpj: comp.cnpj,
                                      userId: userId,
                                      userName: currentUser.name,
                                      userPhotoUrl: currentUser.photoUrl,
                                      rating: selectedStars.toDouble(),
                                      description:
                                          commentController.text.trim().isEmpty
                                          ? null
                                          : commentController.text.trim(),
                                    );

                                if (!sheetContext.mounted) return;
                                Navigator.of(sheetContext).pop(success);
                              },
                        child: Text(
                          isSaving
                              ? 'Enviando...'
                              : (existing != null
                                    ? 'Atualizar Avaliação'
                                    : 'Publicar Avaliação'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );

    commentController.dispose();

    if (!context.mounted || submitted == null) return;

    if (submitted) {
      _showFeedbackSnackBar(context, 'Avaliação enviada com sucesso!');
    } else {
      _showFeedbackSnackBar(
        context,
        companyViewModel.state.message.value ??
            'Não foi possível salvar sua avaliação.',
        isError: true,
      );
    }
  }
}