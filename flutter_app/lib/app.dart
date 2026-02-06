import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ai_journal/core/config/theme/app_theme.dart';
import 'package:ai_journal/core/config/routes/app_router.dart';
import 'package:ai_journal/presentation/providers/auth_provider.dart';
import 'package:ai_journal/presentation/providers/entry_provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => EntryProvider()..init()),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            title: 'AI Journal',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.system,
            routerConfig: AppRouter.createRouter(context),
          );
        },
      ),
    );
  }
}
