import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:ai_journal/core/config/app_config.dart';
import 'package:ai_journal/data/models/entry_model.dart';
import 'package:ai_journal/presentation/providers/entry_provider.dart';
import 'package:ai_journal/presentation/screens/entry/entry_editor_screen.dart';
import 'package:ai_journal/presentation/widgets/entry_card_actions.dart';

/// Shows all journal entries written on a specific day.
/// Uses the same layout as History: day heading + journal cards with thumbnail, title, preview.
class EntriesForDateScreen extends StatefulWidget {
  const EntriesForDateScreen({super.key, required this.dateKey});

  final String dateKey;

  @override
  State<EntriesForDateScreen> createState() => _EntriesForDateScreenState();
}

class _EntriesForDateScreenState extends State<EntriesForDateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EntryProvider>().loadEntriesForDate(widget.dateKey);
    });
  }

  static String _formatDayHeading(String dateKey) {
    try {
      final parts = dateKey.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          final dt = DateTime(y, m, d);
          return DateFormat('EEEE, MMM d, yyyy').format(dt);
        }
      }
    } catch (_) {}
    return dateKey;
  }

  @override
  Widget build(BuildContext context) {
    final entryProvider = context.watch<EntryProvider>();
    final entries = entryProvider.entriesForDate;
    final isLoading = entryProvider.isLoading;
    final error = entryProvider.error;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDayHeading(widget.dateKey)),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => entryProvider.loadEntriesForDate(widget.dateKey),
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
                onPressed: () => entryProvider.loadEntriesForDate(widget.dateKey),
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
                'No entries on this day',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Journals written on this date will appear here.',
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

    // Same layout as History: day heading + journal cards
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            _formatDayHeading(widget.dateKey),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
              letterSpacing: -0.2,
              fontSize: 20,
            ),
          ),
        ),
        ...entries.map(
          (entry) => _JournalCard(
            entry: entry,
            onDeleted: () => entryProvider.loadEntriesForDate(widget.dateKey),
            onTapThenRefresh: () => entryProvider.loadEntriesForDate(widget.dateKey),
          ),
        ),
      ],
    );
  }
}

String _entryTitle(EntryModel e) {
  if (e.title != null && e.title!.trim().isNotEmpty) return e.title!;
  final t = e.content.trim();
  if (t.isEmpty) return 'Untitled';
  final first = t.split('\n').first.trim();
  return first.length > 50 ? '${first.substring(0, 50)}...' : first;
}

String _entryPreview(EntryModel e, {int maxChars = 90}) {
  final t = e.content.trim().replaceAll('\n', ' ');
  if (t.isEmpty) return '';
  return t.length > maxChars ? '${t.substring(0, maxChars)}...' : t;
}

String _mediaUrl(String url) => AppConfig.rewriteMediaUrl(url);

class _JournalCard extends StatelessWidget {
  const _JournalCard({
    required this.entry,
    required this.onDeleted,
    required this.onTapThenRefresh,
  });

  final EntryModel entry;
  final VoidCallback onDeleted;
  final VoidCallback onTapThenRefresh;

  static const List<String> _noImagePhrases = [
    'Just words',
    'Words only',
    'Thoughts only',
  ];

  static String _noImagePhrase(String entryId) {
    final i = entryId.hashCode.abs() % _noImagePhrases.length;
    return _noImagePhrases[i];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstMediaUrl = entry.media != null && entry.media!.isNotEmpty
        ? _mediaUrl(entry.media!.first.url)
        : null;
    final title = _entryTitle(entry);
    final preview = _entryPreview(entry);
    final date = entry.updatedAt ?? entry.createdAt;
    final dateStr = date != null
        ? DateFormat('MMM d · h:mm a').format(date)
        : entry.entryDate;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => EntryEditorScreen(entry: entry),
            ),
          );
          if (context.mounted) onTapThenRefresh();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: firstMediaUrl != null
                      ? Image.network(
                          firstMediaUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
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
                          errorBuilder: (_, __, ___) => _NoImagePlaceholder(
                            phrase: _noImagePhrase(entry.id),
                            theme: theme,
                          ),
                        )
                      : _NoImagePlaceholder(
                          phrase: _noImagePhrase(entry.id),
                          theme: theme,
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 12,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  EntryCardActions(
                    entry: entry,
                    isDraft: false,
                    onDeleted: onDeleted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoImagePlaceholder extends StatelessWidget {
  const _NoImagePlaceholder({required this.phrase, required this.theme});

  final String phrase;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final hue = (phrase.hashCode.abs() % 360).toDouble();
    final softColor = HSLColor.fromAHSL(1, hue, 0.08, 0.96).toColor();
    final accentColor = HSLColor.fromAHSL(1, hue, 0.25, 0.75).toColor();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            softColor,
            theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DotPatternPainter(
                color: accentColor.withOpacity(0.12),
                spacing: 14,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  size: 28,
                  color: accentColor.withOpacity(0.85),
                ),
                const SizedBox(height: 4),
                Text(
                  phrase,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accentColor.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  _DotPatternPainter({required this.color, this.spacing = 12});

  final Color color;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var x = 0.0; x < size.width; x += spacing) {
      for (var y = 0.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
