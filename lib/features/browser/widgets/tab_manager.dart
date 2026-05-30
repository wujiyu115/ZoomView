import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoomview/core/extensions.dart';
import 'package:zoomview/core/widgets/ios_nav_header.dart';
import 'package:zoomview/features/browser/providers/browser_provider.dart';
import 'package:zoomview/l10n/app_localizations.dart';

class TabManager extends ConsumerWidget {
  const TabManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browserState = ref.watch(browserProvider);
    final colors = context.appColors;
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            IosNavHeader(
              title: l.tabsCount(browserState.tabs.length),
              showBack: false,
              largeTitle: true,
              trailing: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  l.done,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.accent,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${browserState.tabs.length} ${browserState.tabs.length == 1 ? 'tab' : 'tabs'}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.muted),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.72,
                ),
                itemCount: browserState.tabs.length,
                itemBuilder: (context, index) {
                  final tab = browserState.tabs[index];
                  final isActive = index == browserState.activeTabIndex;
                  final domain = Uri.tryParse(tab.url)?.host ?? tab.url;

                  return GestureDetector(
                    onTap: () {
                      ref.read(browserProvider.notifier).switchTab(index);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isActive ? colors.accent : Colors.transparent,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AspectRatio(
                                aspectRatio: 4 / 3,
                                child: Container(
                                  color: colors.urlBg,
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.language, size: 28, color: colors.muted),
                                      const SizedBox(height: 4),
                                      Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 12),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: colors.surface.withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          domain,
                                          style: TextStyle(fontSize: 10, color: colors.muted),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tab.title.isEmpty ? l.newTab : tab.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: colors.fg,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      domain,
                                      style: TextStyle(fontSize: 11, color: colors.muted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () => ref.read(browserProvider.notifier).closeTab(index),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.35),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    ref.read(browserProvider.notifier).addTab(
                      '',
                      showStartPage: true,
                    );
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, size: 20),
                      const SizedBox(width: 8),
                      Text(l.newTab, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
