import 'dart:convert';

import 'save_codec.dart';

class JsonSaveCodec extends SaveCodec {
  const JsonSaveCodec();

  @override
  String encode(Map<String, dynamic> value) {
    return jsonEncode(value);
  }

  @override
  Map<String, dynamic> decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object');
    }
    return decoded;
  }
}
