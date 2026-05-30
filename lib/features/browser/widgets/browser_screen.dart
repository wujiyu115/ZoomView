import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zoomview/core/extensions.dart';
import 'package:zoomview/core/widgets/colored_icon_box.dart';
import 'package:zoomview/features/browser/providers/browser_provider.dart';
import 'package:zoomview/features/settings/models/settings_model.dart';
import 'package:zoomview/features/settings/providers/settings_provider.dart';
import 'package:zoomview/features/bookmarks/providers/bookmark_provider.dart';
import 'package:zoomview/features/bookmarks/widgets/bookmark_screen.dart';
import 'package:zoomview/features/history/providers/history_provider.dart';
import 'package:zoomview/features/history/widgets/history_screen.dart';
import 'package:zoomview/features/settings/widgets/settings_screen.dart';
import 'package:zoomview/features/downloads/widgets/download_screen.dart';
import 'package:zoomview/features/downloads/providers/download_provider.dart';
import 'package:zoomview/l10n/app_localizations.dart';
import 'toolbar.dart';
import 'url_bar.dart';
import 'zoom_slider.dart';
import 'tab_manager.dart';
import 'webview_container.dart';
import 'start_page.dart';

class BrowserScreen extends ConsumerStatefulWidget {
  const BrowserScreen({super.key});

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  final Map<String, InAppWebViewController> _controllers = {};
  bool _isFullscreen = false;
  Offset? _fabOffset;

