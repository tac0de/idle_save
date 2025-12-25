import 'dart:convert';

import 'save_codec.dart';

/// JSON codec using `dart:convert` `jsonEncode`/`jsonDecode`.
class JsonSaveCodec extends SaveCodec {
  /// Creates a JSON codec.
  const JsonSaveCodec();

  /// Encodes a JSON-safe map to a JSON string.
  @override
  String encode(Map<String, dynamic> value) {
    return jsonEncode(value);
  }

  /// Decodes a JSON string into a JSON-safe map.
  @override
  Map<String, dynamic> decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object');
    }
    return decoded;
  }
}
