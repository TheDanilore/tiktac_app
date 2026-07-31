import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiktac_app/features/stopwatch/presentation/blocs/stopwatch_cubit.dart';
import 'package:tiktac_app/features/stopwatch/domain/models/stopwatch_entry.dart';
import 'package:tiktac_app/features/stopwatch/presentation/widgets/quick_presets.dart';

class EditActivityModal extends StatefulWidget {
  final StopwatchEntry entry;
  
  const EditActivityModal({super.key, required this.entry});

  static Future<void> show(BuildContext context, {required StopwatchEntry entry}) {
    final isTablet = MediaQuery.of(context).size.width >= 800;

    if (isTablet) {
      return showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: EditActivityModal(entry: entry),
          ),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => EditActivityModal(entry: entry),
      );
    }
  }

  @override
  State<EditActivityModal> createState() => _EditActivityModalState();
}

class _EditActivityModalState extends State<EditActivityModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry.title);
    _categoryController = TextEditingController(text: widget.entry.category);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<StopwatchCubit>();
    
    final title = _titleController.text.trim();
    final category = _categoryController.text.trim();

    final updatedEntry = widget.entry.copyWith(
      title: title,
      category: category,
    );
    cubit.updateEntry(updatedEntry);
    
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.surface),
              const SizedBox(width: 8),
              const Text('Actividad actualizada', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isTablet = MediaQuery.of(context).size.width >= 800;

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
            Text(
              'Editar Actividad',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            QuickPresets(
              onPresetSelected: (title, category) {
                setState(() {
                  _titleController.text = title;
                  _categoryController.text = category;
                });
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              maxLength: 50,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: 'Nombre de la actividad',
                prefixIcon: const Icon(Icons.edit),
                filled: true,
                fillColor: theme.scaffoldBackgroundColor,
              ),
              validator: (value) {
                final trimmed = value?.trim();
                if (trimmed == null || trimmed.isEmpty) {
                  return 'El título es obligatorio';
                }
                if (trimmed.length < 3) {
                  return 'El título debe tener al menos 3 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
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
                final trimmed = value?.trim();
                if (trimmed == null || trimmed.isEmpty) {
                  return 'La categoría es obligatoria';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _save(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Guardar Cambios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
