import 'package:clock/clock.dart';

import '../checksum/checksum.dart';
import '../codec/json_safe.dart';
import '../codec/save_codec.dart';
import '../envelope/save_envelope.dart';
import '../migrator/migrator.dart';
import '../store/save_store.dart';

/// Reason for a failed load operation.
enum LoadFailureReason {
  /// No save data was found.
  notFound,

  /// Data could not be decoded by the codec.
  invalidJson,

  /// Envelope metadata failed validation.
  invalidEnvelope,

  /// Payload is not JSON-safe or fails validation.
  invalidPayload,

  /// Payload checksum did not match.
  checksumMismatch,

  /// Required migration step is missing.
  migrationMissing,

  /// Migration failed with an unexpected error.
  migrationFailed,

  /// Save schema is newer than the latest known version.
  futureSchema,
}

/// Base type for load results.
sealed class LoadResult<T> {
  /// Creates a load result.
  const LoadResult();
}

/// Successful load result.
class LoadSuccess<T> extends LoadResult<T> {
  /// Creates a success result.
  const LoadSuccess({
    required this.value,
    required this.envelope,
    required this.migrated,
    required this.fromBackup,
  });

  /// Loaded value after optional migration.
  final T value;

  /// The parsed envelope metadata.
  final SaveEnvelope envelope;

  /// Whether a migration was applied.
  final bool migrated;

  /// Whether the data came from the backup store.
  final bool fromBackup;
}

/// Failed load result.
class LoadFailure extends LoadResult<Never> {
  /// Creates a failure result.
  const LoadFailure({
    required this.reason,
    required this.raw,
  });

  /// Failure reason.
  final LoadFailureReason reason;

  /// Raw payload when available.
  final String? raw;
}

/// Coordinates saving, loading, and migrations for a payload type.
class SaveManager<T> {
  /// Creates a save manager.
  ///
  /// Set [backupStore] to enable fallback reads and backup writes.
  /// Set [validatePayload] to `false` if your codec handles non-JSON values.
  SaveManager({
    required SaveStore store,
    required SaveCodec codec,
    required Migrator migrator,
    required Map<String, dynamic> Function(T value) encoder,
    required T Function(Map<String, dynamic> payload) decoder,
    SaveStore? backupStore,
    Clock? clock,
    Checksum checksum = const Checksum(),
    bool useChecksum = true,
    bool verifyChecksum = true,
    bool validatePayload = true,
  })  : _store = store,
        _backupStore = backupStore,
        _codec = codec,
        _migrator = migrator,
        _encoder = encoder,
        _decoder = decoder,
        _clock = clock ?? const Clock(),
        _checksum = checksum,
        _useChecksum = useChecksum,
        _verifyChecksum = verifyChecksum,
        _validatePayload = validatePayload;

  final SaveStore _store;
  final SaveStore? _backupStore;
  final SaveCodec _codec;
  final Migrator _migrator;
  final Map<String, dynamic> Function(T value) _encoder;
  final T Function(Map<String, dynamic> payload) _decoder;
  final Clock _clock;
  final Checksum _checksum;
  final bool _useChecksum;
  final bool _verifyChecksum;
  final bool _validatePayload;

  /// Loads the current save without writing it back.
  Future<LoadResult<T>> load() async {
    return _load(writeBack: false);
  }

  /// Loads and persists the migrated save when needed.
  Future<LoadResult<T>> migrateIfNeeded() async {
    return _load(writeBack: true);
  }

  /// Saves a new value, writing the previous value to backup if configured.
  Future<void> save(T value) async {
    final nowMs = _clock.now().millisecondsSinceEpoch;
    final previous = await _readEnvelope(_store, fromBackup: false);
    final createdAtMs = previous is LoadSuccess<_LoadedEnvelope>
        ? previous.value.envelope.createdAtMs
        : nowMs;

    final payload = _encoder(value);
    if (_validatePayload) {
      JsonSafe.validate(payload);
    }
    var envelope = SaveEnvelope(
      schemaVersion: _migrator.latestVersion,
      createdAtMs: createdAtMs,
      updatedAtMs: nowMs,
      payload: payload,
    );

    envelope = _applyChecksum(envelope);

    final raw = _codec.encode(envelope.toJson());
    if (_backupStore != null) {
      final existing = await _store.read();
      if (existing != null) {
        await _backupStore!.write(existing);
      }
    }
    await _store.write(raw);
  }

  Future<LoadResult<T>> _load({required bool writeBack}) async {
    final loadedResult = await _readPrimaryOrBackup();
    if (loadedResult is LoadFailure) {
      return loadedResult;
    }

    final loadedSuccess = loadedResult as LoadSuccess<_LoadedEnvelope>;
    final migrationResult = _migrateEnvelope(loadedSuccess.value);
    if (migrationResult is LoadFailure) {
      return migrationResult;
    }

    final migrationSuccess = migrationResult as LoadSuccess<_LoadedEnvelope>;
    final loaded = migrationSuccess.value;
    var envelope = loaded.envelope;

    if (writeBack && (loaded.migrated || loaded.fromBackup)) {
      final nowMs = _clock.now().millisecondsSinceEpoch;
      envelope = _applyChecksum(envelope.copyWith(updatedAtMs: nowMs));
      final raw = _codec.encode(envelope.toJson());
      if (_backupStore != null) {
        final existing = await _store.read();
        if (existing != null) {
          await _backupStore!.write(existing);
        }
      }
      await _store.write(raw);
    }

    final value = _decoder(envelope.payload);

    return LoadSuccess<T>(
      value: value,
      envelope: envelope,
      migrated: loaded.migrated,
      fromBackup: loaded.fromBackup,
    );
  }

