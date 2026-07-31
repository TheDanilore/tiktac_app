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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 16),
                  Text('Importando historial...'),
                ],
              ),
              duration: Duration(seconds: 1),
            ),
          );
        }

        await Future.delayed(
          const Duration(milliseconds: 300),
        ); // Renderizar snackbar

        final file = File(result.files.single.path!);
        final contents = await file.readAsString();
        final count = await cubit.importCSVData(contents);

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $count registros importados correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          cubit.loadEntries();
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

  Future<void> _exportData(BuildContext context, StopwatchCubit cubit) async {
    final csvData = cubit.exportCSVData();
    if (csvData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay datos para exportar')),
      );
      return;
    }

    final format = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Opciones de Exportación',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.table_chart, color: Colors.green),
                  title: const Text('Archivo CSV (Recomendado)'),
                  subtitle: const Text(
                    'Ideal para importar de vuelta a la app o abrir en Excel.',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  onTap: () => Navigator.pop(context, 'csv'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.description, color: Colors.blue),
                  title: const Text('Documento de Texto (TXT)'),
                  subtitle: const Text(
                    'Formato simple de lectura sin formato.',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  onTap: () => Navigator.pop(context, 'txt'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (format != null) {
      final fileName = 'Historial_TikTac.$format';
      SharePlus.instance.share(ShareParams(text: csvData, subject: fileName));
    }
  }

  void _showMoreOptions(
    BuildContext context,
    StopwatchCubit cubit,
    bool hasEntries,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.file_download_outlined),
                title: const Text('Importar historial'),
                onTap: () {
                  Navigator.pop(context);
                  _importCSV(context, cubit);
                },
              ),
              ListTile(
                leading: const Icon(Icons.ios_share),
                title: const Text('Exportar historial'),
                enabled: hasEntries,
                onTap: () {
                  Navigator.pop(context);
                  _exportData(context, cubit);
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.delete_sweep,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  'Borrar todo el historial',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                enabled: hasEntries,
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Borrar todo'),
                      content: const Text(
                        '¿Estás seguro de que quieres eliminar permanentemente todo el historial?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                          ),
                          onPressed: () {
                            cubit.clearHistory();
                            Navigator.pop(dialogContext);
                          },
                          child: const Text('Borrar Definitivamente'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<StopwatchCubit>();

    return BlocBuilder<StopwatchCubit, StopwatchState>(
      buildWhen: (previous, current) =>
          previous.entries != current.entries ||
          previous.filteredEntries != current.filteredEntries ||
          previous.filterQuery != current.filterQuery ||
          previous.isLoading != current.isLoading ||
          previous.errorMessage != current.errorMessage,
      builder: (context, state) {
        final hasEntries = state.entries.isNotEmpty;
        final displayList =
            state.filterQuery.isNotEmpty || _searchController.text.isNotEmpty
            ? state.filteredEntries
            : state.entries;
        final isSearching =
            state.filterQuery.isNotEmpty || _searchController.text.isNotEmpty;

        return RefreshIndicator(
          onRefresh: () async {
            cubit.loadEntries();
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                  child: Row(
                    children: [
                      Text(
                        'Historial',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () =>
                            _showMoreOptions(context, cubit, hasEntries),
                        tooltip: 'Más opciones',
                      ),
                    ],
                  ),
                ),
              ),

              // Stats Panel
              if (hasEntries)
                SliverToBoxAdapter(child: StatsPanel(state: state)),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: SearchBar(
                    controller: _searchController,
                    onChanged: (val) => _onSearchChanged(val, cubit),
                    hintText: 'Buscar en el historial...',
                    leading: const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.search),
                    ),
                    trailing: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _debounceTimer?.cancel();
                            cubit.searchEntries('');
                            FocusScope.of(context).unfocus();
                          },
                        ),
                    ],
                    elevation: WidgetStateProperty.all(0),
                    backgroundColor: WidgetStateProperty.all(
                      theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ),

              // States (Loading / Error / Empty / List)
              if (state.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.errorMessage != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.errorMessage!,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.tonal(
                          onPressed: () => cubit.loadEntries(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (displayList.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSearching
                                ? Icons.search_off
                                : Icons.history_toggle_off,
                            size: 72,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isSearching
                                ? 'No se encontraron resultados.'
                                : 'Aún no hay actividades.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isSearching
                                ? 'Intenta con otros términos de búsqueda.'
                                : 'Tus sesiones guardadas aparecerán aquí.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          HistoryCard(entry: displayList[index]),
                      childCount: displayList.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
