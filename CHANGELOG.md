# Changelog

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
