import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tiktac_app/providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle(title: 'Apariencia'),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Selector<SettingsProvider, ThemeMode>(
              selector: (context, settings) => settings.themeMode,
              builder: (context, themeMode, _) {
                final settings = Provider.of<SettingsProvider>(context, listen: false);
                return RadioGroup<ThemeMode>(
                  groupValue: themeMode,
                  onChanged: (mode) => settings.setThemeMode(mode!),
                  child: Column(
                    children: [
                      RadioListTile<ThemeMode>(
                        title: const Text('Sistema'),
                        value: ThemeMode.system,
                      ),
                      const Divider(height: 1),
                      RadioListTile<ThemeMode>(
                        title: const Text('Claro'),
                        value: ThemeMode.light,
                      ),
                      const Divider(height: 1),
                      RadioListTile<ThemeMode>(
                        title: const Text('Oscuro'),
                        value: ThemeMode.dark,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'Comportamiento'),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Column(
              children: [
                Selector<SettingsProvider, bool>(
                  selector: (context, settings) => settings.isVibrationEnabled,
                  builder: (context, isVibrationEnabled, _) {
                    return SwitchListTile(
                      title: const Text('Vibración Intensa'),
                      subtitle: const Text('Al terminar el temporizador o acciones clave'),
                      value: isVibrationEnabled,
                      onChanged: (val) => Provider.of<SettingsProvider>(context, listen: false).setVibrationEnabled(val),
                    );
                  },
                ),
                const Divider(height: 1),
                Selector<SettingsProvider, bool>(
                  selector: (context, settings) => settings.isSoundEnabled,
                  builder: (context, isSoundEnabled, _) {
                    return SwitchListTile(
                      title: const Text('Sonido'),
                      subtitle: const Text('Reproducir alarma al finalizar el temporizador'),
                      value: isSoundEnabled,
                      onChanged: (val) => Provider.of<SettingsProvider>(context, listen: false).setSoundEnabled(val),
                    );
                  },
                ),
                const Divider(height: 1),
                Selector<SettingsProvider, bool>(
                  selector: (context, settings) => settings.isPipEnabled,
                  builder: (context, isPipEnabled, _) {
                    return SwitchListTile(
                      title: const Text('Modo Encogido (PiP)'),
                      subtitle: const Text('Mantener tiempo en pantalla al minimizar la app'),
                      value: isPipEnabled,
                      onChanged: (val) => Provider.of<SettingsProvider>(context, listen: false).setPipEnabled(val),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'Permisos'),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: ListTile(
              title: const Text('Notificaciones'),
              subtitle: const Text('Configurar permiso en los ajustes del sistema'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () async {
                try {
                  final opened = await openAppSettings();
                  if (!opened && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No se pudieron abrir los ajustes del sistema')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error al acceder a los ajustes')),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
