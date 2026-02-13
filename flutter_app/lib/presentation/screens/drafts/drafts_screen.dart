import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:ai_journal/data/models/entry_model.dart';
import 'package:ai_journal/presentation/providers/entry_provider.dart';
import 'package:ai_journal/presentation/screens/entry/entry_editor_screen.dart';
import 'package:ai_journal/presentation/widgets/entry_card_actions.dart';

/// Full-page list of draft entries. Fetches from API on load and supports pull-to-refresh.
class DraftsScreen extends StatefulWidget {
  const DraftsScreen({super.key});

  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EntryProvider>().loadDrafts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drafts'),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: const _DraftsBody(),
    );
  }
}

class _DraftsBody extends StatelessWidget {
  const _DraftsBody();

  static String _draftTitle(EntryModel entry) {
    if (entry.title != null && entry.title!.trim().isNotEmpty) return entry.title!;
    final t = entry.content.trim();
    if (t.isEmpty) return 'Untitled draft';
    final line = t.split('\n').first.trim();
    return line.isEmpty ? 'Untitled draft' : (line.length > 50 ? '${line.substring(0, 50)}...' : line);
  }

  @override
  Widget build(BuildContext context) {
    final entryProvider = context.watch<EntryProvider>();
    final drafts = entryProvider.drafts;
    final isLoading = entryProvider.isLoading;
    final error = entryProvider.error;

    if (isLoading && drafts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && drafts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.read<EntryProvider>().loadDrafts(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (drafts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_note, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No drafts yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Drafts you save from the entry editor will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<EntryProvider>().loadDrafts(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        itemCount: drafts.length,
        itemBuilder: (context, index) {
          final entry = drafts[index];
          return _DraftTile(
            entry: entry,
            onDeleted: () => context.read<EntryProvider>().loadDrafts(),
          );
        },
      ),
    );
  }
}

class _DraftTile extends StatelessWidget {
  const _DraftTile({required this.entry, required this.onDeleted});

  final EntryModel entry;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final preview = entry.content.length > 120
        ? '${entry.content.substring(0, 120)}...'
        : entry.content;
    final date = entry.updatedAt ?? entry.createdAt;
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : entry.entryDate;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          _DraftsBody._draftTitle(entry),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: EntryCardActions(
          entry: entry,
          isDraft: true,
          onDeleted: onDeleted,
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => EntryEditorScreen(entry: entry),
            ),
          ).then((_) {
            if (context.mounted) context.read<EntryProvider>().loadDrafts();
          });
        },
      ),
    );
  }
}
