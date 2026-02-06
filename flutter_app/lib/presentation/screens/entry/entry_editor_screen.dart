import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:ai_journal/presentation/providers/entry_provider.dart';

/// New journal entry: writing pad + bottom bar (Add photos, Use templates, Ask inspiration).
/// Bottom bar stays at visual bottom and moves up with the keyboard.
class EntryEditorScreen extends StatefulWidget {
  const EntryEditorScreen({super.key});

  @override
  State<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends State<EntryEditorScreen> {
  final _contentController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _contentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _askInspiration() async {
    final entryProvider = context.read<EntryProvider>();
    final prompt = await entryProvider.getInspirationPrompt();
    if (!mounted) return;
    if (prompt != null && prompt.isNotEmpty) {
      final before = _contentController.text;
      final insert = before.isEmpty ? prompt : '\n\n$prompt';
      _contentController.text = before + insert;
      _contentController.selection = TextSelection.collapsed(offset: _contentController.text.length);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inspiration added to your entry')),
      );
    } else if (entryProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(entryProvider.error!), backgroundColor: Colors.red),
      );
    }
  }

  void _addPhotos() {
    // TODO: image_picker and attach to entry
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add photos – coming soon')),
    );
  }

  void _useTemplates() {
    // TODO: open template picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Templates – coming soon')),
    );
  }

  Future<void> _saveDraft() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something to save')),
      );
      return;
    }
    final entryProvider = context.read<EntryProvider>();
    final entry = await entryProvider.saveEntry(content: content, isDraft: true);
    if (!mounted) return;
    if (entry != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft saved')),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(entryProvider.error ?? 'Failed to save'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _publish() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something to publish')),
      );
      return;
    }
    final entryProvider = context.read<EntryProvider>();
    final entry = await entryProvider.saveEntry(content: content, isDraft: false);
    if (!mounted) return;
    if (entry != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry published')),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(entryProvider.error ?? 'Failed to save'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('New entry'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            if (_contentController.text.trim().isNotEmpty) {
              final leave = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Discard draft?'),
                  content: const Text('You have unsaved changes. Discard?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep editing')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard')),
                  ],
                ),
              );
              if (leave == true && mounted) context.pop();
            } else {
              context.pop();
            }
          },
        ),
        actions: [
          TextButton(onPressed: _saveDraft, child: const Text('Save draft')),
          const SizedBox(width: 8),
          FilledButton(onPressed: _publish, child: const Text('Publish')),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Writing pad
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _contentController,
                focusNode: _focusNode,
                maxLines: null,
                minLines: 12,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                decoration: const InputDecoration(
                  hintText: 'What\'s on your mind? Start writing your reflection...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
          ),
          // Bottom bar: Add photos, Use templates, Ask inspiration (dynamic position above keyboard)
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Row(
                children: [
                  _BottomBarChip(
                    icon: Icons.add_photo_alternate_outlined,
                    label: 'Add photos',
                    onTap: _addPhotos,
                  ),
                  const SizedBox(width: 12),
                  _BottomBarChip(
                    icon: Icons.description_outlined,
                    label: 'Use templates',
                    onTap: _useTemplates,
                  ),
                  const SizedBox(width: 12),
                  _BottomBarChip(
                    icon: Icons.auto_awesome,
                    label: 'Ask inspiration',
                    onTap: _askInspiration,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBarChip extends StatelessWidget {
  const _BottomBarChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.6),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}
