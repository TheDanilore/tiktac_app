import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiktac_app/providers/stopwatch_provider.dart';
import 'package:tiktac_app/screens/widgets/stopwatch_display.dart';
import 'package:tiktac_app/screens/widgets/control_buttons.dart';
import 'package:tiktac_app/screens/widgets/save_activity_modal.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 800;

            if (isTablet) {
              // Tablet / Desktop: Split View
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Panel: Stopwatch
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildHeader(context, isTablet: true),
                        const Expanded(child: StopwatchView()),
                      ],
                    ),
                  ),
                  // Divider
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  // Right Panel: History
                  const Expanded(
                    flex: 1,
                    child: HistoryView(),
                  ),
                ],
              );
            }

            // Mobile: Tabbed View
            return Column(
              children: [
                _buildHeader(context, isTablet: false),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      StopwatchView(),
                      HistoryView(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required bool isTablet}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.timer, color: theme.colorScheme.onPrimary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Cronómetro & Historial',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('v2.0', style: TextStyle(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    Text(
                      'Mide tu tiempo y documenta en qué te demoras',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isTablet) ...[
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _CustomTab(
                      icon: Icons.timer,
                      text: 'Cronómetro',
                      isSelected: _tabController.index == 0,
                      onTap: () => _tabController.animateTo(0),
                    ),
                  ),
                  Expanded(
                    child: Consumer<StopwatchProvider>(
                      builder: (context, provider, child) {
                        return _CustomTab(
                          icon: Icons.history,
                          text: 'Historial',
                          badge: provider.entries.length.toString(),
                          isSelected: _tabController.index == 1,
                          onTap: () => _tabController.animateTo(1),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class _CustomTab extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _CustomTab({
    required this.icon,
    required this.text,
    this.badge,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.onPrimary.withValues(alpha: 0.2)
                      : theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class StopwatchView extends StatelessWidget {
  const StopwatchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const StopwatchDisplay(),
            const SizedBox(height: 64),
            ControlButtons(
              onSave: () => SaveActivityModal.show(context, onSaved: () {}),
            ),
          ],
        ),
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<StopwatchProvider>(
      builder: (context, provider, child) {
        final entries = provider.entries;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text('Historial', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      final text = provider.exportData();
                      if (text.isNotEmpty) {
                        SharePlus.instance.share(ShareParams(
                          text: text,
                          subject: 'Historial de Cronómetro',
                        ));
                      }
                    },
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Exportar CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.surface,
                      foregroundColor: theme.colorScheme.onSurface,
                      elevation: 0,
                      side: BorderSide(color: theme.colorScheme.outline),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: provider.allEntries.isNotEmpty
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
                  ),
                ],
              ),
            ),
            if (provider.allEntries.isNotEmpty) _StatsPanel(provider: provider),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => provider.search(value),
                decoration: InputDecoration(
                  hintText: 'Buscar en el historial...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            provider.search('');
                          },
                        )
                      : null,
                ),
              ),
            ),
            // Listado de registros
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Text(
                        'Aún no hay sesiones guardadas.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return _HistoryCard(entry: entry);
                      },
                    ),
            ),
          ],
        );
      },
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
      onDismissed: (direction) {
        Provider.of<StopwatchProvider>(context, listen: false).deleteEntry(entry.key);
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
        ),
      ),
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