  Future<LoadResult<_LoadedEnvelope>> _readPrimaryOrBackup() async {
    final primary = await _readEnvelope(_store, fromBackup: false);
    if (primary is LoadSuccess<_LoadedEnvelope>) {
      return primary;
    }
    if (_backupStore == null) {
      return primary;
    }
    final backup = await _readEnvelope(_backupStore!, fromBackup: true);
    if (backup is LoadSuccess<_LoadedEnvelope>) {
      return backup;
    }
    return primary;
  }

  Future<LoadResult<_LoadedEnvelope>> _readEnvelope(
    SaveStore store, {
    required bool fromBackup,
  }) async {
    final raw = await store.read();
    if (raw == null) {
      return const LoadFailure(reason: LoadFailureReason.notFound, raw: null);
    }

    Map<String, dynamic> decoded;
    try {
      decoded = _codec.decode(raw);
    } catch (_) {
      return LoadFailure(reason: LoadFailureReason.invalidJson, raw: raw);
    }

    SaveEnvelope envelope;
    try {
      envelope = SaveEnvelope.fromJson(decoded);
    } catch (_) {
      return LoadFailure(reason: LoadFailureReason.invalidEnvelope, raw: raw);
    }

    if (_verifyChecksum && envelope.checksum != null) {
      final ok = _checksum.verifyPayload(
        payload: envelope.payload,
        codec: _codec,
        expected: envelope.checksum!,
      );
      if (!ok) {
        return LoadFailure(
          reason: LoadFailureReason.checksumMismatch,
          raw: raw,
        );
      }
    }

    if (_validatePayload) {
      try {
        JsonSafe.validate(envelope.payload);
      } on FormatException {
        return LoadFailure(
          reason: LoadFailureReason.invalidPayload,
          raw: raw,
        );
      }
    }

    return LoadSuccess<_LoadedEnvelope>(
      value: _LoadedEnvelope(
        envelope: envelope,
        raw: raw,
        fromBackup: fromBackup,
        migrated: false,
      ),
      envelope: envelope,
      migrated: false,
      fromBackup: fromBackup,
    );
  }

  LoadResult<_LoadedEnvelope> _migrateEnvelope(_LoadedEnvelope loaded) {
    final envelope = loaded.envelope;
    if (envelope.schemaVersion > _migrator.latestVersion) {
      return LoadFailure(
        reason: LoadFailureReason.futureSchema,
        raw: loaded.raw,
      );
    }
    if (envelope.schemaVersion == _migrator.latestVersion) {
      return LoadSuccess<_LoadedEnvelope>(
        value: loaded,
        envelope: envelope,
        migrated: loaded.migrated,
        fromBackup: loaded.fromBackup,
      );
    }

    try {
      final migration = _migrator.migrate(
        fromVersion: envelope.schemaVersion,
        payload: envelope.payload,
      );
      if (_validatePayload) {
        JsonSafe.validate(migration.payload);
      }
      var migratedEnvelope = envelope.copyWith(
        schemaVersion: migration.version,
        payload: migration.payload,
      );
      migratedEnvelope = _applyChecksum(migratedEnvelope);
      return LoadSuccess<_LoadedEnvelope>(
        value: _LoadedEnvelope(
          envelope: migratedEnvelope,
          raw: loaded.raw,
          fromBackup: loaded.fromBackup,
          migrated: true,
        ),
        envelope: migratedEnvelope,
        migrated: true,
        fromBackup: loaded.fromBackup,
      );
    } on StateError {
      return LoadFailure(
        reason: LoadFailureReason.migrationMissing,
        raw: loaded.raw,
      );
    } on FormatException {
      return LoadFailure(
        reason: LoadFailureReason.invalidPayload,
        raw: loaded.raw,
      );
    } catch (_) {
      return LoadFailure(
        reason: LoadFailureReason.migrationFailed,
        raw: loaded.raw,
      );
    }
  }

  SaveEnvelope _applyChecksum(SaveEnvelope envelope) {
    if (!_useChecksum) {
      return envelope.copyWith(checksum: null);
    }
    final checksum = _checksum.forPayload(envelope.payload, _codec);
    return envelope.copyWith(checksum: checksum);
  }
}

class _LoadedEnvelope {
  const _LoadedEnvelope({
    required this.envelope,
    required this.raw,
    required this.fromBackup,
    required this.migrated,
  });

  final SaveEnvelope envelope;
  final String raw;
  final bool fromBackup;
  final bool migrated;
}
