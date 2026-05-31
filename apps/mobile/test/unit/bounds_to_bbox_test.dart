import 'package:flutter_test/flutter_test.dart';
import 'package:memory_map_mobile/map/map.dart';

void main() {
  test('serializes viewport edges as minLng,minLat,maxLng,maxLat', () {
    final bbox = bboxFromEdges(
      west: 106.1,
      south: 10.2,
      east: 108.3,
      north: 12.4,
    );

    expect(bbox.minLng, 106.1);
    expect(bbox.minLat, 10.2);
    expect(bbox.maxLng, 108.3);
    expect(bbox.maxLat, 12.4);
    expect(bbox.serialize(), '106.1,10.2,108.3,12.4');
  });
}
