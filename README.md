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
  idle_save: ^0.1.0
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

  final result = await manager.load();
  if (result case LoadSuccess<GameState>(:final value)) {
    print('Loaded: level=${value.level}, coins=${value.coins}');
  }
}
```

## Demo app

Run the small CLI demo:

```sh
dart run example/demo_app.dart
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

## Integrity + backups

- Checksums are computed from the payload and validated on load.
- Provide a `backupStore` to allow fallback when the primary save is corrupt.

## Load failures

`SaveManager.load()` returns `LoadFailure` for corrupted saves or missing
migrations. Inspect `LoadFailure.reason` to decide how to recover.

## Status

API is stable for `v0.1.x`. Run `dart test` to validate.
