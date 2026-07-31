import 'package:flutter/material.dart';

class QuickPresets extends StatelessWidget {
  final Function(String title, String category) onPresetSelected;

  const QuickPresets({super.key, required this.onPresetSelected});

  @override
  Widget build(BuildContext context) {
    final presets = [
      {
        'title': 'Programación / Fix',
        'category': 'Trabajo',
        'icon': Icons.code,
      },
      {
        'title': 'Sesión de Estudio',
        'category': 'Estudio',
        'icon': Icons.menu_book,
      },
      {
        'title': 'Cocinar / Preparar comida',
        'category': 'Hogar',
        'icon': Icons.restaurant,
      },
      {
        'title': 'Rutina de Ejercicio',
        'category': 'Salud',
        'icon': Icons.fitness_center,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF181B26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFFEAB308),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ajustes Rápidos Preseteados',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '(Clic para cargar título y categoría)',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: presets.map((preset) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    backgroundColor: const Color(0xFF0F111A),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    label: Row(
                      children: [
                        Icon(
                          preset['icon'] as IconData,
                          size: 16,
                          color: const Color(0xFF2DD4BF),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          preset['title'] as String,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    onPressed: () {
                      onPresetSelected(
                        preset['title'] as String,
                        preset['category'] as String,
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
