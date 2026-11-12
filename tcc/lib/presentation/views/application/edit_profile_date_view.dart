import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/di/dependency_injection.dart';
import '../../controllers/user_viewmodel.dart';
import '../../widgets/header_background.dart';
import '../../widgets/animated_three_dots.dart';

class EditProfileDateView extends StatefulWidget {
  const EditProfileDateView({super.key});

  @override
  State<EditProfileDateView> createState() => _EditProfileDateViewState();
}

class _EditProfileDateViewState extends State<EditProfileDateView> {
  late final UserViewModel _userViewModel;
  late final TextEditingController _dateController;
  
  DateTime? _selectedDate;
  String? _errorMessage;
  final isLoading = signal(false);

  @override
  void initState() {
    super.initState();
    _userViewModel = injector.get<UserViewModel>();
    _selectedDate = _userViewModel.state.user.value?.birthDate;
    
    _dateController = TextEditingController(
      text: _selectedDate != null ? _formatDateForTextField(_selectedDate!) : '',
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  String _formatDateForTextField(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  void _updateDateFromText(String text) {
    if (text.isEmpty) {
      setState(() {
        _selectedDate = null;
        _errorMessage = null;
      });
      return;
    }

    if (text.length < 10) {
      setState(() {
        _selectedDate = null;
        _errorMessage = 'Data incompleta (DD/MM/AAAA)';
      });
      return;
    }

    try {
      final parts = text.split('/');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final currentYear = DateTime.now().year;

      if (year < 1920 || year > currentYear) {
        setState(() {
          _selectedDate = null;
          _errorMessage = 'Ano inválido (entre 1920 e $currentYear)';
        });
        return;
      }

      if (month < 1 || month > 12) {
        setState(() {
          _selectedDate = null;
          _errorMessage = 'Mês inválido (de 01 a 12)';
        });
        return;
      }

      final daysInMonth = DateTime(year, month + 1, 0).day;
      if (day < 1 || day > daysInMonth) {
        setState(() {
          _selectedDate = null;
          _errorMessage = 'Dia inválido para este mês';
        });
        return;
      }

      final parsedDate = DateTime(year, month, day);
      if (parsedDate.isAfter(DateTime.now())) {
        setState(() {
          _selectedDate = null;
          _errorMessage = 'A data não pode ser no futuro';
        });
        return;
      }

      setState(() {
        _selectedDate = parsedDate;
        _errorMessage = null;
      });
    } catch (_) {
      setState(() {
        _selectedDate = null;
        _errorMessage = 'Data inválida';
      });
    }
  }

  Future<void> _openCalendarPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'), 
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDateForTextField(picked);
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final router = GoRouter.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                HeaderBackground(height: context.screenHeight * 0.3),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        onPressed: () => context.pop(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data de Nascimento',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: colorScheme.onSurface, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: _dateController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_DateInputFormatter()],
                    onChanged: _updateDateFromText,
                    decoration: InputDecoration(
                      labelText: 'Sua data de nascimento',
                      hintText: 'DD/MM/AAAA',
                      errorText: _errorMessage,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_month_rounded),
                        color: colorScheme.primary,
                        onPressed: _openCalendarPicker,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Watch(
                    (context) => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading.value || _selectedDate == null
                            ? null
                            : () async {
                                final currentUser = _userViewModel.state.user.value;
                                if (currentUser == null) return;

                                try {
                                  isLoading.value = true;
                                  final updatedUser = currentUser.copyWith(birthDate: _selectedDate);
                                  await _userViewModel.commands.saveUserData(updatedUser);
                                  
                                  if (!context.mounted) return;
                                  router.pop();
                                } finally {
                                  if (context.mounted) isLoading.value = false;
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isLoading.value
                            ? AnimatedThreeDots(color: colorScheme.onSurface)
                            : const Text('Salvar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newText.length > 8) return oldValue;
    
    final buffer = StringBuffer();
    for (int i = 0; i < newText.length; i++) {
      buffer.write(newText[i]);
      if ((i == 1 || i == 3) && i != newText.length - 1) {
        buffer.write('/');
      }
    }
    
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}