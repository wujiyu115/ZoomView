import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoomview/features/browser/providers/browser_provider.dart';
import 'package:zoomview/features/settings/models/settings_model.dart';
import 'package:zoomview/features/settings/providers/settings_provider.dart';
import 'package:zoomview/features/bookmarks/providers/bookmark_provider.dart';
import 'package:zoomview/features/bookmarks/widgets/bookmark_screen.dart';
import 'package:zoomview/features/settings/widgets/settings_screen.dart';
import 'toolbar.dart';
import 'url_bar.dart';
import 'zoom_slider.dart';
import 'tab_manager.dart';
import 'webview_container.dart';

class BrowserScreen extends ConsumerStatefulWidget {
  const BrowserScreen({super.key});

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  final Map<String, InAppWebViewController> _controllers = {};

  InAppWebViewController? get _activeController {
    final state = ref.read(browserProvider);
    return _controllers[state.activeTab.id];
  }

  @override
  void initState() {
    super.initState();
    // Load persisted settings on first launch
    Future.microtask(() => ref.read(settingsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final browserState = ref.watch(browserProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: Column(
        children: [
          BrowserToolbar(
            onHome: () => _activeController?.loadUrl(
              urlRequest: URLRequest(url: WebUri(settings.homeUrl)),
            ),
            onBookmarks: () async {
              final url = await Navigator.push<String>(
                context,
                MaterialPageRoute(builder: (_) => const BookmarkScreen()),
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
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            onTabs: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TabManager()),
            ),
            onDownloads: () => _pushPlaceholder(context, 'Downloads'),
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
          Expanded(
            child: IndexedStack(
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
                    // History recording — will be wired in Task 14
                  },
                  onDownloadRequested: (request) {
                    // Download handling — will be wired in Task 14
                  },
                );
              }),
            ),
          ),
          ZoomSlider(
            zoomLevel: browserState.activeTab.zoomLevel,
            minZoom: settings.minZoom,
            maxZoom: settings.maxZoom,
            onChanged: (zoom) {
              ref.read(browserProvider.notifier).updateZoom(
                    browserState.activeTabIndex, zoom);
              _activeController?.zoomBy(
                zoomFactor: zoom,
                animated: false,
              );
            },
          ),
        ],
      ),
    );
  }

  void _pushPlaceholder(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: const Center(child: Text('Coming soon')),
        ),
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Find in Page'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.desktop_mac),
              title: Text(
                ref.read(settingsProvider).uaMode == UaMode.desktop
                    ? 'Switch to Mobile Mode'
                    : 'Switch to Desktop Mode',
              ),
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
            ListTile(
              leading: const Icon(Icons.bookmark_add),
              title: const Text('Add Bookmark'),
              onTap: () {
                Navigator.pop(ctx);
                final tab = ref.read(browserProvider).activeTab;
                ref.read(bookmarkProvider.notifier).addBookmark(
                      tab.title.isEmpty ? tab.url : tab.title,
                      tab.url,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bookmark added')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History'),
              onTap: () {
                Navigator.pop(ctx);
                _pushPlaceholder(context, 'History');
              },
            ),
          ],
        ),
      ),
    );
  }
}
