import 'dart:convert';

/// Encodes and decodes JSON-safe payload maps.
abstract class SaveCodec {
  /// Creates a codec instance.
  const SaveCodec();

  /// Encodes a JSON-safe map into a string representation.
  String encode(Map<String, dynamic> value);

  /// Decodes a string into a JSON-safe map.
  Map<String, dynamic> decode(String raw);

  /// Encodes [value] to UTF-8 bytes.
  List<int> encodeBytes(Map<String, dynamic> value) {
    return utf8.encode(encode(value));
  }

  /// Decodes UTF-8 [bytes] into a JSON-safe map.
  Map<String, dynamic> decodeBytes(List<int> bytes) {
    return decode(utf8.decode(bytes));
  }
}
