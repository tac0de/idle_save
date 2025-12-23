// ignore_for_file: public_member_api_docs
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