  InAppWebViewController? get _activeController {
    final state = ref.read(browserProvider);
    return _controllers[state.activeTab.id];
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(settingsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final browserState = ref.watch(browserProvider);
    final settings = ref.watch(settingsProvider);

    final webViewStack = IndexedStack(
      index: browserState.activeTabIndex,
      children: List.generate(browserState.tabs.length, (i) {
        final tab = browserState.tabs[i];
        return WebViewContainer(
          key: ValueKey(tab.id),
          tabIndex: i,
          initialUrl: tab.url,
          onControllerCreated: (controller) {
            _controllers[tab.id] = controller;
          },
          onPageLoaded: (title, url) {
            ref.read(historyProvider.notifier).addEntry(title, url);
          },
          onDownloadRequested: (request) {
            final fileName = request.suggestedFilename ??
                request.url.toString().split('/').last.split('?').first;
            _showDownloadConfirmDialog(
              request.url.toString(),
              fileName.isEmpty ? 'download' : fileName,
            );
          },
          onDownloadUrlDetected: (url, fileName) {
            _showDownloadConfirmDialog(url, fileName);
          },
        );
      }),
    );

    return Scaffold(
      body: Column(
        children: [
          if (!_isFullscreen) ...[
            BrowserToolbar(
              isDownloading: ref.watch(isDownloadingProvider),
              onHome: () {
                final state = ref.read(browserProvider);
                ref.read(browserProvider.notifier).showStartPageAt(state.activeTabIndex);
              },
              onBookmarks: () async {
                final url = await Navigator.push<String>(
                  context,
                  CupertinoPageRoute(builder: (_) => const BookmarkScreen()),
                );
                if (url != null) {
                  _activeController?.loadUrl(
                      urlRequest: URLRequest(url: WebUri(url)));
                }
              },
              onRefresh: () => _activeController?.reload(),
              onBack: () => _activeController?.goBack(),
              onForward: () => _activeController?.goForward(),
              onMore: () => _showMoreMenu(context),
              onSettings: () => Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const SettingsScreen()),
              ),
              onTabs: () => Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const TabManager()),
              ),
              onDownloads: () => Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const DownloadScreen()),
              ),
            ),
            UrlBar(
              url: browserState.activeTab.url,
              progress: browserState.progress,
              isLoading: browserState.isLoading,
              onSubmitted: (url) {
                _activeController?.loadUrl(
                  urlRequest: URLRequest(url: WebUri(url)),
                );
              },
            ),
          ],
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _fabOffset ??= Offset(20, constraints.maxHeight - 60);
                final showStart = browserState.activeTab.showStartPage;
                return Stack(
                  children: [
                    webViewStack,
                    if (showStart)
                      Positioned.fill(
                        child: StartPage(
                          onUrlSelected: (url) {
                            ref.read(browserProvider.notifier).hideStartPage(browserState.activeTabIndex);
                            _activeController?.loadUrl(
                              urlRequest: URLRequest(url: WebUri(url)),
                            );
                          },
                        ),
                      ),
                    Positioned(
                      left: _fabOffset!.dx,
                      top: _fabOffset!.dy,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _fabOffset = Offset(
                              (_fabOffset!.dx + details.delta.dx).clamp(0, constraints.maxWidth - 40),
                              (_fabOffset!.dy + details.delta.dy).clamp(0, constraints.maxHeight - 40),
                            );
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: context.appColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: context.appColors.border, width: 0.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => setState(() => _isFullscreen = !_isFullscreen),
                            icon: Icon(
                              _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                              size: 18,
                              color: context.appColors.fg2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (!_isFullscreen)
            ZoomSlider(
              zoomLevel: browserState.activeTab.zoomLevel,
              minZoom: settings.minZoom,
              maxZoom: settings.maxZoom,
              onChanged: (zoom) {
                final oldZoom = browserState.activeTab.zoomLevel;
                ref.read(browserProvider.notifier).updateZoom(
                      browserState.activeTabIndex, zoom);
                if (oldZoom > 0) {
                  _activeController?.zoomBy(
                    zoomFactor: zoom / oldZoom,
                    animated: false,
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  void _showDownloadConfirmDialog(String url, String fileName) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.downloadConfirmTitle),
        content: Text(fileName),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(downloadProvider.notifier).startDownload(url, fileName);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.downloading)),
              );
            },
            child: Text(l.download),
          ),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),
              _SheetItem(
                icon: Icons.share,
                iconColor: const Color(0xFF0969DA),
                label: l.share,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  final url = ref.read(browserProvider).activeTab.url;
                  SharePlus.instance.share(ShareParams(uri: Uri.parse(url)));
                },
              ),
              _SheetItem(
                icon: Icons.search,
                iconColor: const Color(0xFF8250DF),
                label: l.findInPage,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  _showFindInPage();
                },
              ),
              _SheetItem(
                icon: Icons.desktop_mac,
                iconColor: const Color(0xFF17A34A),
                label: ref.read(settingsProvider).uaMode == UaMode.desktop
                    ? l.switchToMobileMode
                    : l.switchToDesktopMode,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  final current = ref.read(settingsProvider).uaMode;
                  ref.read(settingsProvider.notifier).setUaMode(
                        current == UaMode.desktop
                            ? UaMode.mobile
                            : UaMode.desktop,
                      );
                  _activeController?.reload();
                },
              ),
              _SheetItem(
                icon: Icons.bookmark_add,
                iconColor: const Color(0xFFE8590C),
                label: l.addBookmark,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  final tab = ref.read(browserProvider).activeTab;
                  ref.read(bookmarkProvider.notifier).addBookmark(
                        tab.title.isEmpty ? tab.url : tab.title,
                        tab.url,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.bookmarkAdded)),
                  );
                },
              ),
              _SheetItem(
                icon: Icons.history,
                iconColor: colors.muted,
                label: l.history,
                isDark: isDark,
                onTap: () async {
                  Navigator.pop(ctx);
                  final url = await Navigator.push<String>(
                    context,
                    CupertinoPageRoute(builder: (_) => const HistoryScreen()),
                  );
                  if (url != null) {
                    _activeController?.loadUrl(
                        urlRequest: URLRequest(url: WebUri(url)));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFindInPage() {
    final l = AppLocalizations.of(context)!;
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final controller = TextEditingController();
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: l.findInPageHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  autofocus: true,
                  onSubmitted: (query) {
                    _activeController?.findAllAsync(find: query);
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.arrow_upward, color: colors.fg2),
                onPressed: () =>
                    _activeController?.findNext(forward: false),
              ),
              IconButton(
                icon: Icon(Icons.arrow_downward, color: colors.fg2),
                onPressed: () =>
                    _activeController?.findNext(forward: true),
              ),
              IconButton(
                icon: Icon(Icons.close, color: colors.fg2),
                onPressed: () {
                  _activeController?.clearMatches();
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SheetItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _SheetItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            ColoredIconBox.settings(
              color: isDark ? const Color(0xFF2D333B) : iconColor,
              icon: icon,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(fontSize: 16, color: colors.fg),
            ),
          ],
        ),
      ),
    );
  }
}
