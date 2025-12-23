import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../codec/save_codec.dart';

/// Computes SHA-256 checksums for payload integrity.
class Checksum {
  /// Creates a checksum helper.
  const Checksum();

  /// Computes a SHA-256 hash for the provided [input].
  String compute(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  /// Computes a checksum for a JSON-safe [payload] using [codec].
  String forPayload(Map<String, dynamic> payload, SaveCodec codec) {
    return compute(codec.encode(payload));
  }

  /// Verifies that [payload] matches the [expected] checksum.
  bool verifyPayload({
    required Map<String, dynamic> payload,
    required SaveCodec codec,
    required String expected,
  }) {
    return forPayload(payload, codec) == expected;
  }
}
