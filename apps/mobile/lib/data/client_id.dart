import 'dart:math';

final Random _secureRandom = Random.secure();

String createLocalClientId({String prefix = 'local'}) {
  final int timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
  final int randomPart = _secureRandom.nextInt(1 << 32);

  return '${prefix}_${timestamp}_$randomPart';
}
