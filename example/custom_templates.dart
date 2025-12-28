// ignore_for_file: public_member_api_docs
import 'dart:convert';

import 'package:idle_save/idle_save.dart';

/// Single-file template for a custom codec.
class Base64JsonSaveCodec extends SaveCodec {
  const Base64JsonSaveCodec();

  @override
  String encode(Map<String, dynamic> value) {
    final json = jsonEncode(value);
    return base64Encode(utf8.encode(json));
  }

  @override
  Map<String, dynamic> decode(String raw) {
    final json = utf8.decode(base64Decode(raw));
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object');
    }
    return decoded;
  }
}

/// Single-file template for a custom store.
class CallbackSaveStore extends SaveStore {
  CallbackSaveStore({
    required this.readData,
    required this.writeData,
    required this.clearData,
  });

  final Future<String?> Function() readData;
  final Future<void> Function(String data) writeData;
  final Future<void> Function() clearData;

  @override
  Future<String?> read() => readData();

  @override
  Future<void> write(String data) => writeData(data);

  @override
  Future<void> clear() => clearData();
}
