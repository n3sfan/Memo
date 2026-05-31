import '../data/models/coordinates.dart';

BboxQuery bboxFromEdges({
  required double west,
  required double south,
  required double east,
  required double north,
}) {
  return BboxQuery(
    minLng: west,
    minLat: south,
    maxLng: east,
    maxLat: north,
  );
}
