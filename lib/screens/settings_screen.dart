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
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionTitle(title: 'Apariencia'),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: RadioGroup<ThemeMode>(
                  groupValue: settings.themeMode,
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
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Comportamiento'),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Vibración Intensa'),
                      subtitle: const Text('Al terminar el temporizador o acciones clave'),
                      value: settings.isVibrationEnabled,
                      onChanged: (val) => settings.setVibrationEnabled(val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Sonido'),
                      subtitle: const Text('Reproducir alarma al finalizar el temporizador'),
                      value: settings.isSoundEnabled,
                      onChanged: (val) => settings.setSoundEnabled(val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Modo Encogido (PiP)'),
                      subtitle: const Text('Mantener tiempo en pantalla al minimizar la app'),
                      value: settings.isPipEnabled,
                      onChanged: (val) => settings.setPipEnabled(val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Permisos'),
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
                  onTap: () => openAppSettings(),
                ),
              ),
            ],
          );
        },
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
