import 'package:flutter_test/flutter_test.dart';
import 'package:memory_map_mobile/data/models/models.dart';

void main() {
  test('parses authenticated share link response', () {
    final ShareLinkDto link = ShareLinkDto.fromJson(<String, Object?>{
      'id': 'share_1',
      'pinId': 'pin_1',
      'token': 'share-token',
      'url': 'https://memo.app/p/share-token',
      'revoked': false,
      'createdAt': '2026-06-01T00:00:00.000Z',
      'expiresAt': null,
    });

    expect(link.id, 'share_1');
    expect(link.pinId, 'pin_1');
    expect(link.token, 'share-token');
    expect(link.url, 'https://memo.app/p/share-token');
    expect(link.revoked, isFalse);
    expect(link.createdAt, DateTime.utc(2026, 6, 1));
    expect(link.expiresAt, isNull);
  });

  test('parses public shared pin without requiring mapId or objectKey', () {
    final PublicSharedPinDto shared = PublicSharedPinDto.fromJson(
      <String, Object?>{
        'shareLinkId': 'share_1',
        'pin': <String, Object?>{
          'id': 'pin_1',
          'title': 'Da Lat morning',
          'note': 'Coffee near the lake.',
          'memoryDate': '2026-05-20T00:00:00.000Z',
          'lat': 11.9404,
          'lng': 108.4583,
          'media': <Object?>[
            <String, Object?>{
              'id': 'media_1',
              'pinId': 'pin_1',
              'mediaType': 'image',
              'mimeType': 'image/jpeg',
              'sizeBytes': 512,
              'createdAt': '2026-06-01T00:00:00.000Z',
              'url': 'https://r2.example/read/photo.jpg',
            },
          ],
          'createdAt': '2026-06-01T00:00:00.000Z',
          'updatedAt': '2026-06-01T00:05:00.000Z',
        },
      },
    );

    expect(shared.shareLinkId, 'share_1');
    expect(shared.pin.id, 'pin_1');
    expect(shared.pin.title, 'Da Lat morning');
    expect(shared.pin.media.single.url, 'https://r2.example/read/photo.jpg');
  });
}
