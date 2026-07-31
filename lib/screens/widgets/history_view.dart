import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

import 'package:tiktac_app/providers/stopwatch_provider.dart';
import 'package:tiktac_app/screens/widgets/edit_activity_modal.dart';

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
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value, StopwatchProvider provider) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      provider.search(value);
    });
  }

  Future<void> _importCSV(BuildContext context, StopwatchProvider provider) async {
    final theme = Theme.of(context);
    
    // 1. Mostrar diálogo de información
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar Historial'),
        content: const Text(
          'Puedes importar tu historial desde un archivo CSV o TXT generado previamente por esta aplicación.\n\n'
          'Asegúrate de que el archivo no haya sido modificado manualmente para evitar errores de lectura.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
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
        final count = await provider.importCSVData(contents);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('$count registros importados exitosamente'),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error al importar: $e')),
              ],
            ),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<StopwatchProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('Historial', style: theme.textTheme.titleLarge),
              const Spacer(),
              IconButton(
                onPressed: () => _importCSV(context, provider),
                icon: const Icon(Icons.file_upload),
                tooltip: 'Importar historial',
                color: theme.colorScheme.primary,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Exportar Historial'),
                      content: const Text('¿En qué formato deseas exportar los datos?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            final text = provider.exportData(); // TXT
                            if (text.isNotEmpty) {
                              SharePlus.instance.share(ShareParams(
                                text: text,
                                subject: 'Historial de Cronómetro (TXT)',
                              ));
                            }
                          },
                          child: const Text('Texto (TXT)'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            final csv = provider.exportCSVData(); // CSV
                            if (csv.isNotEmpty) {
                              SharePlus.instance.share(ShareParams(
                                text: csv,
                                subject: 'Historial de Cronómetro (CSV)',
                              ));
                            }
                          },
                          child: const Text('CSV'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Exportar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  foregroundColor: theme.colorScheme.onSurface,
                  elevation: 0,
                  side: BorderSide(color: theme.colorScheme.outline),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              const SizedBox(width: 8),
              Selector<StopwatchProvider, bool>(
                selector: (_, p) => p.allEntries.isNotEmpty,
                builder: (context, isNotEmpty, _) {
                  return ElevatedButton(
                    onPressed: isNotEmpty
                        ? () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: theme.colorScheme.surface,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                title: const Text('Borrar todo'),
                                content: const Text('¿Estás seguro de que quieres eliminar todo el historial?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancelar', style: TextStyle(color: theme.colorScheme.onSurface)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      provider.clearHistory();
                                      Navigator.pop(context);
                                    },
                                    child: Text('Borrar', style: TextStyle(color: theme.colorScheme.error)),
                                  ),
                                ],
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.surface,
                      foregroundColor: theme.colorScheme.error,
                      elevation: 0,
                      side: BorderSide(color: theme.colorScheme.outline),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Borrar todo'),
                  );
                },
              ),
            ],
          ),
        ),
        Selector<StopwatchProvider, bool>(
          selector: (_, p) => p.allEntries.isNotEmpty,
          builder: (context, isNotEmpty, _) {
            if (isNotEmpty) {
              return _StatsPanel(provider: provider);
            }
            return const SizedBox.shrink();
          },
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedBuilder(
            animation: _searchController,
            builder: (context, _) {
              return TextField(
                controller: _searchController,
                onChanged: (value) => _onSearchChanged(value, provider),
                decoration: InputDecoration(
                  hintText: 'Buscar en el historial...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('', provider);
                          },
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        Expanded(
          child: Selector<StopwatchProvider, List<dynamic>>(
            selector: (_, p) => p.entries,
            builder: (context, entries, _) {
              if (entries.isEmpty) {
                return Center(
                  child: Text(
                    'Aún no hay sesiones guardadas.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
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
  final dynamic entry;

  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: Key(entry.key.toString()),
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
      onDismissed: (direction) {
        final provider = Provider.of<StopwatchProvider>(context, listen: false);
        provider.deleteEntry(entry.key);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Actividad eliminada'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'Deshacer',
              textColor: theme.colorScheme.primary,
              onPressed: () {
                provider.restoreEntry(entry);
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
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
            entry.formattedDuration,
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

  void _showOptionsBottomSheet(BuildContext context, dynamic entry, ThemeData theme) {
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

  void _confirmDelete(BuildContext context, dynamic entry) {
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
              final provider = Provider.of<StopwatchProvider>(context, listen: false);
              provider.deleteEntry(entry.key);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Actividad eliminada'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  action: SnackBarAction(
                    label: 'Deshacer',
                    textColor: Theme.of(context).colorScheme.primary,
                    onPressed: () {
                      provider.restoreEntry(entry);
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

  void _showShareDialog(BuildContext context, dynamic entry) {
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
                        entry.formattedDuration,
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
  final StopwatchProvider provider;

  const _StatsPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    final stats = provider.getStats();

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
                  value: stats['totalCount'].toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Tiempo total',
                  value: _formatDuration(stats['totalTime']),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Promedio',
                  value: _formatDuration(stats['averageTime']),
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
