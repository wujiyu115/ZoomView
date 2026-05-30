import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoomview/core/extensions.dart';
import 'package:zoomview/core/widgets/colored_icon_box.dart';
import 'package:zoomview/core/widgets/search_bar_widget.dart';
import 'package:zoomview/core/widgets/section_header.dart';
import 'package:zoomview/features/history/providers/history_provider.dart';
import 'package:zoomview/l10n/app_localizations.dart';

class StartPage extends ConsumerStatefulWidget {
  final ValueChanged<String> onUrlSelected;

  const StartPage({super.key, required this.onUrlSelected});

  @override
  ConsumerState<StartPage> createState() => _StartPageState();
}

class _StartPageState extends ConsumerState<StartPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(historyProvider.notifier).load());
  }

  static const _quickAccess = [
    _QuickSite('G', 'Google', 'https://www.google.com', Color(0xFF4285F4)),
    _QuickSite('Y', 'YouTube', 'https://www.youtube.com', Color(0xFFFF0000)),
    _QuickSite('X', 'Twitter', 'https://x.com', Color(0xFF1DA1F2)),
    _QuickSite('GH', 'GitHub', 'https://github.com', Color(0xFF1B1F24)),
    _QuickSite('W', 'Wikipedia', 'https://www.wikipedia.org', Color(0xFF25D366)),
    _QuickSite('R', 'Reddit', 'https://www.reddit.com', Color(0xFFFF4500)),
    _QuickSite('L', 'LinkedIn', 'https://www.linkedin.com', Color(0xFF0A66C2)),
    _QuickSite('HN', 'HN', 'https://news.ycombinator.com', Color(0xFFFF6600)),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l = AppLocalizations.of(context)!;
    final history = ref.watch(historyProvider);
    final recentItems = history.take(5).toList();

    return Container(
      color: colors.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Center(
              child: Text(
                'ZoomView',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: colors.fg,
                  letterSpacing: -0.01 * 22,
                ),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _showSearchDialog(context),
              child: SearchBarWidget(
                hint: l.searchOrEnterUrl,
                pill: true,
              ),
            ),
            const SizedBox(height: 32),
            SectionHeader(label: l.quickAccess),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: _quickAccess.map((site) {
                return GestureDetector(
                  onTap: () => widget.onUrlSelected(site.url),
                  child: Column(
                    children: [
                      ColoredIconBox(
                        color: site.color,
                        letter: site.letter,
                        size: 56,
                        borderRadius: 14,
                        iconSize: 22,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        site.name,
                        style: TextStyle(fontSize: 12, color: colors.fg2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            if (recentItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              SectionHeader(label: l.recentVisits),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.06,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (int i = 0; i < recentItems.length; i++) ...[
                      _RecentItem(
                        entry: recentItems[i],
                        onTap: () => widget.onUrlSelected(recentItems[i].url),
                      ),
                      if (i < recentItems.length - 1)
                        Divider(height: 0.5, thickness: 0.5, color: colors.border, indent: 16),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.searchOrEnterUrl),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.go,
          onSubmitted: (value) {
            Navigator.pop(ctx);
            _handleSearch(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleSearch(controller.text);
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  void _handleSearch(String value) {
    var url = value.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.contains('.') && !url.contains(' ')) {
        url = 'https://$url';
      } else {
        url = 'https://www.google.com/search?q=${Uri.encodeComponent(url)}';
      }
    }
    widget.onUrlSelected(url);
  }
}

class _RecentItem extends StatelessWidget {
  final dynamic entry;
  final VoidCallback onTap;

  const _RecentItem({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final title = entry.title as String;
    final url = entry.url as String;
    final domain = Uri.tryParse(url)?.host ?? url;
    final letter = title.isNotEmpty ? title[0].toUpperCase() : domain.isNotEmpty ? domain[0].toUpperCase() : '?';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            ColoredIconBox(
              color: colors.urlBg,
              letter: letter,
              size: 36,
              borderRadius: 10,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isNotEmpty ? title : domain,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.fg),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    domain,
                    style: TextStyle(fontSize: 12, color: colors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickSite {
  final String letter;
  final String name;
  final String url;
  final Color color;

  const _QuickSite(this.letter, this.name, this.url, this.color);
}
