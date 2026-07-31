import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiktac_app/features/stopwatch/presentation/blocs/stopwatch_cubit.dart';
import 'package:tiktac_app/features/stopwatch/presentation/blocs/stopwatch_state.dart';
import 'package:tiktac_app/features/stopwatch/presentation/widgets/quick_presets.dart';

class SaveActivityModal extends StatefulWidget {
  final VoidCallback onSaved;
  final int finalElapsedTime;

  const SaveActivityModal({super.key, required this.onSaved, required this.finalElapsedTime});

  static Future<void> show(BuildContext context, {required VoidCallback onSaved, required int finalElapsedTime}) {
    final isTablet = MediaQuery.of(context).size.width >= 800;

    if (isTablet) {
      return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SaveActivityModal(onSaved: onSaved, finalElapsedTime: finalElapsedTime),
          ),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (_) => SaveActivityModal(onSaved: onSaved, finalElapsedTime: finalElapsedTime),
      );
    }
  }

  @override
  State<SaveActivityModal> createState() => _SaveActivityModalState();
}

class _SaveActivityModalState extends State<SaveActivityModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController(text: 'General');

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<StopwatchCubit>().saveActivity(
        title: _titleController.text.trim(),
        category: _categoryController.text.trim(),
        notes: '',
        finalElapsedTime: widget.finalElapsedTime,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isTablet = MediaQuery.of(context).size.width >= 800;

    return BlocConsumer<StopwatchCubit, StopwatchState>(
      listenWhen: (previous, current) => previous.isLoading != current.isLoading || previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (!state.isLoading && state.errorMessage == null) {
          Navigator.of(context).pop();
          widget.onSaved();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: theme.colorScheme.surface),
                  const SizedBox(width: 8),
                  const Text('Actividad guardada exitosamente', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              backgroundColor: theme.colorScheme.secondary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: theme.colorScheme.error,
            ),
          );
          context.read<StopwatchCubit>().clearError();
        }
      },
      builder: (context, state) {
        final isLoading = state.isLoading;
        
        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: bottomPadding > 0 ? bottomPadding + 24 : 32,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: isTablet 
                ? BorderRadius.circular(24) 
                : const BorderRadius.vertical(top: Radius.circular(32)),
            border: isTablet 
                ? null 
                : Border(top: BorderSide(color: theme.colorScheme.outline)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isTablet)
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Guardar Sesión',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (!isLoading)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                  ],
                ),
                const SizedBox(height: 24),
                IgnorePointer(
                  ignoring: isLoading,
                  child: QuickPresets(
                    onPresetSelected: (title, category) {
                      setState(() {
                        _titleController.text = title;
                        _categoryController.text = category;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  enabled: !isLoading,
                  maxLength: 50,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: '¿En qué vas a trabajar / medir?',
                    prefixIcon: const Icon(Icons.auto_fix_high),
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El título es obligatorio';
                    }
                    if (value.trim().length < 3) {
                      return 'El título debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryController,
                  enabled: !isLoading,
                  maxLength: 30,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    prefixIcon: const Icon(Icons.label_outline),
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La categoría es obligatoria';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: isLoading ? null : () => _save(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading 
                    ? const SizedBox(
                        height: 20, width: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2)
                      )
                    : const Text('Categorizar y Guardar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
