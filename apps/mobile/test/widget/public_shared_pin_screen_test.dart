import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_map_mobile/app/public_shared_pin_screen.dart';
import 'package:memory_map_mobile/data/mock/fake_share_repository.dart';
import 'package:memory_map_mobile/data/mock/mock_data.dart';
import 'package:memory_map_mobile/data/models/models.dart';
import 'package:memory_map_mobile/data/repository_providers.dart';

void main() {
  testWidgets('renders a valid public shared pin', (tester) async {
    final MockBackendState state = MockBackendState.seeded();
    final FakeShareRepository repository = FakeShareRepository(state);
    final ShareLinkDto link =
        await repository.createShareLink('pin_da_lat_1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shareRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: PublicSharedPinScreen(token: link.token),
        ),
      ),
    );

    expect(find.byKey(const Key('public_share_loading')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Da Lat morning'), findsOneWidget);
    expect(find.text('Coffee near the lake.'), findsOneWidget);
    expect(find.textContaining('11.9404'), findsOneWidget);
  });

  testWidgets('renders revoked public link state', (tester) async {
    final MockBackendState state = MockBackendState.seeded();
    final FakeShareRepository repository = FakeShareRepository(state);
    final ShareLinkDto link =
        await repository.createShareLink('pin_da_lat_1');
    await repository.revokeShareLink(link.id);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shareRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: PublicSharedPinScreen(token: link.token),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Liên kết đã thu hồi'), findsOneWidget);
  });
}
