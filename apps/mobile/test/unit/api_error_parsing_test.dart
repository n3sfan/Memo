import 'package:flutter_test/flutter_test.dart';
import 'package:memory_map_mobile/data/models/models.dart';

void main() {
  test('parses backend error envelope into ApiError', () {
    final ApiError error = ApiError.fromJson(<String, Object?>{
      'error': 'validation_error',
      'message': 'Invalid coordinates',
      'details': <String, Object?>{
        'lat': 'out_of_range',
      },
      'requestId': 'req_test',
    });

    expect(error.error, 'validation_error');
    expect(error.message, 'Invalid coordinates');
    expect(error.details['lat'], 'out_of_range');
    expect(error.requestId, 'req_test');
  });
}
