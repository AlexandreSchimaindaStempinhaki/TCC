import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../domain/models/boarding_entity.dart';
import '../../../../domain/models/company_entity.dart';
import '../../../../domain/models/route_entity.dart';
import '../../../controllers/boarding/boarding_list_viewmodel.dart';
import '../../../controllers/boarding/boarding_state_viewmodel.dart';
import '../../../controllers/boarding/boarding_viewmodel.dart';
import '../../../controllers/user/user_viewmodel.dart';
import '../../../widgets/animated_three_dots.dart';

enum DayAttendanceStatus {
  none,
  both,
  outboundOnly,
  returnOnly,
  absent,
}

class RouteAttendanceCalendarView extends StatefulWidget {
  final RouteModel route;
  final CompanyModel? company;
  final bool isStaff;

  const RouteAttendanceCalendarView({
    super.key,
    required this.route,
    this.company,
    this.isStaff = false,
  });

  @override
  State<RouteAttendanceCalendarView> createState() =>
      _RouteAttendanceCalendarViewState();
}

class _RouteAttendanceCalendarViewState
    extends State<RouteAttendanceCalendarView> {
  // Opcional: se preencher os meses (1 a 12), eles têm prioridade sobre o locale do app.
  static const Map<int, String> _monthNames = {
    // 1: '...',
  };

  static const List<String> _weekInitials = [
    'D',
    'S',
    'T',
    'Q',
    'Q',
    'S',
    'S',
  ];

  late final BoardingViewModel _boardingViewModel;
  late final BoardingListViewModel _boardingListViewModel;
  late final UserViewModel _userViewModel;

  late final Signal<DateTime> _focusedMonth;
  late final Signal<DateTime> _selectedDate;
  late final Signal _draftOverrides;
  late final Signal<bool> _isInitialLoading;
  late final Signal<bool> _isSaving;
  late final Signal<bool> _isLoadingStaffDay;

  @override
  void initState() {
    super.initState();
    _boardingViewModel = injector.get<BoardingViewModel>();
    _boardingListViewModel = injector.get<BoardingListViewModel>();
    _userViewModel = injector.get<UserViewModel>();

    final now = _normalizeDate(DateTime.now());
    _focusedMonth = signal(DateTime(now.year, now.month));
    _selectedDate = signal(now);
    _draftOverrides = signal(<String, DayAttendanceStatus>{});
    _isInitialLoading = signal(true);
    _isSaving = signal(false);
    _isLoadingStaffDay = signal(false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _focusedMonth.dispose();
    _selectedDate.dispose();
    _draftOverrides.dispose();
    _isInitialLoading.dispose();
    _isSaving.dispose();
    _isLoadingStaffDay.dispose();
    super.dispose();
  }

  String _cleanDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  String get _routeIdStr => widget.route.id.toString();

  String get _currentUserId {
    final loggedUser = _userViewModel.state.user.value;
    final cleanCpf = _cleanDigits(loggedUser?.cpf ?? '');
    if (cleanCpf.isNotEmpty) return cleanCpf;
    if (loggedUser != null && loggedUser.uid.trim().isNotEmpty) {
      return loggedUser.uid.trim();
    }
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  DateTime _normalizeDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  String _dateKey(DateTime dt) => BoardingState.formatDateKey(dt);

  String _formatDateBr(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  String _monthHeaderLabel(BuildContext context, DateTime dt) {
    final custom = _monthNames[dt.month]?.trim();
    if (custom != null && custom.isNotEmpty) {
      return '$custom ${dt.year}';
    }
    final formatted = MaterialLocalizations.of(context).formatMonthYear(dt);
    if (formatted.isEmpty) {
      final m = dt.month.toString().padLeft(2, '0');
      return '$m/${dt.year}';
    }
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  /// Gera um tom 100% opaco levemente mais escuro para destacar a caixa do ícone quando o botão está selecionado.
  Color _darkenSolid(Color color, [double amount = 0.12]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  DayAttendanceStatus _statusFromBoarding(BoardingModel boarding) {
    if (boarding.willGoOutbound && boarding.willGoReturn) {
      return DayAttendanceStatus.both;
    }
    if (boarding.willGoOutbound && !boarding.willGoReturn) {
      return DayAttendanceStatus.outboundOnly;
    }
    if (!boarding.willGoOutbound && boarding.willGoReturn) {
      return DayAttendanceStatus.returnOnly;
    }
    return DayAttendanceStatus.absent;
  }

  DayAttendanceStatus _resolveDisplayStatus(
    DateTime date,
    Map<String, BoardingModel> savedMap,
    Map<String, DayAttendanceStatus> drafts,
  ) {
    final key = _dateKey(date);
    if (drafts.containsKey(key)) {
      return drafts[key]!;
    }
    final saved = savedMap[key];
    if (saved != null) {
      return _statusFromBoarding(saved);
    }
    return DayAttendanceStatus.none;
  }

  Future<void> _loadInitialData() async {
    _isInitialLoading.value = true;
    try {
      if (_userViewModel.state.user.value == null) {
        await _userViewModel.commands.fetchUser();
      }
      await _loadMonthAttendance();
      if (widget.isStaff) {
        await _loadStaffSummaryForDate(_selectedDate.value);
      }
    } finally {
      if (mounted) {
        _isInitialLoading.value = false;
      }
    }
  }

  Future<void> _loadMonthAttendance() async {
    if (widget.isStaff) {
      await _loadStaffSummaryForDate(_selectedDate.value);
      return;
    }

    final uid = _currentUserId;
    if (uid.isEmpty) return;

    final focused = _focusedMonth.value;
    final startDate = DateTime(focused.year, focused.month, 1);
    final endDate = DateTime(focused.year, focused.month + 1, 0);

    await _boardingViewModel.commands.loadUserHistory(
      routeId: _routeIdStr,
      userId: uid,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<void> _loadStaffSummaryForDate(DateTime date) async {
    if (!widget.isStaff) return;
    _isLoadingStaffDay.value = true;
    try {
      await _boardingListViewModel.commands.fetchByRouteAndDate(
        routeId: _routeIdStr,
        date: _normalizeDate(date),
      );
    } finally {
      if (mounted) {
        _isLoadingStaffDay.value = false;
      }
    }
  }

  void _changeMonth(int delta) {
    final current = _focusedMonth.value;
    _focusedMonth.value = DateTime(current.year, current.month + delta);
    _loadMonthAttendance();
  }

  void _selectDate(DateTime date) {
    final normalized = _normalizeDate(date);
    _selectedDate.value = normalized;
    _boardingViewModel.state.selectedDate.value = normalized;
    if (widget.isStaff) {
      _loadStaffSummaryForDate(normalized);
    }
  }

  void _jumpToToday() {
    final today = _normalizeDate(DateTime.now());
    _focusedMonth.value = DateTime(today.year, today.month);
    _selectDate(today);
    _loadMonthAttendance();
  }

  void _selectStatusForCurrentDay(DayAttendanceStatus status) {
    final key = _dateKey(_selectedDate.value);
    final updated = Map<String, DayAttendanceStatus>.from(
      _draftOverrides.value,
    );
    if (status == DayAttendanceStatus.none) {
      updated.remove(key);
    } else {
      updated[key] = status;
    }
    _draftOverrides.value = updated;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
          backgroundColor: isError
              ? const Color(0xFFDC2626)
              : const Color(0xFF16A34A),
          behavior: SnackBarBehavior.fixed,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  Future<void> _saveSelectedDay() async {
    if (_isSaving.value) return;

    final uid = _currentUserId;
    if (uid.isEmpty) {
      _showSnackBar(
        'Não foi possível identificar o usuário logado.',
        isError: true,
      );
      return;
    }

    final date = _normalizeDate(_selectedDate.value);
    final status = _resolveDisplayStatus(
      date,
      _boardingViewModel.state.calendarMap.value,
      _draftOverrides.value,
    );

    if (status == DayAttendanceStatus.none) {
      _showSnackBar(
        'Selecione uma opção de presença antes de salvar.',
        isError: true,
      );
      return;
    }

    final willGoOutbound = status == DayAttendanceStatus.both ||
        status == DayAttendanceStatus.outboundOnly;
    final willGoReturn = status == DayAttendanceStatus.both ||
        status == DayAttendanceStatus.returnOnly;

    _isSaving.value = true;
    try {
      final ok = await _boardingViewModel.commands.updateAttendance(
        routeId: _routeIdStr,
        userId: uid,
        date: date,
        willGoOutbound: willGoOutbound,
        willGoReturn: willGoReturn,
      );

      if (!mounted) return;

      if (ok) {
        final key = _dateKey(date);
        if (_draftOverrides.value.containsKey(key)) {
          final cleaned = Map<String, DayAttendanceStatus>.from(
            _draftOverrides.value,
          )..remove(key);
          _draftOverrides.value = cleaned;
        }
        _showSnackBar(
          'Presença de ${_formatDateBr(date)} salva: ${_statusLabel(status)}',
        );
      } else {
        final err = _boardingViewModel.state.message.value ??
            'Não foi possível salvar sua presença.';
        _showSnackBar(err, isError: true);
      }
    } catch (e) {
      _showSnackBar('Erro ao salvar presença: $e', isError: true);
    } finally {
      if (mounted) {
        _isSaving.value = false;
      }
    }
  }

  Color _statusColor(DayAttendanceStatus status, ColorScheme colorScheme) {
    switch (status) {
      case DayAttendanceStatus.both:
        return const Color(0xFF16A34A);
      case DayAttendanceStatus.outboundOnly:
        return colorScheme.primary;
      case DayAttendanceStatus.returnOnly:
        return const Color(0xFFF59E0B);
      case DayAttendanceStatus.absent:
        return const Color(0xFFDC2626);
      case DayAttendanceStatus.none:
        return Colors.transparent;
    }
  }

  String _statusLabel(DayAttendanceStatus status) {
    switch (status) {
      case DayAttendanceStatus.both:
        return 'Ida e Volta';
      case DayAttendanceStatus.outboundOnly:
        return 'Somente Ida';
      case DayAttendanceStatus.returnOnly:
        return 'Somente Volta';
      case DayAttendanceStatus.absent:
        return 'Ausente';
      case DayAttendanceStatus.none:
        return 'Não definido';
    }
  }

  BoxDecoration _cardDecoration(ThemeData theme, {bool highlighted = true}) {
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(20),
      border: highlighted
          ? Border.all(
              color: isDark
                  ? colorScheme.onSurface.withOpacity(0.24)
                  : colorScheme.onSurface.withOpacity(0.16),
              width: 1.8,
            )
          : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.30 : 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildRouteThumb(String imageUrl, ColorScheme colorScheme) {
    Widget fallback() => Container(
          color: colorScheme.primary,
          alignment: Alignment.center,
          child: const Icon(
            Icons.directions_bus_rounded,
            size: 24,
            color: Colors.white,
          ),
        );

    if (imageUrl.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(width: 52, height: 52, child: fallback()),
      );
    }

    final img =
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback(),
              )
            : Image.file(
                File(imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback(),
              );

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(width: 52, height: 52, child: img),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final today = _normalizeDate(DateTime.now());

    final route = widget.route;
    final company = widget.company;

    final imageUrl =
        (route.imageUrl != null && route.imageUrl!.trim().isNotEmpty)
            ? route.imageUrl!.trim()
            : ((company?.logoUrl != null && company!.logoUrl!.trim().isNotEmpty)
                ? company.logoUrl!.trim()
                : '');

    final companyName = (company?.name.trim().isNotEmpty == true)
        ? company!.name.trim()
        : 'Transporte Contratual';

    final originText =
        (route.originName != null && route.originName!.trim().isNotEmpty)
            ? route.originName!.trim()
            : 'Partida';

    final destinationText = (route.destinationName != null &&
            route.destinationName!.trim().isNotEmpty)
        ? route.destinationName!.trim()
        : 'Destino';

    final operatingDaysText = route.operatingDaysLabel;

    return Watch((context) {
      final initialLoading = _isInitialLoading.value;
      final focused = _focusedMonth.value;
      final selected = _selectedDate.value;
      final savedMap = _boardingViewModel.state.calendarMap.value;
      final drafts = _draftOverrides.value;
      final saving = _isSaving.value;
      final loadingStaffDay = _isLoadingStaffDay.value;

      final firstDayOfMonth = DateTime(focused.year, focused.month, 1);
      final daysInMonth = DateTime(focused.year, focused.month + 1, 0).day;
      final leadingEmptySlots = firstDayOfMonth.weekday % 7;
      final totalCells = leadingEmptySlots + daysInMonth;

      final selectedStatus = _resolveDisplayStatus(
        selected,
        savedMap,
        drafts,
      );

      final hasUnsavedChange = drafts.containsKey(_dateKey(selected));

      final isViewingTodayMonth =
          focused.year == today.year && focused.month == today.month;

      // Métricas reais para o modo motorista/gestor
      final routeBoardings = _boardingListViewModel.state.routeBoardings.value;
      final outboundCount =
          _boardingListViewModel.state.confirmedOutboundList.value.length;
      final returnCount =
          _boardingListViewModel.state.confirmedReturnList.value.length;
      final absentCount = routeBoardings
          .where((b) => !b.willGoOutbound && !b.willGoReturn)
          .length;

      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: colorScheme.onSurface,
            ),
            onPressed: () {
              if (context.canPop()) context.pop();
            },
          ),
          title: Text(
            widget.isStaff ? 'Presenças da Rota' : 'Calendário de Presença',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: initialLoading
            ? Center(
                child: AnimatedThreeDots(color: colorScheme.onSurface),
              )
            : RefreshIndicator(
                color: colorScheme.onSurface,
                onRefresh: _loadMonthAttendance,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ================= 1. CARD RESUMO DA ROTA =================
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: _cardDecoration(theme),
                        child: Row(
                          children: [
                            _buildRouteThumb(imageUrl, colorScheme),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    companyName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '$originText → $destinationText',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w500,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Badge de dias de operação: 100% fosco, sem opacity
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      operatingDaysText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                      ),
                      const SizedBox(height: 16),

                      // ================= 2. CARD DO CALENDÁRIO MENSAL =================
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                        decoration: _cardDecoration(theme),
                        child: Column(
                          children: [
                            // Navegação de mês
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _MonthNavButton(
                                  icon: Icons.chevron_left_rounded,
                                  onTap: () => _changeMonth(-1),
                                  isDark: isDark,
                                  colorScheme: colorScheme,
                                ),
                                Text(
                                  _monthHeaderLabel(context, focused),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                _MonthNavButton(
                                  icon: Icons.chevron_right_rounded,
                                  onTap: () => _changeMonth(1),
                                  isDark: isDark,
                                  colorScheme: colorScheme,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Iniciais dos dias da semana
                            Row(
                              children: List.generate(_weekInitials.length, (i) {
                                final isWeekend = i == 0 || i == 6;
                                return Expanded(
                                  child: Center(
                                    child: Text(
                                      _weekInitials[i],
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isWeekend
                                            ? colorScheme.onSurfaceVariant
                                                .withOpacity(0.65)
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 10),

                            // Grade dos dias do mês
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: totalCells,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: 6,
                                crossAxisSpacing: 5,
                                childAspectRatio: 0.96,
                              ),
                              itemBuilder: (context, index) {
                                if (index < leadingEmptySlots) {
                                  return const SizedBox.shrink();
                                }

                                final dayNumber = index - leadingEmptySlots + 1;
                                final cellDate = DateTime(
                                  focused.year,
                                  focused.month,
                                  dayNumber,
                                );
                                final isSelected = cellDate == selected;
                                final isToday = cellDate == today;
                                final status = widget.isStaff
                                    ? DayAttendanceStatus.none
                                    : _resolveDisplayStatus(
                                        cellDate,
                                        savedMap,
                                        drafts,
                                      );
                                final dotColor =
                                    _statusColor(status, colorScheme);

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _selectDate(cellDate),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 160),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? colorScheme.primary
                                            : (status !=
                                                    DayAttendanceStatus.none
                                                ? dotColor.withOpacity(
                                                    isDark ? 0.20 : 0.13,
                                                  )
                                                : Colors.transparent),
                                        borderRadius: BorderRadius.circular(12),
                                        border: isToday && !isSelected
                                            ? Border.all(
                                                color: colorScheme.primary,
                                                width: 1.6,
                                              )
                                            : (status !=
                                                        DayAttendanceStatus
                                                            .none &&
                                                    !isSelected
                                                ? Border.all(
                                                    color: dotColor
                                                        .withOpacity(0.35),
                                                    width: 1,
                                                  )
                                                : null),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '$dayNumber',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: isSelected || isToday
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              color: isSelected
                                                  ? Colors.white
                                                  : colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 160,
                                            ),
                                            width: status ==
                                                    DayAttendanceStatus.none
                                                ? 0
                                                : 14,
                                            height: 3.5,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              color: status ==
                                                      DayAttendanceStatus.none
                                                  ? Colors.transparent
                                                  : (isSelected
                                                      ? Colors.white
                                                      : dotColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            if (!widget.isStaff) ...[
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.onSurface
                                      .withOpacity(isDark ? 0.05 : 0.035),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Wrap(
                                  spacing: 14,
                                  runSpacing: 6,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _buildLegendItem(
                                      'Ida e Volta',
                                      const Color(0xFF16A34A),
                                      colorScheme,
                                    ),
                                    _buildLegendItem(
                                      'Só Ida',
                                      colorScheme.primary,
                                      colorScheme,
                                    ),
                                    _buildLegendItem(
                                      'Só Volta',
                                      const Color(0xFFF59E0B),
                                      colorScheme,
                                    ),
                                    _buildLegendItem(
                                      'Ausente',
                                      const Color(0xFFDC2626),
                                      colorScheme,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ================= 3. PAINEL DO DIA SELECIONADO =================
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: _cardDecoration(theme),
                        child: widget.isStaff
                            ? _buildStaffDaySummary(
                                selected: selected,
                                isLoading: loadingStaffDay,
                                outboundCount: outboundCount,
                                returnCount: returnCount,
                                absentCount: absentCount,
                                theme: theme,
                                colorScheme: colorScheme,
                              )
                            : _buildPassengerDayControls(
                                selected: selected,
                                selectedStatus: selectedStatus,
                                hasUnsavedChange: hasUnsavedChange,
                                saving: saving,
                                theme: theme,
                                colorScheme: colorScheme,
                                isDark: isDark,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
      );
    });
  }

  Widget _buildLegendItem(
    String label,
    Color color,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerDayControls({
    required DateTime selected,
    required DayAttendanceStatus selectedStatus,
    required bool hasUnsavedChange,
    required bool saving,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    final badgeColor = _statusColor(selectedStatus, colorScheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Programação • ${_formatDateBr(selected)}',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasUnsavedChange
                        ? 'Alteração pendente — toque em salvar abaixo'
                        : 'Defina como você utilizará a linha nesta data',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasUnsavedChange
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight:
                          hasUnsavedChange ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            // Badge do canto superior direito: 100% fosco, sem opacity
            if (selectedStatus != DayAttendanceStatus.none) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _statusLabel(selectedStatus),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        Divider(
          color: theme.dividerColor.withOpacity(0.5),
          height: 1,
        ),
        const SizedBox(height: 14),

        // Grade 2x2 simétrica com fundos 100% foscos e ícones sempre brancos
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildStatusGridCard(
                  title: 'Ida e Volta',
                  subtitle: 'Ambos os trechos',
                  icon: Icons.swap_horiz_rounded,
                  accentColor: const Color(0xFF16A34A),
                  isSelected: selectedStatus == DayAttendanceStatus.both,
                  colorScheme: colorScheme,
                  isDark: isDark,
                  onTap: () =>
                      _selectStatusForCurrentDay(DayAttendanceStatus.both),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatusGridCard(
                  title: 'Somente Ida',
                  subtitle: 'Apenas embarque',
                  icon: Icons.arrow_forward_rounded,
                  accentColor: colorScheme.primary,
                  isSelected:
                      selectedStatus == DayAttendanceStatus.outboundOnly,
                  colorScheme: colorScheme,
                  isDark: isDark,
                  onTap: () => _selectStatusForCurrentDay(
                    DayAttendanceStatus.outboundOnly,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildStatusGridCard(
                  title: 'Somente Volta',
                  subtitle: 'Apenas retorno',
                  icon: Icons.arrow_back_rounded,
                  accentColor: const Color(0xFFF59E0B),
                  isSelected: selectedStatus == DayAttendanceStatus.returnOnly,
                  colorScheme: colorScheme,
                  isDark: isDark,
                  onTap: () => _selectStatusForCurrentDay(
                    DayAttendanceStatus.returnOnly,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatusGridCard(
                  title: 'Ausente',
                  subtitle: 'Não vou neste dia',
                  icon: Icons.event_busy_rounded,
                  accentColor: const Color(0xFFDC2626),
                  isSelected: selectedStatus == DayAttendanceStatus.absent,
                  colorScheme: colorScheme,
                  isDark: isDark,
                  onTap: () =>
                      _selectStatusForCurrentDay(DayAttendanceStatus.absent),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: saving ? null : _saveSelectedDay,
            icon: saving
                ? const SizedBox.shrink()
                : const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
            label: saving
                ? const AnimatedThreeDots(color: Colors.white)
                : const Text(
                    'Salvar Presença do Dia',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusGridCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isSelected,
    required ColorScheme colorScheme,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final unselectedBg =
        isDark ? const Color(0xFF232732) : const Color(0xFFF3F4F6);
    final unselectedBorder =
        isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB);
    final iconBoxColor =
        isSelected ? _darkenSolid(accentColor, 0.12) : accentColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? accentColor : unselectedBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? accentColor : unselectedBorder,
              width: isSelected ? 1.8 : 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: iconBoxColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 19, color: Colors.white),
                  ),
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 19,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isSelected
                      ? Colors.white
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffDaySummary({
    required DateTime selected,
    required bool isLoading,
    required int outboundCount,
    required int returnCount,
    required int absentCount,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumo • ${_formatDateBr(selected)}',
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Previsão de embarques confirmados pelos passageiros nesta data',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        Divider(
          color: theme.dividerColor.withOpacity(0.5),
          height: 1,
        ),
        const SizedBox(height: 14),
        if (isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: AnimatedThreeDots(color: colorScheme.onSurface),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: _buildMetricChip(
                  label: 'Ida',
                  value: '$outboundCount',
                  icon: Icons.arrow_forward_rounded,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricChip(
                  label: 'Volta',
                  value: '$returnCount',
                  icon: Icons.arrow_back_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricChip(
                  label: 'Ausentes',
                  value: '$absentCount',
                  icon: Icons.event_busy_rounded,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMetricChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final ColorScheme colorScheme;

  const _MonthNavButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF232732) : const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            color: colorScheme.onSurface,
            size: 22,
          ),
        ),
      ),
    );
  }
}