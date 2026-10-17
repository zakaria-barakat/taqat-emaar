import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taqat_emaar/main.dart';

void main() {
  testWidgets('TaqatEmaarApp smoke test displays app title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: TaqatEmaarApp(),
      ),
    );

    // Verify that our app displays the title 'Taqat Emaar'.
    expect(find.text('Taqat Emaar'), findsOneWidget);
  });
}