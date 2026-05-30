import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_map_mobile/main.dart';

void main() {
  testWidgets('renders the Memory Map shell', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MemoryMapApp()));
    await tester.pumpAndSettle();

    expect(find.text('Memory Map'), findsOneWidget);
    expect(find.byIcon(Icons.add_location_alt_outlined), findsOneWidget);
  });
}
