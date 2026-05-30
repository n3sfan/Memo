import 'json.dart';
import 'pin_dto.dart';

class TimelinePageDto {
  const TimelinePageDto({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });

  factory TimelinePageDto.fromJson(Object? value) {
    final JsonMap json = asJsonMap(value, name: 'timeline page');

    return TimelinePageDto(
      items: asJsonMapList(json['items'], name: 'items')
          .map(PinDto.fromJson)
          .toList(growable: false),
      nextCursor: readOptionalString(json, 'nextCursor'),
      hasMore: readOptionalBool(json, 'hasMore') ?? false,
    );
  }

  final List<PinDto> items;
  final String? nextCursor;
  final bool hasMore;

  JsonMap toJson() {
    return <String, Object?>{
      'items': items.map((PinDto item) => item.toJson()).toList(),
      'nextCursor': nextCursor,
      'hasMore': hasMore,
    };
  }
}
