// ignore_for_file: public_member_api_docs
import 'package:idle_save/idle_save.dart';
import 'package:test/test.dart';

void main() {
  test('SaveEnvelope round trips JSON', () {
    final envelope = SaveEnvelope(
      schemaVersion: 1,
      createdAtMs: 100,
      updatedAtMs: 200,
      payload: {'level': 3},
      changeSet: SaveChangeSet(note: 'level-up'),
      saveReason: 'manual',
      checksum: 'abc',
    );

    final encoded = envelope.toJson();
    final decoded = SaveEnvelope.fromJson(encoded);

    expect(decoded.schemaVersion, 1);
    expect(decoded.createdAtMs, 100);
    expect(decoded.updatedAtMs, 200);
    expect(decoded.payload, {'level': 3});
    expect(decoded.changeSet?.note, 'level-up');
    expect(decoded.saveReason, 'manual');
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

  test('SaveEnvelope rejects invalid save reason', () {
    final json = {
      'schemaVersion': 1,
      'createdAtMs': 100,
      'updatedAtMs': 200,
      'payload': {'level': 1},
      'saveReason': 123,
    };

    expect(() => SaveEnvelope.fromJson(json), throwsFormatException);
  });
}
