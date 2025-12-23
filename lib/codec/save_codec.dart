import 'dart:convert';

abstract class SaveCodec {
  const SaveCodec();

  String encode(Map<String, dynamic> value);

  Map<String, dynamic> decode(String raw);

  List<int> encodeBytes(Map<String, dynamic> value) {
    return utf8.encode(encode(value));
  }

  Map<String, dynamic> decodeBytes(List<int> bytes) {
    return decode(utf8.decode(bytes));
  }
}
