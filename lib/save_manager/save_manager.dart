import 'package:clock/clock.dart';

import '../checksum/checksum.dart';
import '../codec/save_codec.dart';
import '../envelope/save_envelope.dart';
import '../migrator/migrator.dart';
import '../store/save_store.dart';

enum LoadFailureReason {
  notFound,
  invalidJson,
  invalidEnvelope,
  checksumMismatch,
  migrationMissing,
  migrationFailed,
  futureSchema,
}

sealed class LoadResult<T> {
  const LoadResult();
}

class LoadSuccess<T> extends LoadResult<T> {
  const LoadSuccess({
    required this.value,
    required this.envelope,
    required this.migrated,
    required this.fromBackup,
  });

  final T value;
  final SaveEnvelope envelope;
  final bool migrated;
  final bool fromBackup;
}

class LoadFailure extends LoadResult<Never> {
  const LoadFailure({
    required this.reason,
    required this.raw,
  });

  final LoadFailureReason reason;
  final String? raw;
}

class SaveManager<T> {
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
  })  : _store = store,
        _backupStore = backupStore,
        _codec = codec,
        _migrator = migrator,
        _encoder = encoder,
        _decoder = decoder,
        _clock = clock ?? const Clock(),
        _checksum = checksum,
        _useChecksum = useChecksum,
        _verifyChecksum = verifyChecksum;

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

  Future<LoadResult<T>> load() async {
    return _load(writeBack: false);
  }

  Future<LoadResult<T>> migrateIfNeeded() async {
    return _load(writeBack: true);
  }

  Future<void> save(T value) async {
    final nowMs = _clock.now().millisecondsSinceEpoch;
    final previous = await _readEnvelope(_store, fromBackup: false);
    final createdAtMs = previous is LoadSuccess<_LoadedEnvelope>
        ? previous.value.envelope.createdAtMs
        : nowMs;

    final payload = _encoder(value);
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
