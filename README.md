# idle_save

Engine-level save SDK for idle games. Deterministic serialization, versioned migrations, and observable save boundaries in pure Dart.

## Installation

```yaml
dependencies:
  idle_save: ^0.3.2
```

## Concepts

- SaveEnvelope: metadata wrapper for your payload (schema version, timestamps, reason, change set, checksum).
- SaveManager: orchestrates load, migrate, verify, and save.
- Migrator: explicit, ordered migration chain (1 -> N).
- SaveContext: required save boundary info (why + what changed).
- SaveStore: storage abstraction (memory/file/custom).

## Quick start

```dart
import 'package:idle_core/idle_core.dart';
import 'package:idle_save/idle_save.dart';

class GameState extends IdleState {
  const GameState({required this.level, required this.coins});

  final int level;
  final int coins;

  @override
  Map<String, dynamic> toJson() => {'level': level, 'coins': coins};

  static GameState fromJson(Map<String, dynamic> json) {
    return GameState(
      level: json['level'] as int? ?? 0,
      coins: json['coins'] as int? ?? 0,
    );
  }
}

Future<void> main() async {
  final manager = idleCoreSaveManager<GameState>(
    store: MemoryStore(),
    codec: const CanonicalJsonSaveCodec(),
    migrator: Migrator(latestVersion: 1),
    decoder: GameState.fromJson,
  );

  await manager.save(
    const GameState(level: 1, coins: 10),
    context: SaveContext(
      reason: SaveReason.manual,
      changeSet: SaveChangeSet(updated: ['level', 'coins']),
    ),
  );

  final result = await manager.migrateIfNeeded();
  if (result case LoadSuccess<GameState>(:final value)) {
    print('Loaded: level=${value.level}, coins=${value.coins}');
  }
}
```

## Tutorial

### 1) Define state serialization

Your state must be JSON-safe (no DateTime, no non-string map keys, no NaN).

```dart
class GameState extends IdleState {
  const GameState({required this.level, required this.coins});

  final int level;
  final int coins;

  @override
  Map<String, dynamic> toJson() => {'level': level, 'coins': coins};

  static GameState fromJson(Map<String, dynamic> json) {
    return GameState(
      level: json['level'] as int? ?? 0,
      coins: json['coins'] as int? ?? 0,
    );
  }
}
```

### 2) Define migrations

Migrations are deterministic, ordered, and required for version bumps.

```dart
final migrator = Migrator(
  latestVersion: 2,
  migrations: [
    Migration(
      from: 1,
      to: 2,
      migrate: (payload) => {
        ...payload,
        'coins': (payload['coins'] as int?) ?? 0,
      },
    ),
  ],
);
```

### 3) Create a SaveManager

Choose a codec and a store. CanonicalJsonSaveCodec is a safe default.

```dart
final manager = idleCoreSaveManager<GameState>(
  store: MemoryStore(),
  codec: const CanonicalJsonSaveCodec(),
  migrator: migrator,
  decoder: GameState.fromJson,
);
```

### 4) Save with an explicit boundary

SaveContext is required. It captures why the save happened and what changed.

```dart
final result = await manager.save(
  const GameState(level: 2, coins: 15),
  context: SaveContext(
    reason: SaveReason.autosave,
    changeSet: SaveChangeSet(updated: ['level', 'coins']),
  ),
);
if (result is SaveFailure) {
  print('Save failed: ${result.reason}');
}
```

### 5) Load and migrate

Use migrateIfNeeded on startup to apply migrations and write back.

```dart
final loaded = await manager.migrateIfNeeded();
if (loaded case LoadSuccess<GameState>(:final value)) {
  print('Loaded: ${value.level}');
} else if (loaded is LoadFailure) {
  print('Load failed: ${loaded.reason}');
}
```

## API Overview

### SaveEnvelope

- schemaVersion: payload schema version.
- createdAtMs/updatedAtMs: timestamps in ms since epoch.
- saveReason: why the save happened.
- changeSet: what changed.
- checksum: integrity hash (optional).

### SaveManager

- save(value, context): returns SaveResult.
- load(): reads without write-back.
- migrateIfNeeded(): reads, migrates, and writes back when needed.

### Migrator

- latestVersion: current schema version (must be >= 1).
- migrations: ordered list of Migration(from -> to).

### SaveStore

- read(): returns raw string or null.
- write(data): persists raw string.
- clear(): deletes save data.

## Templates

Single-file custom codec/store templates live in `example/custom_templates.dart`.

## Contact

wonyoungchoiseoul@gmail.com
