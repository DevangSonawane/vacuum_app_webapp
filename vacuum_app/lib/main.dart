import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/ui/app_settings_notifier.dart';
import 'shared/widgets/page_loader.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Prevent debug-time "Build scheduled during frame" assertions triggered
    // by the StretchingOverscrollIndicator's internal animation controller.
    return child;
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(appSettingsProvider);

    return settings.when(
      loading: () => const MaterialApp(home: PageLoader()),
      error: (error, _) => MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Failed to load settings: $error')),
        ),
      ),
      data: (darkMode) => MaterialApp.router(
        title: 'VDTI Service Hub',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
        scrollBehavior: const _AppScrollBehavior(),
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
