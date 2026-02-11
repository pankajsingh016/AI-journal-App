import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:ai_journal/core/config/app_config.dart';
import 'package:ai_journal/core/config/routes/app_router.dart';
import 'package:ai_journal/data/models/entry_model.dart';
import 'package:ai_journal/presentation/providers/auth_provider.dart';
import 'package:ai_journal/presentation/providers/entry_provider.dart';
import 'package:ai_journal/presentation/screens/entries/entries_list_screen.dart';
import 'package:ai_journal/presentation/screens/entry/entry_editor_screen.dart';
import 'package:ai_journal/presentation/screens/profile/profile_screen.dart';
import 'package:ai_journal/presentation/screens/settings/settings_screen.dart';
import 'package:ai_journal/presentation/widgets/entry_card_actions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ep = context.read<EntryProvider>();
      ep.loadRecentEntries();
      ep.loadUserStats();
      ep.loadCalendarDates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final entryProvider = context.watch<EntryProvider>();
    final recentEntries = entryProvider.recentEntries;
    final listError = entryProvider.error;
    final name = auth.user?.fullName ?? auth.user?.email.split('@').first ?? 'there';

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              rootNavigatorKey.currentState?.push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              rootNavigatorKey.currentState?.push(
                MaterialPageRoute<void>(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await entryProvider.loadRecentEntries();
          await entryProvider.loadUserStats();
          await entryProvider.loadCalendarDates();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()}, $name',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start your daily reflection',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              Text(
                'Journal calendar',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 88,
                child: JournalCalendarStrip(datesWithEntries: entryProvider.datesWithEntries),
              ),
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.local_fire_department)),
                  title: const Text('Your streaks'),
                  subtitle: Text(
                    'Streak till today: ${entryProvider.currentStreak} day${entryProvider.currentStreak == 1 ? '' : 's'}\nBest: ${entryProvider.longestStreak} day${entryProvider.longestStreak == 1 ? '' : 's'}${entryProvider.currentStreak == 0 && entryProvider.longestStreak == 0 ? ' – keep writing!' : ''}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.edit_note, size: 40),
                  title: const Text("Today's prompt"),
                  subtitle: const Text('Tap to get an AI prompt and start writing.'),
                  onTap: () async {
                    final entryProvider = context.read<EntryProvider>();
                    String? prompt;
                    try {
                      prompt = await entryProvider.getInspirationPrompt();
                    } catch (_) {}
                    if (!mounted) return;
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => EntryEditorScreen(initialPrompt: prompt),
                      ),
                    );
                    if (mounted) context.read<EntryProvider>().loadRecentEntries();
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent entries',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const EntriesListScreen(),
                        ),
                      );
                    },
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (listError != null && recentEntries.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          listError,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => entryProvider.loadRecentEntries(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (recentEntries.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No entries yet. Tap the button below to create your first entry.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...recentEntries.map(
                  (e) => _RecentEntryTile(entry: e),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => const EntryEditorScreen(),
            ),
          );
          if (mounted) context.read<EntryProvider>().loadRecentEntries();
        },
        icon: const Icon(Icons.add),
        label: const Text('New entry'),
      ),
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

class _RecentEntryTile extends StatelessWidget {
  const _RecentEntryTile({required this.entry});

  final EntryModel entry;

  @override
  Widget build(BuildContext context) {
    final date = entry.updatedAt ?? entry.createdAt;
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : entry.entryDate;
    final preview = entry.content.length > 80
        ? '${entry.content.trim().replaceAll('\n', ' ').substring(0, 80)}...'
        : entry.content.trim().replaceAll('\n', ' ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          _entryTitle(entry),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
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
          isDraft: false,
          onDeleted: () => context.read<EntryProvider>().loadRecentEntries(),
        ),
        onTap: () async {
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => EntryEditorScreen(entry: entry),
            ),
          );
          if (context.mounted) {
            context.read<EntryProvider>().loadRecentEntries();
          }
        },
      ),
    );
  }
}

const List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Width of each day card (SizedBox 56 + horizontal padding 4*2).
const double _calendarItemWidth = 64;

class JournalCalendarStrip extends StatefulWidget {
  const JournalCalendarStrip({super.key, required this.datesWithEntries});

  final Set<String> datesWithEntries;

  @override
  State<JournalCalendarStrip> createState() => _JournalCalendarStripState();
}

class _JournalCalendarStripState extends State<JournalCalendarStrip> {
  final ScrollController _scrollController = ScrollController();

  static String _dateKey(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final today = DateTime.now();
      final start = today.subtract(const Duration(days: 60));
      final todayIndex = today.difference(DateTime(start.year, start.month, start.day)).inDays;
      final offset = (todayIndex * _calendarItemWidth).toDouble();
      _scrollController.jumpTo(offset.clamp(0.0, _scrollController.position.maxScrollExtent));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final start = today.subtract(const Duration(days: 60));
    final days = <DateTime>[];
    for (var d = start; d.isBefore(today.add(const Duration(days: 31))) || d.isAtSameMomentAs(today.add(const Duration(days: 31))); d = d.add(const Duration(days: 1))) {
      days.add(d);
    }
    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final d = days[index];
        final dateKey = _dateKey(d);
        final hasEntry = widget.datesWithEntries.contains(dateKey);
        final isToday = d.year == today.year && d.month == today.month && d.day == today.day;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: isToday
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {},
              child: SizedBox(
                width: 56,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${d.day}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isToday
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _dayNames[d.weekday - 1],
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isToday
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    if (hasEntry) ...[
                      const SizedBox(height: 4),
                      Icon(
                        Icons.local_fire_department,
                        size: 20,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
