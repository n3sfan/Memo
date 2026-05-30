typedef JsonMap = Map<String, Object?>;

JsonMap asJsonMap(Object? value, {String name = 'value'}) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map<Object?, Object?>) {
    final JsonMap json = <String, Object?>{};
    for (final MapEntry<Object?, Object?> entry in value.entries) {
      final Object? key = entry.key;
      if (key is! String) {
        throw FormatException('$name must use string keys');
      }
      json[key] = entry.value;
    }

    return json;
  }

  throw FormatException('$name must be a JSON object');
}

List<JsonMap> asJsonMapList(Object? value, {String name = 'value'}) {
  if (value is List<Object?>) {
    return value
        .map((Object? item) => asJsonMap(item, name: '$name item'))
        .toList(growable: false);
  }

  throw FormatException('$name must be a JSON array');
}

String readString(JsonMap json, String key) {
  final Object? value = json[key];
  if (value is String) {
    return value;
  }

  throw FormatException('$key must be a string');
}

String? readOptionalString(JsonMap json, String key) {
  final Object? value = json[key];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }

  throw FormatException('$key must be a string when present');
}

int readInt(JsonMap json, String key) {
  final Object? value = json[key];
  if (value is int) {
    return value;
  }

  throw FormatException('$key must be an integer');
}

int? readOptionalInt(JsonMap json, String key) {
  final Object? value = json[key];
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }

  throw FormatException('$key must be an integer when present');
}

double readDouble(JsonMap json, String key) {
  final Object? value = json[key];
  if (value is num) {
    return value.toDouble();
  }

  throw FormatException('$key must be a number');
}

bool readBool(JsonMap json, String key) {
  final Object? value = json[key];
  if (value is bool) {
    return value;
  }

  throw FormatException('$key must be a boolean');
}

bool? readOptionalBool(JsonMap json, String key) {
  final Object? value = json[key];
  if (value == null) {
    return null;
  }
  if (value is bool) {
    return value;
  }

  throw FormatException('$key must be a boolean when present');
}

DateTime readDateTime(JsonMap json, String key) {
  return DateTime.parse(readString(json, key)).toUtc();
}

DateTime? readOptionalDateTime(JsonMap json, String key) {
  final String? value = readOptionalString(json, key);
  if (value == null) {
    return null;
  }

  return DateTime.parse(value).toUtc();
}

String writeDateTime(DateTime value) {
  return value.toUtc().toIso8601String();
}
