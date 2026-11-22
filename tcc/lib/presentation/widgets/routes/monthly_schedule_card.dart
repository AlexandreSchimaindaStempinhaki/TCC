import 'package:flutter/material.dart';

class MonthlyScheduleCard extends StatefulWidget {
  const MonthlyScheduleCard({super.key});

  @override
  State<MonthlyScheduleCard> createState() => _MonthlyScheduleCardState();
}

class _MonthlyScheduleCardState extends State<MonthlyScheduleCard> {
  int _comboPreset = 2;
  String _outboundShift = 'Manhã (07:00)';
  String _inboundShift = 'Tarde (18:00)';
  final Set<int> _selectedDays = {2, 3, 4, 5, 6, 9, 10, 11, 12, 13};

  void _applyComboPreset(int index) {
    setState(() {
      _comboPreset = index;
      switch (index) {
        case 0:
          _outboundShift = 'Manhã (07:00)';
          _inboundShift = 'Manhã (12:00)';
          break;
        case 1:
          _outboundShift = 'Tarde (13:00)';
          _inboundShift = 'Tarde (18:00)';
          break;
        case 2:
          _outboundShift = 'Manhã (07:00)';
          _inboundShift = 'Tarde (18:00)';
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Combinação de Turnos (Ida e Volta)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetChip('Manhã / Manhã', 0, colorScheme),
              _buildPresetChip('Tarde / Tarde', 1, colorScheme),
              _buildPresetChip('Manhã / Tarde', 2, colorScheme),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? colorScheme.surface
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ida',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _outboundShift,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: theme.dividerColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Volta',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _inboundShift,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 24, color: theme.dividerColor),
          Text(
            'Calendário Mensal de Presença',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Toque nos dias do mês em que você irá utilizar o transporte:',
            style: TextStyle(fontSize: 11, color: colorScheme.secondary.withOpacity(0.8)),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemCount: 31,
            itemBuilder: (context, index) {
              final dayNumber = index + 1;
              final isSelected = _selectedDays.contains(dayNumber);

              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedDays.remove(dayNumber);
                    } else {
                      _selectedDays.add(dayNumber);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : theme.dividerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, int index, ColorScheme colorScheme) {
    final isSelected = _comboPreset == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : colorScheme.onSurface,
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
      onSelected: (_) => _applyComboPreset(index),
    );
  }
}