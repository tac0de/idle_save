# idle_save

Versioned save + migration chain + integrity helpers for `idle_core` states. Pure Dart (no Flutter).

## Features

- JSON-safe envelope with schema version + timestamps
- Deterministic migration chain with validation
- Optional checksum integrity checks
- Backup slot fallback for corrupted saves
- First-class integration with `idle_core` `IdleState`

## Installation

```yaml
dependencies:
  idle_save: ^0.1.2
```

## Usage guide

1. Define an `IdleState` that can serialize to JSON.
2. Create a `SaveManager` using `idleCoreSaveManager`.
3. Call `save()` and `migrateIfNeeded()` where appropriate in your app lifecycle.

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
  final store = FileStore('build/save.json');
  final manager = idleCoreSaveManager<GameState>(
    store: store,
    codec: const JsonSaveCodec(),
    migrator: Migrator(latestVersion: 1),
    decoder: GameState.fromJson,
  );

  await manager.save(const GameState(level: 1, coins: 10));

  final result = await manager.migrateIfNeeded();
  if (result case LoadSuccess<GameState>(:final value)) {
    print('Loaded: level=${value.level}, coins=${value.coins}');
  }
}
```

## 5-min usage

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
  final store = MemoryStore();

  final manager = idleCoreSaveManager<GameState>(
    store: store,
    codec: const JsonSaveCodec(),
    migrator: Migrator(latestVersion: 1),
    decoder: GameState.fromJson,
  );

  await manager.save(const GameState(level: 1, coins: 10));

  final result = await manager.migrateIfNeeded();
  if (result case LoadSuccess<GameState>(:final value)) {
    print('Loaded: level=${value.level}, coins=${value.coins}');
  }
}
```

## Demo app

```sh
dart run example/example.dart
```

## File storage

Use the built-in file-backed store for quick persistence:

```dart
final store = FileStore('build/save.json');
final manager = idleCoreSaveManager<GameState>(
  store: store,
  codec: const JsonSaveCodec(),
  migrator: Migrator(latestVersion: 1),
  decoder: GameState.fromJson,
);
```

## API overview

- `SaveEnvelope` wraps metadata, payload, and checksum.
- `SaveCodec` encodes/decodes JSON-safe maps.
- `Migrator` applies deterministic `Migration`s from 1 → N.
- `SaveStore` abstracts persistence (`MemoryStore` included).
- `SaveManager<T>` loads, verifies, migrates, and saves.
- `idleCoreSaveManager` wires `IdleState.toJson()` automatically.

## Migrations

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

final migrator = Migrator(
  latestVersion: 3,
  migrations: [
    Migration(from: 1, to: 2, migrate: (payload) {
      return {...payload, 'xp': 0};
    }),
    Migration(from: 2, to: 3, migrate: (payload) {
      return {
        ...payload,
        'coins': (payload['coins'] as int?) ?? 0,
      };
    }),
  ],
);
```

After defining migrations, call `migrateIfNeeded()` on startup to write back the
upgraded save:

```dart
final result = await manager.migrateIfNeeded();
if (result case LoadSuccess<GameState>(:final envelope)) {
  print('Schema version: ${envelope.schemaVersion}');
}
```

## Integrity + backups

- Checksums are computed from the payload and validated on load.
- Provide a `backupStore` to allow fallback when the primary save is corrupt.

```dart
final primary = FileStore('build/save.json');
final backup = FileStore('build/save.bak.json');

final manager = idleCoreSaveManager<GameState>(
  store: primary,
  backupStore: backup,
  codec: const JsonSaveCodec(),
  migrator: Migrator(latestVersion: 1),
  decoder: GameState.fromJson,
);
```

## Payload validation

`SaveManager` validates that payloads are JSON-safe (no `DateTime`, no
non-string map keys, no `NaN` or `Infinity`). Disable with
`validatePayload: false` if you have a custom codec and know what you are
doing.

## Load failures

`SaveManager.load()` returns `LoadFailure` for corrupted saves, missing
migrations, or decoder failures. Inspect `LoadFailure.reason` to decide how
to recover.

```dart
final result = await manager.load();
if (result is LoadFailure) {
  switch (result.reason) {
    case LoadFailureReason.checksumMismatch:
      // Offer reset or fallback.
      break;
    case LoadFailureReason.migrationMissing:
      // Prompt for update or clear save.
      break;
    default:
      break;
  }
}
```

## Save envelope

You can access the `SaveEnvelope` metadata from `LoadSuccess.envelope` to
inspect timestamps, schema version, or checksum.

## Status

API is stable for `v0.1.x`. Run `dart test` to validate.
