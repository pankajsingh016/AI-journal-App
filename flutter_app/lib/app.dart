import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:ai_journal/core/config/theme/app_theme.dart';
import 'package:ai_journal/core/config/routes/app_router.dart';
import 'package:ai_journal/presentation/providers/auth_provider.dart';
import 'package:ai_journal/presentation/providers/entry_provider.dart';
import 'package:ai_journal/presentation/providers/preferences_provider.dart';

/// Caches [GoRouter] so it is created once. Recreating it on every build broke navigation (e.g. settings icon).
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => EntryProvider()..init()),
        ChangeNotifierProvider(create: (_) => PreferencesProvider()..init()),
      ],
      child: const _AppRouterScope(),
    );
  }
}

class _AppRouterScope extends StatefulWidget {
  const _AppRouterScope();

  @override
  State<_AppRouterScope> createState() => _AppRouterScopeState();
}

class _AppRouterScopeState extends State<_AppRouterScope> {
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router ??= AppRouter.createRouter(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_router == null) return const SizedBox.shrink();
    final prefs = context.watch<PreferencesProvider>();
    final themeMode = prefs.themeMode;
    final colorThemeId = prefs.colorTheme;
    return MaterialApp.router(
      title: 'AI Journal',
      theme: AppTheme.light(colorThemeId),
      darkTheme: AppTheme.dark(colorThemeId),
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
