import 'package:flutter/material.dart';

class MonthlyScheduleCard extends StatefulWidget {
  const MonthlyScheduleCard({super.key});

  @override
  State<MonthlyScheduleCard> createState() => _MonthlyScheduleCardState();
}

class _MonthlyScheduleCardState extends State<MonthlyScheduleCard> {
  // Modalidade de Turno Ex: 0 = Manhã/Manhã, 1 = Tarde/Tarde, 2 = Manhã/Tarde
  int _comboPreset = 2; // Padrão: Vai de Manhã e Volta de Tarde

  String _outboundShift = 'Manhã (07:00)';
  String _inboundShift = 'Tarde (18:00)';

  // Dias selecionados do mês atual (ex: 1 a 31)
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Combinação de Turnos (Ida e Volta)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),

          // Presets de Combinação
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetChip('Manhã / Manhã', 0),
              _buildPresetChip('Tarde / Tarde', 1),
              _buildPresetChip('Manhã / Tarde', 2),
            ],
          ),

          const SizedBox(height: 14),

          // Resumo dos Horários Selecionados
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ida',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _outboundShift,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: const Color(0xFFCBD5E1),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Volta',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _inboundShift,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 24, color: Color(0xFFF1F5F9)),

          const Text(
            'Calendário Mensal de Presença',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Toque nos dias do mês em que você irá utilizar o transporte:',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),

          // Grade Numérica do Mês (1 a 31)
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
                        ? const Color(0xFF1E3A8A)
                        : const Color(0xFFF1F5F9),
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
                            : const Color(0xFF334155),
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

  Widget _buildPresetChip(String label, int index) {
    final isSelected = _comboPreset == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF1E3A8A),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF0F172A),
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
      onSelected: (_) => _applyComboPreset(index),
    );
  }
}