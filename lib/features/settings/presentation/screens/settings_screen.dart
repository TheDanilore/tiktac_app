import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tiktac_app/features/settings/presentation/blocs/settings_cubit.dart';
import 'package:tiktac_app/features/settings/presentation/blocs/settings_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
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
            child: BlocSelector<SettingsCubit, SettingsState, ThemeMode>(
              selector: (state) => state.themeMode,
              builder: (context, themeMode) {
                final cubit = context.read<SettingsCubit>();
                return RadioGroup<ThemeMode>(
                  groupValue: themeMode,
                  onChanged: (mode) {
                    if (mode != null) {
                      cubit.setThemeMode(mode);
                    }
                  },
                  child: Column(
                    children: const [
                      RadioListTile<ThemeMode>(
                        title: Text('Sistema'),
                        value: ThemeMode.system,
                      ),
                      Divider(height: 1),
                      RadioListTile<ThemeMode>(
                        title: Text('Claro'),
                        value: ThemeMode.light,
                      ),
                      Divider(height: 1),
                      RadioListTile<ThemeMode>(
                        title: Text('Oscuro'),
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
                BlocSelector<SettingsCubit, SettingsState, bool>(
                  selector: (state) => state.isVibrationEnabled,
                  builder: (context, isVibrationEnabled) {
                    return SwitchListTile(
                      title: const Text('Vibración Intensa'),
                      subtitle: const Text(
                        'Al terminar el temporizador o acciones clave',
                      ),
                      value: isVibrationEnabled,
                      onChanged: (val) => context
                          .read<SettingsCubit>()
                          .setVibrationEnabled(val),
                    );
                  },
                ),
                const Divider(height: 1),
                BlocSelector<SettingsCubit, SettingsState, bool>(
                  selector: (state) => state.isSoundEnabled,
                  builder: (context, isSoundEnabled) {
                    return SwitchListTile(
                      title: const Text('Sonido'),
                      subtitle: const Text(
                        'Reproducir alarma al finalizar el temporizador',
                      ),
                      value: isSoundEnabled,
                      onChanged: (val) =>
                          context.read<SettingsCubit>().setSoundEnabled(val),
                    );
                  },
                ),
                const Divider(height: 1),
                BlocSelector<SettingsCubit, SettingsState, bool>(
                  selector: (state) => state.isPipEnabled,
                  builder: (context, isPipEnabled) {
                    return SwitchListTile(
                      title: const Text('Modo Encogido (PiP)'),
                      subtitle: const Text(
                        'Mantener tiempo en pantalla al minimizar la app',
                      ),
                      value: isPipEnabled,
                      onChanged: (val) =>
                          context.read<SettingsCubit>().setPipEnabled(val),
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
            child: Column(
              children: [
                ListTile(
                  title: const Text('Notificaciones'),
                  subtitle: const Text(
                    'Configurar permiso en los ajustes del sistema',
                  ),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () async {
                    try {
                      final opened = await openAppSettings();
                      if (!opened && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No se pudieron abrir los ajustes del sistema',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error al acceder a los ajustes'),
                          ),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Almacenamiento Local'),
                  subtitle: const Text(
                    'Permite guardar el historial en la carpeta Documentos/TikTac (Descargas)',
                  ),
                  trailing: const Icon(Icons.folder_outlined),
                  onTap: () async {
                    if (await Permission.manageExternalStorage.isDenied) {
                      await Permission.manageExternalStorage.request();
                    }
                    if (await Permission.storage.isDenied) {
                      await Permission.storage.request();
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Permisos de almacenamiento actualizados',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
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
