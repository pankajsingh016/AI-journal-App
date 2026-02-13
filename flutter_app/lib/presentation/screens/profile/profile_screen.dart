import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:ai_journal/core/config/app_config.dart';
import 'package:ai_journal/core/config/routes/app_router.dart';
import 'package:ai_journal/core/config/theme/theme_palette.dart';
import 'package:ai_journal/data/models/user_model.dart';
import 'package:ai_journal/presentation/providers/auth_provider.dart';
import 'package:ai_journal/presentation/providers/entry_provider.dart';
import 'package:ai_journal/presentation/providers/preferences_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EntryProvider>().loadDrafts();
    });
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (xFile == null || !mounted) return;
    setState(() => _isUploadingAvatar = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.updateAvatar(xFile);
    if (!mounted) return;
    setState(() => _isUploadingAvatar = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Failed to update photo'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showChangePhotoOptions() {
    if (_isUploadingAvatar) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _draftsSubtitle(BuildContext context) {
    final p = context.watch<EntryProvider>();
    if (p.isLoading && p.drafts.isEmpty) return 'Loading…';
    if (p.error != null && p.drafts.isEmpty) return 'Tap to open';
    if (p.drafts.isEmpty) return 'No drafts yet';
    return '${p.drafts.length} draft${p.drafts.length == 1 ? '' : 's'}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prefs = context.watch<PreferencesProvider>();
    final user = auth.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Not signed in')),
      );
    }

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _UserCard(
              user: user,
              isUploading: _isUploadingAvatar,
              onAvatarTap: _showChangePhotoOptions,
            ),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Preferences'),
            const SizedBox(height: 8),
            _ThemeTile(prefs: prefs),
            SwitchListTile(
              title: const Text('Dark mode'),
              subtitle: const Text('Use dark theme'),
              value: prefs.theme == 'dark' ||
                  (prefs.theme == 'auto' &&
                      MediaQuery.platformBrightnessOf(context) == Brightness.dark),
              onChanged: (value) => prefs.setTheme(value ? 'dark' : 'light'),
            ),
            SwitchListTile(
              title: const Text('Daily reminder'),
              subtitle: const Text('Get a reminder to journal'),
              value: prefs.reminderEnabled,
              onChanged: prefs.setReminderEnabled,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.edit_note_outlined, color: Theme.of(context).colorScheme.primary),
              title: const Text('Drafts'),
              subtitle: Text(
                _draftsSubtitle(context),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/drafts'),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Log out'),
                    content: const Text(
                      'Are you sure you want to log out of ${AppConfig.appName}?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Log out'),
                      ),
                    ],
                  ),
                );
                if (context.mounted && ok == true) {
                  await auth.logout();
                  if (context.mounted) context.go('/login');
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.isUploading,
    required this.onAvatarTap,
  });

  final UserModel user;
  final bool isUploading;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final displayName = user.fullName?.trim().isNotEmpty == true
        ? user.fullName!
        : user.email.split('@').first;
    final memberSince = user.createdAt != null
        ? 'Member since ${_formatMonthYear(user.createdAt!)}'
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: isUploading ? null : onAvatarTap,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                        ? Text(
                            displayName.isNotEmpty
                                ? displayName.substring(0, 1).toUpperCase()
                                : '?',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          )
                        : null,
                  ),
                  if (isUploading)
                    Positioned.fill(
                      child: ClipOval(
                        child: Container(
                          color: Colors.black38,
                          child: const Center(
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!isUploading) ...[
              const SizedBox(height: 6),
              Text(
                'Tap to change photo',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              displayName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            if (memberSince != null) ...[
              const SizedBox(height: 8),
              Text(
                memberSince,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
            if (user.journalingGoal != null && user.journalingGoal!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _InfoChip(
                icon: Icons.flag_outlined,
                label: user.journalingGoal!,
              ),
            ],
            if (user.preferredJournalingTime != null &&
                user.preferredJournalingTime!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _InfoChip(
                icon: Icons.schedule_outlined,
                label: 'Preferred time: ${user.preferredJournalingTime}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatMonthYear(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

/// Single Theme row: shows theme name, opens sheet to pick theme name + dark mode toggle.
class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.prefs});

  final PreferencesProvider prefs;

  @override
  Widget build(BuildContext context) {
    final palette = ThemePalette.byId(prefs.colorTheme) ?? ThemePalette.getDefault();
    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: const Text('Theme'),
      subtitle: Text(palette.name),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeSheet(context),
    );
  }

  void _showThemeSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Consumer<PreferencesProvider>(
          builder: (_, prefs, __) {
            final theme = Theme.of(ctx);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Theme name',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...ThemePalette.all.map(
                    (palette) => ListTile(
                      title: Text(palette.name),
                      trailing: prefs.colorTheme == palette.id
                          ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                          : null,
                      onTap: () => prefs.setColorTheme(palette.id),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
