import 'package:clock/clock.dart';
import 'package:idle_save/idle_save.dart';
import 'package:test/test.dart';

SaveManager<Map<String, dynamic>> buildManager({
  required SaveStore store,
  SaveStore? backup,
  Clock? clock,
}) {
  return SaveManager<Map<String, dynamic>>(
    store: store,
    backupStore: backup,
    codec: const JsonSaveCodec(),
    migrator: Migrator(latestVersion: 1),
    encoder: (value) => value,
    decoder: (payload) => payload,
    clock: clock ?? Clock.fixed(DateTime(2024)),
  );
}

void main() {
  test('load returns invalidJson failure', () async {
    final store = MemoryStore(initial: 'not-json');
    final manager = buildManager(store: store);

    final result = await manager.load();

    expect(result, isA<LoadFailure>());
    expect((result as LoadFailure).reason, LoadFailureReason.invalidJson);
  });

  test('load returns checksumMismatch failure', () async {
    final store = MemoryStore();
    final manager = buildManager(store: store);

    const envelope = SaveEnvelope(
      schemaVersion: 1,
      createdAtMs: 1,
      updatedAtMs: 1,
      payload: {'gold': 10},
      checksum: 'bad-checksum',
    );

    await store.write(const JsonSaveCodec().encode(envelope.toJson()));

    final result = await manager.load();

    expect(result, isA<LoadFailure>());
    expect((result as LoadFailure).reason, LoadFailureReason.checksumMismatch);
  });
}
