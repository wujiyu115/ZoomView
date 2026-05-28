import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:zoomview/l10n/app_localizations.dart';
import '../models/settings_model.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        children: [
          _sectionHeader(l.browsing),
          SwitchListTile(
            title: Text(l.desktopMode),
            subtitle: Text(l.desktopModeSubtitle),
            value: settings.uaMode == UaMode.desktop,
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .setUaMode(v ? UaMode.desktop : UaMode.mobile),
          ),
          ListTile(
            title: Text(l.searchEngine),
            subtitle: Text(settings.searchEngine),
            onTap: () => _showSearchEnginePicker(context, ref, settings),
          ),
          ListTile(
            title: Text(l.homePage),
            subtitle: Text(settings.homeUrl),
            onTap: () => _showHomeUrlEditor(context, ref, settings),
          ),
          ListTile(
            title: Text(l.viewportWidth),
            subtitle: Text(l.viewportWidthValue(settings.viewportWidth)),
            onTap: () => _showViewportPicker(context, ref, settings),
          ),
          _sectionHeader(l.zoom),
          ListTile(
            title: Text(l.defaultZoom),
            subtitle: Text(l.zoomPercent((settings.defaultZoom * 100).round())),
          ),
          _sectionHeader(l.privacy),
          ListTile(
            title: Text(l.clearCookies),
            leading: const Icon(Icons.cookie_outlined),
            onTap: () async {
              await CookieManager.instance().deleteAllCookies();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.cookiesCleared)),
                );
              }
            },
          ),
          ListTile(
            title: Text(l.clearCache),
            leading: const Icon(Icons.cached),
            onTap: () async {
              await InAppWebViewController.clearAllCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.cacheCleared)),
                );
              }
            },
          ),
          _sectionHeader(l.appearance),
          SwitchListTile(
            title: Text(l.darkMode),
            value: settings.darkMode,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setDarkMode(v),
          ),
          _sectionHeader(l.about),
          ListTile(
            title: Text(l.zoomViewBrowser),
            subtitle: Text(l.version('1.0.0')),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  void _showSearchEnginePicker(
      BuildContext context, WidgetRef ref, SettingsModel settings) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.searchEngine),
        children: [
          RadioGroup<String>(
            groupValue: settings.searchEngine,
            onChanged: (v) {
              if (v != null) {
                ref.read(settingsProvider.notifier).setSearchEngine(v);
                Navigator.pop(ctx);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ['Google', 'Bing', 'DuckDuckGo']
                  .map((e) => RadioListTile<String>(
                        title: Text(e),
                        value: e,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showHomeUrlEditor(
      BuildContext context, WidgetRef ref, SettingsModel settings) {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: settings.homeUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.homePageUrl),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: l.urlHint),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).setHomeUrl(controller.text);
              Navigator.pop(ctx);
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }

  void _showViewportPicker(
      BuildContext context, WidgetRef ref, SettingsModel settings) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.viewportWidth),
        children: [
          RadioGroup<int>(
            groupValue: settings.viewportWidth,
            onChanged: (v) {
              if (v != null) {
                ref.read(settingsProvider.notifier).setViewportWidth(v);
                Navigator.pop(ctx);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [1280, 1920, 2560]
                  .map((w) => RadioListTile<int>(
                        title: Text(l.viewportWidthValue(w)),
                        value: w,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
