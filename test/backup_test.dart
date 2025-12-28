// ignore_for_file: public_member_api_docs
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
    clock: clock ??
        Clock.fixed(
          DateTime(
            2024,
          ),
        ),
  );
}

void main() {
  test('load falls back to backup when primary is corrupt', () async {
    final primary = MemoryStore(initial: 'not-json');
    final backup = MemoryStore();
    final manager = buildManager(store: primary, backup: backup);

    const codec = JsonSaveCodec();
    const checksum = Checksum();
    final payload = {'level': 2};
    final envelope = SaveEnvelope(
      schemaVersion: 1,
      createdAtMs: 1,
      updatedAtMs: 1,
      payload: payload,
      checksum: checksum.forPayload(payload, codec),
    );
    await backup.write(codec.encode(envelope.toJson()));

    final result = await manager.load();

    expect(result, isA<LoadSuccess<Map<String, dynamic>>>());
    final success = result as LoadSuccess<Map<String, dynamic>>;
    expect(success.fromBackup, true);
    expect(success.value, payload);
  });

  test('save writes previous value to backup store', () async {
    final primary = MemoryStore();
    final backup = MemoryStore();
    final manager = buildManager(store: primary, backup: backup);

    final firstResult = await manager.save(
      {'coins': 5},
      context: SaveContext(
        reason: SaveReason.manual,
        changeSet: SaveChangeSet(updated: ['coins']),
      ),
    );
    expect(firstResult, isA<SaveSuccess>());
    final firstRaw = await primary.read();

    final secondResult = await manager.save(
      {'coins': 10},
      context: SaveContext(
        reason: SaveReason.autosave,
        changeSet: SaveChangeSet(updated: ['coins']),
      ),
    );
    expect(secondResult, isA<SaveSuccess>());
    final backupRaw = await backup.read();

    expect(backupRaw, firstRaw);
  });
}
