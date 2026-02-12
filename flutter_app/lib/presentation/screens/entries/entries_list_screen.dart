import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:ai_journal/data/models/entry_model.dart';
import 'package:ai_journal/presentation/providers/entry_provider.dart';
import 'package:ai_journal/presentation/screens/entry/entry_editor_screen.dart';
import 'package:ai_journal/presentation/widgets/entry_card_actions.dart';

/// All published entries, latest first.
class EntriesListScreen extends StatefulWidget {
  const EntriesListScreen({super.key});

  @override
  State<EntriesListScreen> createState() => _EntriesListScreenState();
}

class _EntriesListScreenState extends State<EntriesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EntryProvider>().loadAllEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final entryProvider = context.watch<EntryProvider>();
    final entries = entryProvider.allEntries;
    final isLoading = entryProvider.isLoading;
    final error = entryProvider.error;

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        leading: ModalRoute.of(context)?.canPop == true
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () => entryProvider.loadAllEntries(),
        child: _buildBody(context, entries, isLoading, error, entryProvider),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<EntryModel> entries,
    bool isLoading,
    String? error,
    EntryProvider entryProvider,
  ) {
    if (isLoading && entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => entryProvider.loadAllEntries(),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.edit_note_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 20),
              Text(
                'No entries yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Published entries will appear here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _EntryListTile(entry: entry);
      },
    );
  }
}

String _entryTitle(EntryModel e) {
  if (e.title != null && e.title!.trim().isNotEmpty) return e.title!;
  final t = e.content.trim();
  if (t.isEmpty) return 'Untitled';
  final first = t.split('\n').first.trim();
  return first.length > 40 ? '${first.substring(0, 40)}...' : first;
}

class _EntryListTile extends StatelessWidget {
  const _EntryListTile({required this.entry});

  final EntryModel entry;

  @override
  Widget build(BuildContext context) {
    final date = entry.updatedAt ?? entry.createdAt;
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : entry.entryDate;
    final preview = entry.content.length > 100
        ? '${entry.content.trim().replaceAll('\n', ' ').substring(0, 100)}...'
        : entry.content.trim().replaceAll('\n', ' ');
    final firstMediaUrl = entry.media != null && entry.media!.isNotEmpty
        ? entry.media!.first.url
        : null;

    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: firstMediaUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  firstMediaUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      width: 56,
                      height: 56,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.photo_library_outlined,
                    size: 40,
                    color: theme.colorScheme.outline,
                  ),
                ),
              )
            : null,
        title: Text(
          _entryTitle(entry),
          style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dateStr,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: EntryCardActions(
          entry: entry,
          isDraft: false,
          onDeleted: () => context.read<EntryProvider>().loadAllEntries(),
        ),
        onTap: () async {
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => EntryEditorScreen(entry: entry),
            ),
          );
          if (context.mounted) {
            context.read<EntryProvider>().loadAllEntries();
          }
        },
      ),
    );
  }
}
