import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoomview/core/database/database_helper.dart';
import 'package:zoomview/core/logger/app_logger.dart';
import '../models/settings_model.dart';
import '../repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(DatabaseHelper.instance);
});

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsModel>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<SettingsModel> {
  @override
  SettingsModel build() {
    return const SettingsModel();
  }

  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  Future<void> load() async {
    state = await _repo.loadAll();
    AppLogger.instance.enabled = state.devLogEnabled;
  }

  Future<void> setUaMode(UaMode mode) async {
    await _repo.set('ua_mode', mode == UaMode.mobile ? 'mobile' : 'desktop');
    state = state.copyWith(uaMode: mode);
  }

  Future<void> setSearchEngine(String engine) async {
    await _repo.set('search_engine', engine);
    state = state.copyWith(searchEngine: engine);
  }

  Future<void> setHomeUrl(String url) async {
    await _repo.set('home_url', url);
    state = state.copyWith(homeUrl: url);
  }

  Future<void> setViewportWidth(int width) async {
    await _repo.set('viewport_width', width.toString());
    state = state.copyWith(viewportWidth: width);
  }

  Future<void> setDefaultZoom(double zoom) async {
    await _repo.set('default_zoom', zoom.toString());
    state = state.copyWith(defaultZoom: zoom);
  }

  Future<void> setMinZoom(double zoom) async {
    await _repo.set('min_zoom', zoom.toString());
    state = state.copyWith(minZoom: zoom);
  }

  Future<void> setMaxZoom(double zoom) async {
    await _repo.set('max_zoom', zoom.toString());
    state = state.copyWith(maxZoom: zoom);
  }

  Future<void> setDarkMode(bool enabled) async {
    await _repo.set('dark_mode', enabled.toString());
    state = state.copyWith(darkMode: enabled);
  }

  Future<void> setDevLogEnabled(bool enabled) async {
    await _repo.set('dev_log_enabled', enabled.toString());
    AppLogger.instance.enabled = enabled;
    state = state.copyWith(devLogEnabled: enabled);
  }

  Future<void> setSessionRestore(bool enabled) async {
    await _repo.set('session_restore', enabled.toString());
    state = state.copyWith(sessionRestore: enabled);
  }

  Future<void> setShowZoomBar(bool enabled) async {
    await _repo.set('show_zoom_bar', enabled.toString());
    state = state.copyWith(showZoomBar: enabled);
  }
}
