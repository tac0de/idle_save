// ignore_for_file: public_member_api_docs
import 'package:idle_save/idle_save.dart';
import 'package:test/test.dart';

void main() {
  test('JsonSafe validates nested payloads', () {
    final payload = {
      'level': 1,
      'items': [
        {'id': 'a', 'count': 2},
        {'id': 'b', 'count': 3},
      ],
      'flags': [true, false, null],
    };

    expect(() => JsonSafe.validate(payload), returnsNormally);
    expect(JsonSafe.isJsonSafe(payload), true);
  });

  test('JsonSafe rejects non-string map keys', () {
    final payload = {1: 'bad'};

    expect(() => JsonSafe.validate(payload), throwsFormatException);
    expect(JsonSafe.isJsonSafe(payload), false);
  });

  test('JsonSafe rejects unsupported values', () {
    final payload = {'now': DateTime(2024, 1, 1)};

    expect(() => JsonSafe.validate(payload), throwsFormatException);
    expect(JsonSafe.isJsonSafe(payload), false);
  });

  test('JsonSafe rejects non-finite numbers', () {
    final payload = {'value': double.nan};

    expect(() => JsonSafe.validate(payload), throwsFormatException);
    expect(JsonSafe.isJsonSafe(payload), false);
  });
}
