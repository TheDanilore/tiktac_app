import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

import 'package:tiktac_app/features/stopwatch/data/models/stopwatch_entry.dart';
import 'package:tiktac_app/features/stopwatch/presentation/blocs/stopwatch_cubit.dart';
import 'package:tiktac_app/features/stopwatch/presentation/blocs/stopwatch_state.dart';
import 'package:tiktac_app/features/stopwatch/presentation/widgets/edit_activity_modal.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  final csv = cubit.exportCSVData();
                  SharePlus.instance.share(ShareParams(text: csv, subject: 'Historial de Cronómetro'));
                },
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Exportar'),
              ),
              const SizedBox(width: 8),
              BlocBuilder<StopwatchCubit, StopwatchState>(
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
          builder: (context, state) {
            if (state.entries.isNotEmpty) {
              return _StatsPanel(state: state);
            }
            return const SizedBox.shrink();
          },
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => cubit.searchEntries(value),
            decoration: InputDecoration(
              hintText: 'Buscar en el historial...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        cubit.searchEntries('');
                      },
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: BlocBuilder<StopwatchCubit, StopwatchState>(
            builder: (context, state) {
              if (state.filteredEntries.isEmpty) {
                return const Center(child: Text('No hay registros.'));
              }
              return ListView.builder(
                itemCount: state.filteredEntries.length,
                itemBuilder: (context, index) {
                  final entry = state.filteredEntries[index];
                  return _HistoryCard(entry: entry);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final StopwatchEntry entry;

  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: Key(entry.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onError, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¿Eliminar actividad?'),
            content: const Text('¿Estás seguro de que deseas eliminar este registro?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) {
        final cubit = context.read<StopwatchCubit>();
        cubit.deleteEntry(entry.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Actividad eliminada'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'Deshacer',
              textColor: theme.colorScheme.primary,
              onPressed: () {
                cubit.saveActivity(title: entry.title, category: entry.category, notes: entry.notes, finalElapsedTime: entry.duration);
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Center(
              child: Icon(Icons.timer_outlined, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          title: Text(
            entry.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.category,
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.createdAt.toString().split('.')[0],
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
          trailing: Text(
            _formatDuration(entry.duration),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: theme.colorScheme.onSurface,
            ),
          ),
          onTap: () {
            _showShareDialog(context, entry);
          },
          onLongPress: () {
            _showOptionsBottomSheet(context, entry, theme);
          },
        ),
      ),
    );
  }

  String _formatDuration(int millisecondsTotal) {
    final hours = (millisecondsTotal ~/ 3600000).toString().padLeft(2, '0');
    final minutes = ((millisecondsTotal ~/ 60000) % 60).toString().padLeft(2, '0');
    final seconds = ((millisecondsTotal ~/ 1000) % 60).toString().padLeft(2, '0');
    
    if (millisecondsTotal >= 3600000) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _showOptionsBottomSheet(BuildContext context, StopwatchEntry entry, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar actividad'),
                onTap: () {
                  Navigator.pop(context);
                  EditActivityModal.show(context, entry: entry);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: theme.colorScheme.error),
                title: Text('Eliminar', style: TextStyle(color: theme.colorScheme.error)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, entry);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, StopwatchEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar actividad?'),
        content: const Text('¿Estás seguro de que deseas eliminar este registro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final cubit = context.read<StopwatchCubit>();
              cubit.deleteEntry(entry.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Actividad eliminada'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  action: SnackBarAction(
                    label: 'Deshacer',
                    textColor: Theme.of(context).colorScheme.primary,
                    onPressed: () {
                      cubit.saveActivity(title: entry.title, category: entry.category, notes: entry.notes, finalElapsedTime: entry.duration);
                    },
                  ),
                ),
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context, StopwatchEntry entry) {
    final theme = Theme.of(context);
    final ScreenshotController screenshotController = ScreenshotController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Screenshot(
                controller: screenshotController,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer, color: theme.colorScheme.primary, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _formatDuration(entry.duration),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.title,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.category} • ${entry.createdAt.toString().split('.')[0]}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Cerrar'),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      try {
                        final directory = await getApplicationDocumentsDirectory();
                        final path = '${directory.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
                        final image = await screenshotController.capture();
                        if (image != null) {
                          final file = File(path);
                          await file.writeAsBytes(image);
                          await SharePlus.instance.share(
                            ShareParams(
                              files: [XFile(path)],
                              text: '¡Mira mi tiempo en TikTac!',
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('Error sharing: $e');
                      }
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Compartir'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _StatsPanel extends StatelessWidget {
  final StopwatchState state;

  const _StatsPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    int totalCount = state.entries.length;
    int totalTime = state.entries.fold(0, (sum, entry) => sum + entry.duration);
    int averageTime = totalCount > 0 ? (totalTime ~/ totalCount) : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ESTADÍSTICAS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Sesiones',
                  value: totalCount.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Tiempo total',
                  value: _formatDuration(totalTime),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Promedio',
                  value: _formatDuration(averageTime),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(int milliseconds) {
    if (milliseconds == 0) return '0.0s';
    final hours = (milliseconds ~/ 3600000);
    final minutes = ((milliseconds ~/ 60000) % 60);
    final seconds = ((milliseconds ~/ 1000) % 60);

    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
