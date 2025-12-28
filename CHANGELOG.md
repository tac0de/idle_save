# Changelog

## 0.3.2

- Package version README update.

## 0.3.1

- Dart format .

## 0.3.0

- Require SaveContext to include SaveChangeSet.
- Record changeSet in SaveEnvelope metadata.
- Enforce latestVersion >= 1 and require migrations for versions > 1.

## 0.2.1

- minor pub score fix.

## 0.2.0

- Add SaveContext/SaveReason and SaveResult for observable saves.
- Track saveReason in SaveEnvelope metadata.
- Add MigrationContext and Migration.withContext for deterministic migrations.
- Add CanonicalJsonSaveCodec for stable JSON ordering.
- Report store read/write errors in load results.

## 0.1.2

- Treat decoder failures as invalid payloads on load.
- Update idle_core dependency and docs.

## 0.1.1

## 0.1.0

- Initial release with save envelope, codec, checksum, migrations, store, and save manager.
- `idle_core` integration helper with `IdleState` encoder.
- Example and demo app plus tests for migrations, corruption, and backups.
