import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoomview/features/browser/providers/browser_provider.dart';
import 'package:zoomview/features/browser/models/tab_model.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  test('initial state has one tab', () {
    final state = container.read(browserProvider);
    expect(state.tabs.length, 1);
    expect(state.activeTabIndex, 0);
  });

  test('addTab creates new tab and switches to it', () {
    container.read(browserProvider.notifier).addTab('https://example.com');
    final state = container.read(browserProvider);
    expect(state.tabs.length, 2);
    expect(state.activeTabIndex, 1);
    expect(state.tabs[1].url, 'https://example.com');
  });

  test('closeTab removes tab and adjusts index', () {
    container.read(browserProvider.notifier).addTab('https://example.com');
    container.read(browserProvider.notifier).closeTab(0);
    final state = container.read(browserProvider);
    expect(state.tabs.length, 1);
    expect(state.activeTabIndex, 0);
    expect(state.tabs[0].url, 'https://example.com');
  });

  test('closeTab on last tab creates new empty tab', () {
    container.read(browserProvider.notifier).closeTab(0);
    final state = container.read(browserProvider);
    expect(state.tabs.length, 1);
  });

  test('switchTab updates activeTabIndex', () {
    container.read(browserProvider.notifier).addTab('https://example.com');
    container.read(browserProvider.notifier).switchTab(0);
    expect(container.read(browserProvider).activeTabIndex, 0);
  });

  test('updateZoom clamps to range', () {
    container.read(browserProvider.notifier).updateZoom(0, 5.0);
    expect(container.read(browserProvider).tabs[0].zoomLevel, 3.0);
    container.read(browserProvider.notifier).updateZoom(0, 0.1);
    expect(container.read(browserProvider).tabs[0].zoomLevel, 1.0);
  });

  test('updateUrl changes tab URL', () {
    container.read(browserProvider.notifier).updateUrl(0, 'https://changed.com');
    expect(container.read(browserProvider).tabs[0].url, 'https://changed.com');
  });

  test('updateTitle changes tab title', () {
    container.read(browserProvider.notifier).updateTitle(0, 'New Title');
    expect(container.read(browserProvider).tabs[0].title, 'New Title');
  });

  test('restoreTabs replaces state with given tabs and index', () {
    container.read(browserProvider.notifier).restoreTabs([
      TabModel(url: 'https://a.com'),
      TabModel(url: 'https://b.com'),
    ], 1);
    final state = container.read(browserProvider);
    expect(state.tabs.length, 2);
    expect(state.activeTabIndex, 1);
    expect(state.tabs[1].url, 'https://b.com');
  });

  test('restoreTabs clamps out-of-range activeIndex', () {
    container.read(browserProvider.notifier)
        .restoreTabs([TabModel(url: 'https://a.com')], 5);
    expect(container.read(browserProvider).activeTabIndex, 0);
  });

  test('restoreTabs ignores empty list', () {
    container.read(browserProvider.notifier).restoreTabs([], 0);
    expect(container.read(browserProvider).tabs.length, 1);
  });
}
