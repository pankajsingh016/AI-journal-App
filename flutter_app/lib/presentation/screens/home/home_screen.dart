import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ai_journal/core/config/app_config.dart';
import 'package:ai_journal/core/config/theme/theme_extension.dart';
import 'package:ai_journal/presentation/providers/auth_provider.dart';
import 'package:ai_journal/presentation/providers/entry_provider.dart';
import 'package:ai_journal/presentation/screens/entry/entry_editor_screen.dart';

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

  late final ScrollController _calendarScrollController;

  @override
  void initState() {
    super.initState();
    _calendarScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ep = context.read<EntryProvider>();
      ep.loadUserStats();
      ep.loadCalendarDates();
    });
  }

  @override
  void dispose() {
    _calendarScrollController.dispose();
    super.dispose();
  }

  /// Finds the start date of the longest consecutive streak in [datesWithEntries].
  static DateTime? _longestStreakStartDate(Set<String> datesWithEntries) {
    if (datesWithEntries.isEmpty) return null;
    final sorted = datesWithEntries.toList()..sort();
    int bestLength = 1;
    String bestStart = sorted.first;
    int currentLength = 1;
    String currentStart = sorted.first;
    for (int i = 1; i < sorted.length; i++) {
      final prevDate = DateTime.parse(sorted[i - 1]);
      final currDate = DateTime.parse(sorted[i]);
      if (currDate.difference(prevDate).inDays == 1) {
        currentLength++;
      } else {
        if (currentLength > bestLength) {
          bestLength = currentLength;
          bestStart = currentStart;
        }
        currentLength = 1;
        currentStart = sorted[i];
      }
    }
    if (currentLength > bestLength) bestStart = currentStart;
    return DateTime.parse(bestStart);
  }

  void _scrollCalendarToDate(DateTime target) {
    if (!_calendarScrollController.hasClients) return;
    final today = DateTime.now();
    final start = today.subtract(const Duration(days: 60));
    final startDate = DateTime(start.year, start.month, start.day);
    final targetDate = DateTime(target.year, target.month, target.day);
    final index = targetDate.difference(startDate).inDays;
    final offset = (index * _calendarItemWidth).clamp(
      0.0,
      _calendarScrollController.position.maxScrollExtent,
    );
    _calendarScrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final entryProvider = context.watch<EntryProvider>();
    final name = auth.user?.fullName ?? auth.user?.email.split('@').first ?? 'there';

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await entryProvider.loadUserStats();
          await entryProvider.loadCalendarDates();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()}, $name',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Start your daily reflection',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              _SectionLabel(label: 'Journal calendar'),
              const SizedBox(height: 10),
              SizedBox(
                height: 88,
                child: JournalCalendarStrip(
                  datesWithEntries: entryProvider.datesWithEntries,
                  scrollController: _calendarScrollController,
                ),
              ),
              const SizedBox(height: 24),
              _StreakWidget(
                currentStreak: entryProvider.currentStreak,
                longestStreak: entryProvider.longestStreak,
                onSingleTap: () {
                  final date = _longestStreakStartDate(entryProvider.datesWithEntries);
                  if (date != null) _scrollCalendarToDate(date);
                },
                onDoubleTap: () => _scrollCalendarToDate(DateTime.now()),
              ),
              const SizedBox(height: 20),
              _SectionLabel(label: "Today's focus"),
              const SizedBox(height: 10),
              _PromptCard(
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
                    if (mounted) context.read<EntryProvider>()
                          ..loadUserStats()
                          ..loadCalendarDates();
                },
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
          if (mounted) context.read<EntryProvider>()
                          ..loadUserStats()
                          ..loadCalendarDates();
        },
        icon: const Icon(Icons.add),
        label: const Text('New entry'),
      ),
    );
  }
}

/// Small-caps style section label for hierarchy.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.8,
      ),
    );
  }
}

