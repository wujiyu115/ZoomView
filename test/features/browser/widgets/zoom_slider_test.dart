import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoomview/features/browser/widgets/zoom_slider.dart';

void main() {
  testWidgets('displays current zoom percentage', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZoomSlider(
            zoomLevel: 1.5,
            minZoom: 1.0,
            maxZoom: 3.0,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('150%'), findsOneWidget);
  });

  testWidgets('zoom out button decreases value', (tester) async {
    double zoom = 1.5;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZoomSlider(
            zoomLevel: zoom,
            minZoom: 1.0,
            maxZoom: 3.0,
            onChanged: (v) => zoom = v,
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.zoom_out));
    expect(zoom, 1.4);
  });

  testWidgets('zoom in button increases value', (tester) async {
    double zoom = 1.5;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZoomSlider(
            zoomLevel: zoom,
            minZoom: 1.0,
            maxZoom: 3.0,
            onChanged: (v) => zoom = v,
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.zoom_in));
    expect(zoom, 1.6);
  });

  testWidgets('zoom out clamps at min', (tester) async {
    double zoom = 1.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZoomSlider(
            zoomLevel: zoom,
            minZoom: 1.0,
            maxZoom: 3.0,
            onChanged: (v) => zoom = v,
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.zoom_out));
    expect(zoom, 1.0);
  });
}
