import 'package:flutter_test/flutter_test.dart';
import 'package:zoomview/core/constants.dart';

void main() {
  test('desktop UA contains Windows and Chrome', () {
    expect(AppConstants.desktopUserAgent, contains('Windows NT'));
    expect(AppConstants.desktopUserAgent, contains('Chrome'));
  });

  test('zoom range is valid', () {
    expect(AppConstants.minZoom, lessThan(AppConstants.maxZoom));
    expect(AppConstants.defaultZoom, greaterThanOrEqualTo(AppConstants.minZoom));
    expect(AppConstants.defaultZoom, lessThanOrEqualTo(AppConstants.maxZoom));
  });

  test('default viewport width is 1920', () {
    expect(AppConstants.defaultViewportWidth, 1920);
  });

  test('search engine URLs contain query placeholder', () {
    for (final entry in AppConstants.searchEngines.entries) {
      expect(entry.value, contains('%s'), reason: '${entry.key} missing %s');
    }
  });
}
