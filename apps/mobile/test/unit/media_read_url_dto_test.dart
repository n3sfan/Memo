import 'package:flutter_test/flutter_test.dart';
import 'package:memory_map_mobile/data/mock/fake_media_repository.dart';
import 'package:memory_map_mobile/data/mock/mock_data.dart';
import 'package:memory_map_mobile/data/models/models.dart';

void main() {
  group('MediaReadUrlDto.fromJson', () {
    test('parses url and expiresAt from a JSON map', () {
      final MediaReadUrlDto dto = MediaReadUrlDto.fromJson(<String, Object?>{
        'url': 'https://storage.memo.local/read/media_42',
        'expiresAt': '2026-05-30T10:15:00.000Z',
      });

      expect(dto.url, 'https://storage.memo.local/read/media_42');
      expect(dto.expiresAt, DateTime.utc(2026, 5, 30, 10, 15));
    });

    test('round-trips through toJson/fromJson', () {
      final MediaReadUrlDto dto = MediaReadUrlDto(
        url: 'https://storage.memo.local/read/media_7',
        expiresAt: DateTime.utc(2026, 6, 1, 12),
      );

      final MediaReadUrlDto parsed = MediaReadUrlDto.fromJson(dto.toJson());

      expect(parsed.url, dto.url);
      expect(parsed.expiresAt, dto.expiresAt);
    });
  });

  group('FakeMediaRepository.createReadUrl', () {
    test('returns a loadable image URL for seeded image media', () async {
      final FakeMediaRepository repository =
          FakeMediaRepository(MockBackendState.seeded());

      final MediaReadUrlDto result =
          await repository.createReadUrl('media_da_lat_photo');

      expect(result.url, contains('https://picsum.photos/seed/'));
      expect(result.url, contains('media_da_lat_photo'));
    });

    test('returns a loadable audio URL for seeded audio media', () async {
      final FakeMediaRepository repository =
          FakeMediaRepository(MockBackendState.seeded());

      final MediaReadUrlDto result =
          await repository.createReadUrl('media_da_lat_audio');

      expect(result.url, startsWith('https://www.soundhelix.com/'));
    });

    test('returns an expiry in the future', () async {
      final FakeMediaRepository repository =
          FakeMediaRepository(MockBackendState.seeded());
      final DateTime before = DateTime.now().toUtc();

      final MediaReadUrlDto result =
          await repository.createReadUrl('media_da_lat_photo');

      expect(result.expiresAt.isAfter(before), isTrue);
    });
  });
}
