import 'package:flutter_test/flutter_test.dart';
import 'package:memory_map_mobile/app/router.dart';

void main() {
  test('parses valid map focus coordinates from route query parameters', () {
    final coordinates = coordinatesFromQuery(
      Uri.parse('/?lat=10.762622&lng=106.660172'),
    );

    expect(coordinates, isNotNull);
    expect(coordinates!.lat, 10.762622);
    expect(coordinates.lng, 106.660172);
  });

  test('rejects invalid map focus coordinates', () {
    expect(
      coordinatesFromQuery(Uri.parse('/?lat=999&lng=106.660172')),
      isNull,
    );
    expect(
      coordinatesFromQuery(Uri.parse('/?lat=NaN&lng=106.660172')),
      isNull,
    );
    expect(
      coordinatesFromQuery(Uri.parse('/?lat=10.762622')),
      isNull,
    );
  });
}
