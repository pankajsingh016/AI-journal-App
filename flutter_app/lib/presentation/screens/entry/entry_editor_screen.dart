import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ai_journal/data/models/entry_model.dart';
import 'package:ai_journal/presentation/providers/entry_provider.dart';

/// New or edit journal entry: writing pad + bottom bar.
/// When [entry] is non-null, shows existing content and updates on save.
/// [initialPrompt] pre-fills the content when starting a new entry (e.g. from Today's prompt).
class EntryEditorScreen extends StatefulWidget {
  const EntryEditorScreen({super.key, this.entry, this.initialPrompt});

  final EntryModel? entry;
  /// Optional prompt text to pre-fill content when creating a new entry.
  final String? initialPrompt;

  @override
  State<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends State<EntryEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final initialContent = widget.entry?.content ?? widget.initialPrompt ?? '';
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _contentController = TextEditingController(text: initialContent);
  }

  @override
  void dispose() {
    _titleController.dispose();
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
    final saved = await entryProvider.saveEntry(
      entryId: widget.entry?.id,
      content: content,
      title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
      isDraft: true,
    );
    if (!mounted) return;
    if (saved != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft saved')),
      );
      // Only pop when creating a new draft; when editing existing draft stay so changes are visible
      if (widget.entry == null) {
        Navigator.of(context).pop();
      }
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
    final saved = await entryProvider.saveEntry(
      entryId: widget.entry?.id,
      content: content,
      title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
      isDraft: false,
    );
    if (!mounted) return;
    if (saved != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry published')),
      );
      await entryProvider.loadRecentEntries();
      await entryProvider.loadUserStats();
      await entryProvider.loadCalendarDates();
      if (!mounted) return;
      Navigator.of(context).pop();
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
        title: Text(widget.entry != null ? 'Edit draft' : 'New entry'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            if (_titleController.text.trim().isNotEmpty || _contentController.text.trim().isNotEmpty) {
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
              if (leave == true && mounted) Navigator.of(context).pop();
            } else {
              Navigator.of(context).pop();
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
          // Writing pad – title + content (Notion-style)
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _titleController,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Title',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contentController,
                    focusNode: _focusNode,
                    maxLines: null,
                    minLines: 12,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                    decoration: InputDecoration(
                      hintText: "What's on your mind? Start writing your Journal",
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom bar: scrollable so it never overflows (e.g. when keyboard is up)
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 72),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
