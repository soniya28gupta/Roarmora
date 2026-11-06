import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamora_flutter/main.dart';

void main() {
  testWidgets('RoamoraApp pumps with ProviderScope and routes to /login when unauthenticated', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RoamoraApp(),
      ),
    );
    expect(find.text('Pookie Match'), findsOneWidget);

    // Advance past splash animation & session check
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 500));

    // Welcome Back is rendered on the screen
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
