import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:ai_journal/presentation/providers/auth_provider.dart';
import 'package:ai_journal/presentation/screens/auth/login_screen.dart';
import 'package:ai_journal/presentation/screens/auth/signup_screen.dart';
import 'package:ai_journal/presentation/screens/entry/entry_editor_screen.dart';
import 'package:ai_journal/presentation/screens/home/home_screen.dart';

class AppRouter {
  static GoRouter createRouter(BuildContext context) {
    return GoRouter(
      initialLocation: '/login',
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
        GoRoute(
          path: '/',
          builder: (_, __) => const HomeScreen(),
        ),
        GoRoute(
          path: '/entry/new',
          builder: (_, __) => const EntryEditorScreen(),
        ),
      ],
    );
  }
}
