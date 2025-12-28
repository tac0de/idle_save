# idle_save

🎉 **I'm thrilled to introduce `idle_save`**, a focused save SDK for idle games: deterministic serialization, explicit versioned migrations, and observable save boundaries in pure Dart. 🚀

## Quick start

```yaml
dependencies:
  idle_save: ^0.2.1
```

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
    context: const SaveContext(reason: SaveReason.manual),
  );

  final result = await manager.migrateIfNeeded();
  if (result case LoadSuccess<GameState>(:final value)) {
    print('Loaded: level=${value.level}, coins=${value.coins}');
  }
}
```

## Contact

wonyoungchoiseoul@gmail.com
