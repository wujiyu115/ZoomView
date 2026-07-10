import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:zoomview/core/extensions.dart';
import 'package:zoomview/core/widgets/ios_nav_header.dart';
import 'package:zoomview/core/widgets/grouped_card.dart';
import 'package:zoomview/core/widgets/colored_icon_box.dart';
import 'package:zoomview/core/widgets/ios_toggle.dart';
import 'package:zoomview/core/widgets/section_header.dart';
import 'package:zoomview/l10n/app_localizations.dart';
import '../models/settings_model.dart';
import '../providers/settings_provider.dart';
import 'dev_log_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final colors = context.appColors;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            IosNavHeader(title: l.settings),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  SectionHeader(label: l.browsing, useAccentColor: true),
                  GroupedCard(
                    children: [
                      _SettingsRow(
                        icon: Icons.desktop_mac,
                        iconColor: const Color(0xFF0969DA),
                        title: l.desktopMode,
                        subtitle: l.desktopModeSubtitle,
                        trailing: IosToggle(
                          value: settings.uaMode == UaMode.desktop,
                          onChanged: (v) => ref
                              .read(settingsProvider.notifier)
                              .setUaMode(v ? UaMode.desktop : UaMode.mobile),
                        ),
                      ),
                      _SettingsRow(
                        icon: Icons.search,
                        iconColor: const Color(0xFF8250DF),
                        title: l.searchEngine,
                        value: settings.searchEngine,
                        onTap: () => _showSearchEnginePicker(context, ref, settings),
                      ),
                      _SettingsRow(
                        icon: Icons.home,
                        iconColor: const Color(0xFF17A34A),
                        title: l.homePage,
                        value: settings.homeUrl,
                        onTap: () => _showHomeUrlEditor(context, ref, settings),
                      ),
                      _SettingsRow(
                        icon: Icons.aspect_ratio,
                        iconColor: const Color(0xFFE8590C),
                        title: l.viewportWidth,
                        value: l.viewportWidthValue(settings.viewportWidth),
                        onTap: () => _showViewportPicker(context, ref, settings),
                      ),
                      _SettingsRow(
                        icon: Icons.restore,
                        iconColor: const Color(0xFF17A34A),
                        title: l.sessionRestore,
                        subtitle: l.sessionRestoreSubtitle,
                        trailing: IosToggle(
                          value: settings.sessionRestore,
                          onChanged: (v) => ref
                              .read(settingsProvider.notifier)
                              .setSessionRestore(v),
                        ),
                      ),
                    ],
                  ),
                  SectionHeader(label: l.zoom, useAccentColor: true),
                  GroupedCard(
                    children: [
                      _SettingsRow(
                        icon: Icons.zoom_in,
                        iconColor: const Color(0xFF0969DA),
                        title: l.defaultZoom,
                        value: l.zoomPercent((settings.defaultZoom * 100).round()),
                      ),
                      _SettingsRow(
                        icon: Icons.height,
                        iconColor: const Color(0xFF0969DA),
                        title: l.showZoomBar,
                        subtitle: l.showZoomBarSubtitle,
                        trailing: IosToggle(
                          value: settings.showZoomBar,
                          onChanged: (v) => ref
                              .read(settingsProvider.notifier)
                              .setShowZoomBar(v),
                        ),
                      ),
                    ],
                  ),
                  SectionHeader(label: l.privacy, useAccentColor: true),
                  GroupedCard(
                    children: [
                      _SettingsRow(
                        icon: Icons.cookie_outlined,
                        iconColor: const Color(0xFFE8590C),
                        title: l.clearCookies,
                        onTap: () async {
                          await CookieManager.instance().deleteAllCookies();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l.cookiesCleared)),
                            );
                          }
                        },
                      ),
                      _SettingsRow(
                        icon: Icons.cached,
                        iconColor: const Color(0xFF17A34A),
                        title: l.clearCache,
                        onTap: () async {
                          await InAppWebViewController.clearAllCache();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l.cacheCleared)),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  SectionHeader(label: l.appearance, useAccentColor: true),
                  GroupedCard(
                    children: [
                      _SettingsRow(
                        icon: Icons.dark_mode,
                        iconColor: const Color(0xFF8250DF),
                        title: l.darkMode,
                        trailing: IosToggle(
                          value: settings.darkMode,
                          onChanged: (v) =>
                              ref.read(settingsProvider.notifier).setDarkMode(v),
                        ),
                      ),
                    ],
                  ),
                  SectionHeader(label: l.developer, useAccentColor: true),
                  GroupedCard(
                    children: [
                      _SettingsRow(
                        icon: Icons.bug_report_outlined,
                        iconColor: const Color(0xFFE8590C),
                        title: l.devLog,
                        trailing: IosToggle(
                          value: settings.devLogEnabled,
                          onChanged: (v) =>
                              ref.read(settingsProvider.notifier).setDevLogEnabled(v),
                        ),
                      ),
                      _SettingsRow(
                        icon: Icons.article_outlined,
                        iconColor: const Color(0xFF0969DA),
                        title: l.viewLogs,
                        onTap: () => Navigator.push(
                          context,
                          CupertinoPageRoute(builder: (_) => const DevLogScreen()),
                        ),
                      ),
                    ],
                  ),
                  SectionHeader(label: l.about, useAccentColor: true),
                  GroupedCard(
                    children: [
                      _SettingsRow(
                        icon: Icons.info_outline,
                        iconColor: colors.muted,
                        title: l.zoomViewBrowser,
                        value: l.version('1.0.0'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
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

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            ColoredIconBox.settings(color: iconColor, icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, color: colors.fg)),
                  if (subtitle != null)
                    Text(subtitle!, style: TextStyle(fontSize: 12, color: colors.muted)),
                ],
              ),
            ),
            ?trailing,
            if (value != null && trailing == null) ...[
              Text(value!, style: TextStyle(fontSize: 14, color: colors.muted)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 16, color: colors.border),
            ],
            if (onTap != null && value == null && trailing == null)
              Icon(Icons.chevron_right, size: 16, color: colors.border),
          ],
        ),
      ),
    );
  }
}
