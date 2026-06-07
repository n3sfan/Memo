import 'package:flutter_test/flutter_test.dart';
import 'package:memory_map_mobile/data/mock/fake_share_repository.dart';
import 'package:memory_map_mobile/data/mock/mock_data.dart';
import 'package:memory_map_mobile/data/models/models.dart';

void main() {
  test('fake share repository creates, resolves and revokes one pin link',
      () async {
    final MockBackendState state = MockBackendState.seeded();
    final FakeShareRepository repository = FakeShareRepository(state);

    final ShareLinkDto link = await repository.createShareLink('pin_da_lat_1');
    expect(link.pinId, 'pin_da_lat_1');
    expect(link.url, contains('/p/${link.token}'));

    final PublicSharedPinDto shared =
        await repository.resolvePublicPin(link.token);
    expect(shared.shareLinkId, link.id);
    expect(shared.pin.id, 'pin_da_lat_1');
    expect(shared.pin.title, 'Da Lat morning');

    await repository.revokeShareLink(link.id);

    expect(
      () => repository.resolvePublicPin(link.token),
      throwsA(
        isA<ApiException>().having(
          (ApiException error) => error.apiError.error,
          'error',
          'link_revoked',
        ),
      ),
    );
  });

  test('fake share repository uses non predictable 12 character tokens',
      () async {
    final MockBackendState state = MockBackendState.seeded();
    final FakeShareRepository repository = FakeShareRepository(state);

    final ShareLinkDto first = await repository.createShareLink('pin_da_lat_1');
    final ShareLinkDto second =
        await repository.createShareLink('pin_da_lat_1');

    expect(first.token, isNot(startsWith('share_token_')));
    expect(second.token, isNot(startsWith('share_token_')));
    expect(first.token, isNot(second.token));
    expect(first.token, matches(RegExp(r'^[A-Za-z0-9_-]{12}$')));
    expect(second.token, matches(RegExp(r'^[A-Za-z0-9_-]{12}$')));
  });

  test('fake share repository retries token collisions', () async {
    final MockBackendState state = MockBackendState.seeded();
    state.shareLinks.add(
      MockShareLink(
        id: 'share-existing',
        pinId: 'pin_da_lat_1',
        token: 'aaaaaaaaaaaa',
        url: 'https://memo.app/p/aaaaaaaaaaaa',
        createdAt: DateTime.utc(2026),
        revoked: false,
      ),
    );
    final List<String> tokens = <String>['aaaaaaaaaaaa', 'bbbbbbbbbbbb'];
    var tokenIndex = 0;
    final FakeShareRepository repository = FakeShareRepository(
      state,
      tokenFactory: () => tokens[tokenIndex++],
    );

    final ShareLinkDto link = await repository.createShareLink('pin_da_lat_1');

    expect(link.token, 'bbbbbbbbbbbb');
    expect(
      state.shareLinks.where((MockShareLink link) {
        return link.token == 'aaaaaaaaaaaa';
      }),
      hasLength(1),
    );
  });
}
