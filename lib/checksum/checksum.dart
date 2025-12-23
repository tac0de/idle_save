import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../codec/save_codec.dart';

class Checksum {
  const Checksum();

  String compute(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  String forPayload(Map<String, dynamic> payload, SaveCodec codec) {
    return compute(codec.encode(payload));
  }

  bool verifyPayload({
    required Map<String, dynamic> payload,
    required SaveCodec codec,
    required String expected,
  }) {
    return forPayload(payload, codec) == expected;
  }
}
