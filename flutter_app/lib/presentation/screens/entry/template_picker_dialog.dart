import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ai_journal/data/models/template_model.dart';
import 'package:ai_journal/presentation/providers/template_provider.dart';

/// Shows a list of templates (by category) and "Create own template".
/// Pops with [TemplateModel] when one is selected, or null when dismissed.
class TemplatePickerDialog extends StatefulWidget {
  const TemplatePickerDialog({super.key});

  @override
  State<TemplatePickerDialog> createState() => _TemplatePickerDialogState();
}

class _TemplatePickerDialogState extends State<TemplatePickerDialog> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TemplateProvider>().loadTemplates();
    });
  }

  Future<void> _openCreateTemplateSheet() async {
    final created = await showModalBottomSheet<TemplateModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => const _CreateTemplateSheet(),
    );
    if (created != null && mounted) {
      context.read<TemplateProvider>().loadTemplates(category: _selectedCategory);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxContentHeight = mediaQuery.size.height * 0.6;
    return AlertDialog(
      title: const Text('Choose a template'),
      content: SizedBox(
        width: double.maxFinite,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxContentHeight),
          child: Consumer<TemplateProvider>(
            builder: (context, provider, _) {
            if (provider.isLoading && provider.templates.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (provider.error != null && provider.templates.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(provider.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => provider.loadTemplates(category: _selectedCategory),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            // Prepend built-in example so users can try a template right away
            final fromProvider = _selectedCategory == null
                ? List<TemplateModel>.from(provider.templates)
                : provider.templates.where((t) => t.category == _selectedCategory).toList();
            final showExample = _selectedCategory == null || _selectedCategory == TemplateModel.example.category;
            final templates = showExample
                ? [TemplateModel.example, ...fromProvider]
                : fromProvider;

            final categorySet = <String>{...provider.templates.map((t) => t.category), TemplateModel.example.category};
            final categories = provider.categories.isNotEmpty
                ? List<String>.from(provider.categories)
                : (List<String>.from(categorySet)..sort());
            if (!categories.contains(TemplateModel.example.category)) {
              categories.add(TemplateModel.example.category);
              categories.sort();
            }

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Create own template
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                    title: const Text('Create own template'),
                    subtitle: const Text('Save a template from your current or new text'),
                    onTap: _openCreateTemplateSheet,
                  ),
                  const Divider(height: 24),
                  // Category filter
                  if (categories.length > 1) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _selectedCategory == null,
                          onSelected: (_) => setState(() => _selectedCategory = null),
                        ),
                        ...categories.map((c) => ChoiceChip(
                              label: Text(c),
                              selected: _selectedCategory == c,
                              onSelected: (_) => setState(() => _selectedCategory = c),
                            )),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Template list
                  ...templates.map((t) => _TemplateTile(
                        template: t,
                        onTap: () => Navigator.of(context).pop(t),
                      )),
                  if (templates.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No templates yet. Create one above or add system templates in Supabase.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({required this.template, required this.onTap});

  final TemplateModel template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: template.isSystem
              ? Theme.of(context).colorScheme.secondaryContainer
              : Theme.of(context).colorScheme.tertiaryContainer,
          child: Icon(
            template.isSystem ? Icons.description : Icons.edit_note,
            color: template.isSystem
                ? Theme.of(context).colorScheme.onSecondaryContainer
                : Theme.of(context).colorScheme.onTertiaryContainer,
          ),
        ),
        title: Text(template.name),
        subtitle: Text(
          template.description ?? template.category,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// Bottom sheet to create a user template. Pops with [TemplateModel] on success.
class _CreateTemplateSheet extends StatefulWidget {
  const _CreateTemplateSheet();

  @override
  State<_CreateTemplateSheet> createState() => _CreateTemplateSheetState();
}

class _CreateTemplateSheetState extends State<_CreateTemplateSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _category = 'custom';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a template name')),
      );
      return;
    }
    setState(() => _saving = true);
    final provider = context.read<TemplateProvider>();
    final created = await provider.createTemplate(
      name: name,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      category: _category,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
    );
    setState(() => _saving = false);
    if (!mounted) return;
    if (created != null) {
      Navigator.of(context).pop(created);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template saved')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to save template'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewPadding.bottom + 24,
          ),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                'Create your template',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Template name *',
                  hintText: 'e.g. Weekly review',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'When to use this template',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Default title (optional)',
                  hintText: 'Pre-fill entry title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Default content',
                  hintText: 'Pre-fill entry body. Leave blank to start from scratch.',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                minLines: 3,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save template'),
              ),
            ],
          ),
        );
      },
    );
  }
}
