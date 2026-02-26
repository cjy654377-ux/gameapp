import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';

/// Root application widget.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: '몬스터 컬렉터',
      debugShowCheckedModeBanner: false,

      // Dark theme
      theme: AppTheme.getDarkTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: ThemeMode.dark,

      // Korean locale support
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],

      // Router
      routerConfig: router,
    );
  }
}
