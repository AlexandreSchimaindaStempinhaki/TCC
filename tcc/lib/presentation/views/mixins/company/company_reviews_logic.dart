import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../domain/models/company_entity.dart';
import '../../../../domain/models/company_review_entity.dart';
import '../../../../domain/models/user_entity.dart';
import '../../../controllers/company/company_viewmodel.dart';
import '../../../controllers/company_member/company_member_viewmodel.dart';
import '../../../controllers/route/route_list_viewmodel.dart';
import '../../../controllers/user/user_viewmodel.dart';
import '../../application/company/company_reviews_view.dart';

mixin CompanyReviewsMixin on State<CompanyReviewsView> {
  late final CompanyViewModel companyViewModel;
  late final UserViewModel userViewModel;
  late final RouteListViewModel routeListViewModel;
  late final CompanyMemberViewModel companyMemberViewModel;

  final selectedStarFilter = signal<int?>(null);
  final isCompanyPassenger = signal<bool>(false);
  final isCheckingEligibility = signal<bool>(true);

  String _cleanDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  CompanyModel? get targetCompany {
    final selected = companyViewModel.state.selectedCompany.value;
    final initial = widget.company;
    if (selected != null && initial != null) {
      if (_cleanDigits(selected.cnpj) == _cleanDigits(initial.cnpj)) {
        return selected;
      }
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

  Set<String> _allCurrentUserIdentifiers() {
    final ids = <String>{};
    final currentUser = userViewModel.state.user.value;
    if (currentUser == null) return ids;

    if (currentUser.uid.trim().isNotEmpty) {
      ids.add(currentUser.uid.trim());
    }

    final cpf = currentUser.cpf;
    if (cpf != null && cpf.trim().isNotEmpty) {
      ids.add(cpf.trim());
      final cleanCpf = _cleanDigits(cpf);
      if (cleanCpf.isNotEmpty) ids.add(cleanCpf);
    }

    if (currentUser.email.trim().isNotEmpty) {
      ids.add(currentUser.email.trim());
      ids.add(currentUser.email.trim().toLowerCase());
    }

    return ids;
  }

  bool _matchesUser(String? rawId, Set<String> userIds) {
    if (rawId == null) return false;
    final trimmed = rawId.trim();
    if (trimmed.isEmpty) return false;
    final cleaned = _cleanDigits(trimmed);
    return userIds.contains(trimmed) ||
        userIds.contains(trimmed.toLowerCase()) ||
        (cleaned.length == 11 && userIds.contains(cleaned));
  }

  bool _matchesUserModel(UserModel? user, Set<String> userIds) {
    if (user == null) return false;
    return _matchesUser(user.uid, userIds) ||
        _matchesUser(user.cpf, userIds) ||
        _matchesUser(user.email, userIds);
  }

  CompanyReviewModel? get currentUserReview {
    final userIds = _allCurrentUserIdentifiers();
    if (userIds.isEmpty) return null;

    for (final review in allReviews) {
      if (_matchesUser(review.userId, userIds)) {
        return review;
      }
    }
    return null;
  }

  /// Apenas passageiros vinculados à empresa (que não sejam dono, gerente ou motorista) podem avaliar.
  bool get canCurrentUserRate {
    if (isCheckingEligibility.value) return false;
    final currentUser = userViewModel.state.user.value;
    final comp = targetCompany;
    if (currentUser == null || comp == null) return false;
    return isCompanyPassenger.value;
  }

  @override
  void initState() {
    super.initState();
    companyViewModel = injector.get<CompanyViewModel>();
    userViewModel = injector.get<UserViewModel>();
    routeListViewModel = injector.get<RouteListViewModel>();
    companyMemberViewModel = injector.get<CompanyMemberViewModel>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      refreshReviews();
    });
  }

  @override
  void dispose() {
    selectedStarFilter.dispose();
    isCompanyPassenger.dispose();
    isCheckingEligibility.dispose();
    super.dispose();
  }

  Future<void> refreshReviews() async {
    final comp = targetCompany;
    final cnpj = comp?.cnpj.trim() ?? '';

    await Future.wait([
      if (cnpj.isNotEmpty) companyViewModel.commands.fetchCompanyReviews(cnpj),
      _checkPassengerEligibility(),
    ]);
  }

  Future<void> _checkPassengerEligibility() async {
    isCheckingEligibility.value = true;
    isCompanyPassenger.value = false;

    try {
      try {
        await userViewModel.commands.fetchUser().timeout(
          const Duration(seconds: 6),
        );
      } catch (_) {}

      if (!mounted) return;

      final comp = targetCompany;
      final userIds = _allCurrentUserIdentifiers();
      if (comp == null || userIds.isEmpty) return;

      // Dono da empresa nunca avalia a própria empresa
      if (_matchesUser(comp.ownerId, userIds)) {
        isCompanyPassenger.value = false;
        return;
      }

      final cleanCnpj = _cleanDigits(comp.cnpj);

      // Carrega rotas e membros da empresa via ViewModels -> Services
      await Future.wait([
        if (cleanCnpj.isNotEmpty)
          routeListViewModel.commands
              .fetchRoutesByCompany(cleanCnpj)
              .timeout(const Duration(seconds: 6))
              .catchError((_) {}),
        companyMemberViewModel.commands
            .loadCompanyMembersDetailed(comp)
            .timeout(const Duration(seconds: 6))
            .catchError((_) {}),
      ]);

      if (!mounted) return;

      final owners = companyMemberViewModel.state.ownersList.value;
      final managers = companyMemberViewModel.state.managersList.value;
      final drivers = companyMemberViewModel.state.driversList.value;
      final passengers = companyMemberViewModel.state.passengersList.value;

      final companyRoutes = routeListViewModel.state.companyRoutes.value
          .where((r) => _cleanDigits(r.companyCnpj) == cleanCnpj)
          .toList();

      final isStaff =
          owners.any((m) => _matchesUserModel(m.userModel, userIds)) ||
          managers.any((m) => _matchesUserModel(m.userModel, userIds)) ||
          drivers.any((m) => _matchesUserModel(m.userModel, userIds)) ||
          companyRoutes.any((r) => userIds.any((id) => r.isUserDriver(id)));

      if (isStaff) {
        isCompanyPassenger.value = false;
        return;
      }

      final isPassengerInRoute = companyRoutes.any(
        (r) => userIds.any((id) => r.isUserPassenger(id)),
      );
      final isPassengerMember = passengers.any(
        (m) => _matchesUserModel(m.userModel, userIds),
      );

      isCompanyPassenger.value = isPassengerInRoute || isPassengerMember;
    } finally {
      if (mounted) {
        isCheckingEligibility.value = false;
      }
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
    if (!mounted || !context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
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
        duration: const Duration(seconds: 3),
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

    if (!canCurrentUserRate) {
      _showFeedbackSnackBar(
        context,
        'Apenas passageiros vinculados a esta empresa podem avaliá-la.',
        isError: true,
      );
      return;
    }

    final existing = currentUserReview;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _RateCompanyBottomSheet(
        companyName: comp.name,
        existingReview: existing,
        onSubmit: (stars, description) async {
          final cleanCpf = _cleanDigits(currentUser.cpf ?? '');
          final userId =
              cleanCpf.isNotEmpty ? cleanCpf : currentUser.uid.trim();
          if (userId.isEmpty) return false;

          final cleanCnpj = _cleanDigits(comp.cnpj);
          final targetCnpj =
              cleanCnpj.isNotEmpty ? cleanCnpj : comp.cnpj.trim();
          final displayName = currentUser.name.trim().isNotEmpty
              ? currentUser.name.trim()
              : 'Passageiro';

          return companyViewModel.commands.rateCompany(
            cnpj: targetCnpj,
            userId: userId,
            userName: displayName,
            userPhotoUrl: currentUser.photoUrl,
            rating: stars.toDouble(),
            description: description,
          );
        },
      ),
    );

    if (!mounted || !context.mounted || submitted == null) return;

    if (submitted) {
      final cnpj = comp.cnpj.trim();
      if (cnpj.isNotEmpty) {
        await companyViewModel.commands.fetchCompanyReviews(cnpj);
      }
      if (!mounted || !context.mounted) return;
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

class _RateCompanyBottomSheet extends StatefulWidget {
  final String companyName;
  final CompanyReviewModel? existingReview;
  final Future<bool> Function(int stars, String? description) onSubmit;

  const _RateCompanyBottomSheet({
    required this.companyName,
    required this.existingReview,
    required this.onSubmit,
  });

  @override
  State<_RateCompanyBottomSheet> createState() =>
      _RateCompanyBottomSheetState();
}

class _RateCompanyBottomSheetState extends State<_RateCompanyBottomSheet> {
  late int _selectedStars;
  late final TextEditingController _commentController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedStars = widget.existingReview != null
        ? widget.existingReview!.rating.round().clamp(1, 5)
        : 5;
    _commentController = TextEditingController(
      text: widget.existingReview?.description ?? '',
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      final trimmed = _commentController.text.trim();
      final success = await widget.onSubmit(
        _selectedStars,
        trimmed.isEmpty ? null : trimmed,
      );
      if (!mounted) return;
      Navigator.of(context).pop(success);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.existingReview != null;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
            isEditing
                ? 'Editar sua Avaliação'
                : 'Avaliar ${widget.companyName}',
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
                final isFilled = starValue <= _selectedStars;
                return IconButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => setState(() => _selectedStars = starValue),
                  iconSize: 38,
                  icon: Icon(
                    Icons.star_rounded,
                    color: isFilled
                        ? Colors.amber.shade700
                        : colorScheme.onSurfaceVariant.withOpacity(0.28),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            enabled: !_isSubmitting,
            maxLines: 4,
            maxLength: 400,
            style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
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
                borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
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
              onPressed: _isSubmitting ? null : _handleSubmit,
              child: Text(
                _isSubmitting
                    ? 'Enviando...'
                    : (isEditing ? 'Atualizar Avaliação' : 'Publicar Avaliação'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}