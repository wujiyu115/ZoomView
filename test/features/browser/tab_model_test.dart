import 'package:flutter_test/flutter_test.dart';
import 'package:zoomview/features/browser/models/tab_model.dart';

void main() {
  test('toJson serializes persisted fields', () {
    final tab = TabModel(
      url: 'https://example.com',
      title: 'Example',
      zoomLevel: 1.5,
      scrollPosition: 240,
    );
    expect(tab.toJson(), {
      'url': 'https://example.com',
      'title': 'Example',
      'zoomLevel': 1.5,
      'scrollPosition': 240.0,
    });
  });

  test('fromJson restores persisted fields', () {
    final tab = TabModel.fromJson({
      'url': 'https://example.com',
      'title': 'Example',
      'zoomLevel': 1.5,
      'scrollPosition': 240,
    });
    expect(tab.url, 'https://example.com');
    expect(tab.title, 'Example');
    expect(tab.zoomLevel, 1.5);
    expect(tab.scrollPosition, 240.0);
    expect(tab.showStartPage, false);
  });

  test('fromJson with empty url derives showStartPage true', () {
    final tab = TabModel.fromJson({'url': ''});
    expect(tab.showStartPage, true);
    expect(tab.zoomLevel, 1.0);
    expect(tab.scrollPosition, 0.0);
  });

  test('round-trip preserves values', () {
    final original = TabModel(
        url: 'https://a.com', title: 'A', zoomLevel: 2.0, scrollPosition: 10);
    final restored = TabModel.fromJson(original.toJson());
    expect(restored.url, original.url);
    expect(restored.title, original.title);
    expect(restored.zoomLevel, original.zoomLevel);
    expect(restored.scrollPosition, original.scrollPosition);
  });
}
