import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/settings_model.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _sectionHeader('Browsing'),
          SwitchListTile(
            title: const Text('Desktop Mode'),
            subtitle: const Text('Load websites in desktop layout'),
            value: settings.uaMode == UaMode.desktop,
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .setUaMode(v ? UaMode.desktop : UaMode.mobile),
          ),
          ListTile(
            title: const Text('Search Engine'),
            subtitle: Text(settings.searchEngine),
            onTap: () => _showSearchEnginePicker(context, ref, settings),
          ),
          ListTile(
            title: const Text('Home Page'),
            subtitle: Text(settings.homeUrl),
            onTap: () => _showHomeUrlEditor(context, ref, settings),
          ),
          ListTile(
            title: const Text('Viewport Width'),
            subtitle: Text('${settings.viewportWidth}px'),
            onTap: () => _showViewportPicker(context, ref, settings),
          ),
          _sectionHeader('Zoom'),
          ListTile(
            title: const Text('Default Zoom'),
            subtitle: Text('${(settings.defaultZoom * 100).round()}%'),
          ),
          _sectionHeader('Privacy'),
          ListTile(
            title: const Text('Clear Cookies'),
            leading: const Icon(Icons.cookie_outlined),
            onTap: () async {
              await CookieManager.instance().deleteAllCookies();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cookies cleared')),
                );
              }
            },
          ),
          ListTile(
            title: const Text('Clear Cache'),
            leading: const Icon(Icons.cached),
            onTap: () async {
              await InAppWebViewController.clearAllCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared')),
                );
              }
            },
          ),
          _sectionHeader('Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: settings.darkMode,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setDarkMode(v),
          ),
          _sectionHeader('About'),
          const ListTile(
            title: Text('ZoomView Browser'),
            subtitle: Text('Version 1.0.0'),
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
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Search Engine'),
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
    final controller = TextEditingController(text: settings.homeUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Home Page URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'https://...'),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).setHomeUrl(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showViewportPicker(
      BuildContext context, WidgetRef ref, SettingsModel settings) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Viewport Width'),
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
                        title: Text('${w}px'),
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
