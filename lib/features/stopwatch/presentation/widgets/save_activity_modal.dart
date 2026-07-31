import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiktac_app/features/stopwatch/presentation/providers/stopwatch_provider.dart';
import 'package:tiktac_app/features/stopwatch/presentation/widgets/quick_presets.dart';

class SaveActivityModal extends StatefulWidget {
  final VoidCallback onSaved;

  const SaveActivityModal({super.key, required this.onSaved});

  static Future<void> show(BuildContext context, {required VoidCallback onSaved}) {
    // Show as Dialog on wide screens, BottomSheet on narrow screens
    final isTablet = MediaQuery.of(context).size.width >= 800;

    if (isTablet) {
      return showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SaveActivityModal(onSaved: onSaved),
          ),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SaveActivityModal(onSaved: onSaved),
      );
    }
  }

  @override
  State<SaveActivityModal> createState() => _SaveActivityModalState();
}

class _SaveActivityModalState extends State<SaveActivityModal> {
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController(text: 'General');

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _save(BuildContext context) async {
    final provider = Provider.of<StopwatchProvider>(context, listen: false);
    
    String title = _titleController.text.trim();
    String category = _categoryController.text.trim();

    if (title.isEmpty) title = 'Sesión sin título';
    if (category.isEmpty) category = 'General';

    await provider.saveActivity(
      title: title,
      category: category,
      notes: '',
    );
    
    if (context.mounted) {
      Navigator.of(context).pop();
      widget.onSaved();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.surface),
              const SizedBox(width: 8),
              const Text('Actividad guardada exitosamente', style: TextStyle(fontWeight: FontWeight.bold)),
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
            'Guardar Sesión',
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
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: '¿En qué vas a trabajar / medir?',
              prefixIcon: const Icon(Icons.auto_fix_high),
              filled: true,
              fillColor: theme.scaffoldBackgroundColor,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _categoryController,
            decoration: InputDecoration(
              labelText: 'Categoría',
              prefixIcon: const Icon(Icons.label_outline),
              filled: true,
              fillColor: theme.scaffoldBackgroundColor,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _save(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Categorizar y Guardar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
