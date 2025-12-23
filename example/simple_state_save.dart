import 'package:idle_core/idle_core.dart';
import 'package:idle_save/idle_save.dart';

class GameState extends IdleState {
  const GameState({required this.level, required this.coins});

  final int level;
  final int coins;

  @override
  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'coins': coins,
    };
  }

  static GameState fromJson(Map<String, dynamic> json) {
    final level = json['level'] as int? ?? 0;
    final coins = json['coins'] as int? ?? 0;
    return GameState(level: level, coins: coins);
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

  await manager.save(const GameState(level: 1, coins: 25));

  final result = await manager.load();
  if (result case LoadSuccess<GameState>(:final value)) {
    print('Loaded: level=${value.level}, coins=${value.coins}');
  } else if (result is LoadFailure) {
    print('Load failed: ${result.reason}');
  }
}
