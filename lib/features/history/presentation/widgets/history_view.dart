import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'package:tiktac_app/features/history/presentation/widgets/history_card.dart';
import 'package:tiktac_app/features/history/presentation/widgets/stats_panel.dart';
import 'package:tiktac_app/features/stopwatch/presentation/blocs/stopwatch_cubit.dart';
import 'package:tiktac_app/features/stopwatch/presentation/blocs/stopwatch_state.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query, StopwatchCubit cubit) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      cubit.searchEntries(query);
    });
  }

  Future<void> _importCSV(BuildContext context, StopwatchCubit cubit) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar Historial'),
        content: const Text(
          'Puedes importar tu historial desde un archivo CSV o TXT generado previamente por esta aplicación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Seleccionar Archivo'),
          ),
        ],
      ),
    );

    if (proceed != true) return;

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final contents = await file.readAsString();
        final count = await cubit.importCSVData(contents);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$count registros importados')),
          );
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error al importar archivo CSV en Historial',
        error: e,
        stackTrace: stackTrace,
        name: 'HistoryView',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al importar archivo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<StopwatchCubit>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('Historial', style: theme.textTheme.titleLarge),
              const Spacer(),
              IconButton(
                onPressed: () => _importCSV(context, cubit),
                icon: const Icon(Icons.file_upload),
                tooltip: 'Importar CSV',
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  final csv = cubit.exportCSVData();
                  if (csv.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No hay datos para exportar')),
                    );
                    return;
                  }
                  SharePlus.instance.share(ShareParams(text: csv, subject: 'Historial de Cronómetro'));
                },
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Exportar'),
              ),
              const SizedBox(width: 8),
              BlocBuilder<StopwatchCubit, StopwatchState>(
                buildWhen: (previous, current) =>
                    (previous.entries.isNotEmpty) != (current.entries.isNotEmpty),
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state.entries.isNotEmpty
                        ? () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Borrar todo'),
                                content: const Text('¿Estás seguro de que quieres eliminar todo el historial?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      cubit.clearHistory();
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Borrar', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          }
                        : null,
                    child: const Text('Borrar todo'),
                  );
                },
              ),
            ],
          ),
        ),
        BlocBuilder<StopwatchCubit, StopwatchState>(
          buildWhen: (previous, current) => previous.entries != current.entries,
          builder: (context, state) {
            if (state.entries.isNotEmpty) {
              return StatsPanel(state: state);
            }
            return const SizedBox.shrink();
          },
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, _) {
              return TextField(
                controller: _searchController,
                onChanged: (val) => _onSearchChanged(val, cubit),
                decoration: InputDecoration(
                  hintText: 'Buscar en el historial...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: value.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _debounceTimer?.cancel();
                            cubit.searchEntries('');
                          },
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        Expanded(
          child: BlocBuilder<StopwatchCubit, StopwatchState>(
            buildWhen: (previous, current) =>
                previous.filteredEntries != current.filteredEntries ||
                previous.isLoading != current.isLoading ||
                previous.errorMessage != current.errorMessage ||
                previous.filterQuery != current.filterQuery ||
                previous.entries.length != current.entries.length,
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(state.errorMessage!, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => cubit.loadEntries(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              final displayList = state.filterQuery.isNotEmpty || _searchController.text.isNotEmpty
                  ? state.filteredEntries
                  : state.entries;

              if (displayList.isEmpty) {
                final isSearching = state.filterQuery.isNotEmpty || _searchController.text.isNotEmpty;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSearching ? Icons.search_off : Icons.history_toggle_off,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isSearching
                              ? 'No se encontraron resultados para la búsqueda.'
                              : 'No tienes actividades registradas aún.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  final entry = displayList[index];
                  return HistoryCard(entry: entry);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
