import 'dart:collection';
import 'dart:convert';

import 'save_codec.dart';

/// JSON codec that canonicalizes maps by sorting keys.
class CanonicalJsonSaveCodec extends SaveCodec {
  /// Creates a canonical JSON codec.
  const CanonicalJsonSaveCodec();

  /// Encodes a JSON-safe map to a canonical JSON string.
  @override
  String encode(Map<String, dynamic> value) {
    return jsonEncode(_canonicalize(value));
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

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final sorted = SplayTreeMap<String, dynamic>();
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        throw const FormatException('Non-string map key');
      }
      sorted[key] = _canonicalize(entry.value);
    }
    return sorted;
  }
  if (value is List) {
    return value.map(_canonicalize).toList(growable: false);
  }
  return value;
}
