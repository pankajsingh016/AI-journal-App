import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:ai_journal/data/models/entry_model.dart';
import 'package:ai_journal/presentation/providers/auth_provider.dart';
import 'package:ai_journal/presentation/screens/entry/entry_editor_screen.dart';
import 'package:ai_journal/presentation/providers/entry_provider.dart';
import 'package:ai_journal/presentation/providers/preferences_provider.dart';
import 'package:ai_journal/presentation/widgets/entry_card_actions.dart';

/// Settings screen: tab 1 = basic settings (theme, reminders, account), tab 2 = drafts list.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PreferencesProvider>().loadPreferences();
      context.read<EntryProvider>().loadDrafts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Settings', icon: Icon(Icons.settings_outlined)),
            Tab(text: 'Drafts', icon: Icon(Icons.edit_note)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SettingsTab(),
          _DraftsTab(),
        ],
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();
    final auth = context.watch<AuthProvider>();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Appearance',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ListTile(
          title: const Text('Theme'),
          subtitle: Text(_themeLabel(prefs.theme)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            showModalBottomSheet<String>(
              context: context,
              builder: (ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('System'),
                      onTap: () => Navigator.pop(ctx, 'auto'),
                    ),
                    ListTile(
                      title: const Text('Light'),
                      onTap: () => Navigator.pop(ctx, 'light'),
                    ),
                    ListTile(
                      title: const Text('Dark'),
                      onTap: () => Navigator.pop(ctx, 'dark'),
                    ),
                  ],
                ),
              ),
            ).then((v) {
              if (v != null) prefs.setTheme(v);
            });
          },
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'Notifications',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('Daily reminder'),
          subtitle: const Text('Get a reminder to journal'),
          value: prefs.reminderEnabled,
          onChanged: (v) => prefs.setReminderEnabled(v),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'Account',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ListTile(
          title: const Text('Email'),
          subtitle: Text(auth.user?.email ?? '—'),
        ),
        ListTile(
          title: const Text('Log out'),
          leading: const Icon(Icons.logout_outlined),
          onTap: () async {
            await auth.logout();
            if (context.mounted) context.go('/login');
          },
        ),
      ],
    );
  }

  String _themeLabel(String theme) {
    switch (theme) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      default:
        return 'System';
    }
  }
}

class _DraftsTab extends StatelessWidget {
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
                onPressed: () => entryProvider.loadDrafts(),
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
            Text(
              'Drafts you save from the entry editor will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => entryProvider.loadDrafts(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        itemCount: drafts.length,
        itemBuilder: (context, index) {
          final entry = drafts[index];
          return _DraftTile(entry: entry);
        },
      ),
    );
  }
}

/// Title for draft card: from content (first line or first 50 chars), fallback "Untitled draft".
String _draftTitleFromContent(EntryModel entry) {
  if (entry.title != null && entry.title!.trim().isNotEmpty) return entry.title!;
  final trimmed = entry.content.trim();
  if (trimmed.isEmpty) return 'Untitled draft';
  final firstLine = trimmed.split('\n').first.trim();
  if (firstLine.isEmpty) return 'Untitled draft';
  return firstLine.length > 50 ? '${firstLine.substring(0, 50)}...' : firstLine;
}

class _DraftTile extends StatelessWidget {
  const _DraftTile({required this.entry});

  final EntryModel entry;

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
          _draftTitleFromContent(entry),
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
          onDeleted: () => context.read<EntryProvider>().loadDrafts(),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => EntryEditorScreen(entry: entry),
            ),
          );
        },
      ),
    );
  }
}