/// Today's prompt CTA card — clear, actionable.
class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.onTap});
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final appColors = AppThemeColors.of(context);
    final iconColor = isDark ? colorScheme.primary : appColors.inspiration;
    final iconBgColor = isDark ? colorScheme.primary.withValues(alpha: 0.2) : appColors.inspirationMuted;
    return Material(
      color: theme.cardTheme.color,
      shape: theme.cardTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onTap(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 28,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's prompt",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Get an AI prompt and start writing.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Streak card: single tap scrolls calendar to longest streak, double tap to today.
class _StreakWidget extends StatefulWidget {
  const _StreakWidget({
    required this.currentStreak,
    required this.longestStreak,
    this.onSingleTap,
    this.onDoubleTap,
  });

  final int currentStreak;
  final int longestStreak;
  final VoidCallback? onSingleTap;
  final VoidCallback? onDoubleTap;

  @override
  State<_StreakWidget> createState() => _StreakWidgetState();
}

class _StreakWidgetState extends State<_StreakWidget> {
  Timer? _singleTapTimer;

  @override
  void dispose() {
    _singleTapTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onDoubleTap != null && widget.onSingleTap != null) {
      _singleTapTimer?.cancel();
      _singleTapTimer = Timer(const Duration(milliseconds: 250), () {
        _singleTapTimer = null;
        if (mounted) widget.onSingleTap?.call();
      });
    } else {
      widget.onSingleTap?.call();
    }
  }

  void _handleDoubleTap() {
    _singleTapTimer?.cancel();
    _singleTapTimer = null;
    widget.onDoubleTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isZero = widget.currentStreak == 0 && widget.longestStreak == 0;

    Widget content = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isZero
              ? colorScheme.outline.withValues(alpha: 0.4)
              : AppThemeColors.of(context).success.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isZero ? colorScheme.outline : AppThemeColors.of(context).success)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isZero ? Icons.trending_up_rounded : Icons.local_fire_department_rounded,
              size: 28,
              color: isZero ? colorScheme.onSurfaceVariant : AppThemeColors.of(context).success,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Streak',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${widget.currentStreak}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                        letterSpacing: -0.5,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.currentStreak == 1 ? 'day' : 'days',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (widget.longestStreak > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Best: ${widget.longestStreak} days',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (isZero)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Write today to start.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.onSingleTap != null || widget.onDoubleTap != null) {
      return GestureDetector(
        onTap: widget.onSingleTap != null ? _handleTap : null,
        onDoubleTap: widget.onDoubleTap != null ? _handleDoubleTap : null,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }
    return content;
  }
}

const List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Width of each day card (SizedBox 56 + horizontal padding 4*2).
const double _calendarItemWidth = 64;

class JournalCalendarStrip extends StatefulWidget {
  const JournalCalendarStrip({
    super.key,
    required this.datesWithEntries,
    this.scrollController,
  });

  final Set<String> datesWithEntries;
  /// If provided, the parent can scroll the calendar (e.g. to longest streak or today).
  final ScrollController? scrollController;

  @override
  State<JournalCalendarStrip> createState() => _JournalCalendarStripState();
}

class _JournalCalendarStripState extends State<JournalCalendarStrip> {
  late final ScrollController _scrollController;
  bool _ownsController = false;

  static String _dateKey(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _ownsController = true;
    }
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
    if (_ownsController) _scrollController.dispose();
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
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: isToday
                ? colorScheme.primary.withValues(alpha: 0.14)
                : colorScheme.surfaceContainerHighest,
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
                            fontWeight: FontWeight.w700,
                            color: isToday
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _dayNames[d.weekday - 1],
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isToday
                                ? colorScheme.primary.withValues(alpha: 0.9)
                                : colorScheme.onSurfaceVariant,
                          ),
                    ),
                    if (hasEntry) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppThemeColors.of(context).success,
                          shape: BoxShape.circle,
                        ),
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
