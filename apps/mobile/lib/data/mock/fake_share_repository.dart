import 'dart:convert';
import 'dart:math';

import '../models/models.dart';
import '../repositories/share_repository.dart';
import 'mock_data.dart';

typedef ShareTokenFactory = String Function();

class FakeShareRepository implements ShareRepository {
  FakeShareRepository(
    this.state, {
    ShareTokenFactory? tokenFactory,
  }) : _tokenFactory = tokenFactory ?? _createRandomToken;

  static final Random _secureRandom = Random.secure();
  static const int _tokenBytes = 9;
  static const int _tokenLength = 12;
  static const int _maxTokenAttempts = 10;

  final MockBackendState state;
  final ShareTokenFactory _tokenFactory;

  @override
  Future<ShareLinkDto> createShareLink(String pinId) async {
    state.pins.firstWhere((PinDto pin) => pin.id == pinId);
    final DateTime now = DateTime.now().toUtc();
    final String token = _createUniqueToken();
    final MockShareLink link = MockShareLink(
      id: state.nextId('share'),
      pinId: pinId,
      token: token,
      url: 'https://memo.app/p/$token',
      createdAt: now,
      revoked: false,
    );
    state.shareLinks.add(link);

    return _toShareLinkDto(link);
  }

  String _createUniqueToken() {
    for (var attempt = 0; attempt < _maxTokenAttempts; attempt += 1) {
      final String token = _tokenFactory();
      final bool exists = state.shareLinks.any(
        (MockShareLink link) => link.token == token,
      );

      if (!exists) {
        return token;
      }
    }

    throw const ApiException(
      apiError: ApiError(
        error: 'conflict',
        message: 'Could not create a unique share link token.',
        details: <String, Object?>{},
        requestId: '',
      ),
      statusCode: 409,
    );
  }

  static String _createRandomToken() {
    final List<int> bytes = List<int>.generate(
      _tokenBytes,
      (_) => _secureRandom.nextInt(256),
      growable: false,
    );

    return base64UrlEncode(bytes).replaceAll('=', '').substring(
          0,
          _tokenLength,
        );
  }

  @override
  Future<PublicSharedPinDto> resolvePublicPin(String token) async {
    final MockShareLink link = state.shareLinks.firstWhere(
      (MockShareLink item) => item.token == token,
      orElse: () => throw const ApiException(
        apiError: ApiError(
          error: 'not_found',
          message: 'Share link not found.',
          details: <String, Object?>{},
          requestId: '',
        ),
        statusCode: 404,
      ),
    );

    if (link.revoked) {
      throw const ApiException(
        apiError: ApiError(
          error: 'link_revoked',
          message: 'Share link has been revoked.',
          details: <String, Object?>{},
          requestId: '',
        ),
        statusCode: 410,
      );
    }

    final PinDto pin =
        state.pins.firstWhere((PinDto item) => item.id == link.pinId);

    return PublicSharedPinDto(
      shareLinkId: link.id,
      pin: _toPublicPinDto(pin),
    );
  }

  @override
  Future<void> revokeShareLink(String shareLinkId) async {
    final int index = state.shareLinks.indexWhere(
      (MockShareLink item) => item.id == shareLinkId,
    );
    if (index < 0) {
      throw const ApiException(
        apiError: ApiError(
          error: 'not_found',
          message: 'Share link not found.',
          details: <String, Object?>{},
          requestId: '',
        ),
        statusCode: 404,
      );
    }

    state.shareLinks[index] = state.shareLinks[index].copyWith(revoked: true);
  }

  ShareLinkDto _toShareLinkDto(MockShareLink link) {
    return ShareLinkDto(
      id: link.id,
      pinId: link.pinId,
      token: link.token,
      url: link.url,
      revoked: link.revoked,
      createdAt: link.createdAt,
      expiresAt: null,
    );
  }

  PublicPinDto _toPublicPinDto(PinDto pin) {
    return PublicPinDto(
      id: pin.id,
      title: pin.title,
      note: pin.note,
      memoryDate: pin.memoryDate,
      lat: pin.lat,
      lng: pin.lng,
      media: pin.media
          .map(
            (PinMediaDto media) => PublicPinMediaDto(
              id: media.id,
              pinId: media.pinId,
              mediaType: media.mediaType,
              mimeType: media.mimeType,
              sizeBytes: media.sizeBytes,
              createdAt: media.createdAt,
              url: media.url ?? 'mock://media/${media.id}',
            ),
          )
          .toList(growable: false),
      createdAt: pin.createdAt,
      updatedAt: pin.updatedAt,
    );
  }
}
