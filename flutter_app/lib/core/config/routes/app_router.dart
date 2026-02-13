import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:ai_journal/presentation/providers/auth_provider.dart';
import 'package:ai_journal/presentation/screens/auth/login_screen.dart';
import 'package:ai_journal/presentation/screens/auth/signup_screen.dart';
import 'package:ai_journal/presentation/screens/entries/entries_for_date_screen.dart';
import 'package:ai_journal/presentation/screens/entries/entries_list_screen.dart';
import 'package:ai_journal/presentation/screens/drafts/drafts_screen.dart';
import 'package:ai_journal/presentation/screens/entry/entry_editor_screen.dart';
import 'package:ai_journal/presentation/screens/home/home_screen.dart';
import 'package:ai_journal/presentation/screens/main/main_shell.dart';
import 'package:ai_journal/presentation/screens/profile/profile_screen.dart';

/// Global key for the root navigator (used by GoRouter).
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
          builder: (context, state) {
            final initialPrompt = state.extra as String?;
            return EntryEditorScreen(initialPrompt: initialPrompt);
          },
        ),
        GoRoute(
          path: '/entries/date/:dateKey',
          builder: (_, state) {
            final dateKey = state.pathParameters['dateKey'] ?? '';
            return EntriesForDateScreen(dateKey: dateKey);
          },
        ),
        GoRoute(
          path: '/drafts',
          builder: (_, __) => const DraftsScreen(),
        ),
      ],
    );
  }
}
