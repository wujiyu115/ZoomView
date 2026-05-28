import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zoomview/app.dart';

void main() {
  testWidgets('ZoomViewApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ZoomViewApp()),
    );
    // App should render without crashing
    expect(find.byType(ZoomViewApp), findsOneWidget);
  });
}
