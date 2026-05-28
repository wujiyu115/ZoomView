import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/browser/widgets/browser_screen.dart';
import 'l10n/app_localizations.dart';

class ZoomViewApp extends ConsumerWidget {
  const ZoomViewApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'ZoomView',
      debugShowCheckedModeBanner: false,
      theme: settings.darkMode ? AppTheme.dark() : AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const BrowserScreen(),
    );
  }
}
