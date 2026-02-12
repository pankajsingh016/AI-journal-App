import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:ai_journal/presentation/providers/auth_provider.dart';
import 'package:ai_journal/presentation/screens/auth/login_screen.dart';
import 'package:ai_journal/presentation/screens/auth/signup_screen.dart';
import 'package:ai_journal/presentation/screens/entries/entries_list_screen.dart';
import 'package:ai_journal/presentation/screens/entry/entry_editor_screen.dart';
import 'package:ai_journal/presentation/screens/home/home_screen.dart';
import 'package:ai_journal/presentation/screens/main/main_shell.dart';
import 'package:ai_journal/presentation/screens/profile/profile_screen.dart';
import 'package:ai_journal/presentation/screens/settings/settings_screen.dart';

/// Global key for the root navigator (used by GoRouter). Use this to push
/// routes that must appear on top of the current screen (e.g. Settings).
final rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static GoRouter createRouter(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/login',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        final isAuth = auth.isLoggedIn;
        final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
        if (!isAuth && !isAuthRoute) return '/login';
        if (isAuth && isAuthRoute) return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (_, __) => const SignupScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, __) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/history',
                  builder: (_, __) => const EntriesListScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (_, __) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/entry/new',
          builder: (_, __) => const EntryEditorScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, __) => const SettingsScreen(),
        ),
      ],
    );
  }
}
