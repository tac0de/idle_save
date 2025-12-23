/// Validates that payloads only contain JSON-safe values.
class JsonSafe {
  const JsonSafe._();

  /// Returns `true` if [value] is JSON-safe.
  static bool isJsonSafe(Object? value) {
    try {
      validate(value);
      return true;
    } on FormatException {
      return false;
    }
  }

  /// Throws [FormatException] if [value] is not JSON-safe.
  static void validate(Object? value) {
    _validate(value, path: r'$');
  }

  static void _validate(Object? value, {required String path}) {
    if (value == null || value is bool || value is String) {
      return;
    }
    if (value is num) {
      if (value is double && (value.isNaN || value.isInfinite)) {
        throw FormatException('Non-finite number at $path');
      }
      return;
    }
    if (value is List) {
      for (var i = 0; i < value.length; i++) {
        _validate(value[i], path: '$path[$i]');
      }
      return;
    }
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key;
        if (key is! String) {
          throw FormatException('Non-string map key at $path');
        }
        final nextPath = _mapPath(path, key);
        _validate(entry.value, path: nextPath);
      }
      return;
    }

    throw FormatException(
      'Non-JSON-safe value at $path (${value.runtimeType})',
    );
  }

  static String _mapPath(String path, String key) {
    final escaped = key.replaceAll("'", "\\'");
    return "$path['$escaped']";
  }
}
