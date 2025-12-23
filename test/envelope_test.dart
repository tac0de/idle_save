import 'package:idle_save/idle_save.dart';
import 'package:test/test.dart';

void main() {
  test('SaveEnvelope round trips JSON', () {
    const envelope = SaveEnvelope(
      schemaVersion: 1,
      createdAtMs: 100,
      updatedAtMs: 200,
      payload: {'level': 3},
      checksum: 'abc',
    );

    final encoded = envelope.toJson();
    final decoded = SaveEnvelope.fromJson(encoded);

    expect(decoded.schemaVersion, 1);
    expect(decoded.createdAtMs, 100);
    expect(decoded.updatedAtMs, 200);
    expect(decoded.payload, {'level': 3});
    expect(decoded.checksum, 'abc');
  });

  test('SaveEnvelope rejects invalid payload', () {
    final json = {
      'schemaVersion': 1,
      'createdAtMs': 100,
      'updatedAtMs': 200,
      'payload': ['not-a-map'],
    };

    expect(() => SaveEnvelope.fromJson(json), throwsFormatException);
  });
}
