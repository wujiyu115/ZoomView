import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoomview/core/constants.dart';
import '../models/tab_model.dart';

class BrowserState {
  final List<TabModel> tabs;
  final int activeTabIndex;
  final bool isLoading;
  final double progress;

  const BrowserState({
    required this.tabs,
    this.activeTabIndex = 0,
    this.isLoading = false,
    this.progress = 0,
  });

  TabModel get activeTab => tabs[activeTabIndex];

  BrowserState copyWith({
    List<TabModel>? tabs,
    int? activeTabIndex,
    bool? isLoading,
    double? progress,
  }) {
    return BrowserState(
      tabs: tabs ?? this.tabs,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
    );
  }
}

final browserProvider =
    NotifierProvider<BrowserNotifier, BrowserState>(BrowserNotifier.new);

class BrowserNotifier extends Notifier<BrowserState> {
  @override
  BrowserState build() {
    return BrowserState(
      tabs: [TabModel(url: '', showStartPage: true)],
    );
  }

  void addTab(String url, {bool showStartPage = false}) {
    final newTab = TabModel(url: url, showStartPage: showStartPage);
    final newTabs = [...state.tabs, newTab];
    state = state.copyWith(tabs: newTabs, activeTabIndex: newTabs.length - 1);
  }

  void showStartPageAt(int index) {
    final newTabs = [...state.tabs];
    newTabs[index] = newTabs[index].copyWith(showStartPage: true);
    state = state.copyWith(tabs: newTabs);
  }

  void hideStartPage(int index) {
    final newTabs = [...state.tabs];
    newTabs[index] = newTabs[index].copyWith(showStartPage: false);
    state = state.copyWith(tabs: newTabs);
  }

  void closeTab(int index) {
    if (state.tabs.length <= 1) {
      state = BrowserState(tabs: [TabModel(url: '', showStartPage: true)]);
      return;
    }
    final newTabs = [...state.tabs]..removeAt(index);
    var newIndex = state.activeTabIndex;
    if (index <= newIndex) {
      newIndex = (newIndex - 1).clamp(0, newTabs.length - 1);
    }
    state = state.copyWith(tabs: newTabs, activeTabIndex: newIndex);
  }

  void switchTab(int index) {
    if (index >= 0 && index < state.tabs.length) {
      state = state.copyWith(activeTabIndex: index);
    }
  }

  void updateZoom(int index, double zoom) {
    final clamped = zoom.clamp(AppConstants.minZoom, AppConstants.maxZoom);
    final newTabs = [...state.tabs];
    newTabs[index] = newTabs[index].copyWith(zoomLevel: clamped);
    state = state.copyWith(tabs: newTabs);
  }

  void updateUrl(int index, String url) {
    final newTabs = [...state.tabs];
    newTabs[index] = newTabs[index].copyWith(url: url);
    state = state.copyWith(tabs: newTabs);
  }

  void updateTitle(int index, String title) {
    final newTabs = [...state.tabs];
    newTabs[index] = newTabs[index].copyWith(title: title);
    state = state.copyWith(tabs: newTabs);
  }

  void updateFavicon(int index, dynamic favicon) {
    final newTabs = [...state.tabs];
    newTabs[index] = newTabs[index].copyWith(favicon: favicon);
    state = state.copyWith(tabs: newTabs);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setProgress(double progress) {
    state = state.copyWith(progress: progress);
  }
}
