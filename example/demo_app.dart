// ignore_for_file: public_member_api_docs
import 'package:idle_core/idle_core.dart';
import 'package:idle_save/idle_save.dart';

class GameState extends IdleState {
  const GameState({required this.gold, required this.rate});

  final int gold;
  final int rate;

  GameState copyWith({int? gold, int? rate}) {
    return GameState(
      gold: gold ?? this.gold,
      rate: rate ?? this.rate,
    );
  }

  @override
  Map<String, dynamic> toJson() => {'gold': gold, 'rate': rate};

  static GameState fromJson(Map<String, dynamic> json) {
    return GameState(
      gold: json['gold'] as int? ?? 0,
      rate: json['rate'] as int? ?? 1,
    );
  }
}

class UpgradeRate extends IdleAction {
  const UpgradeRate(this.delta);

  final int delta;
}

GameState reducer(GameState state, IdleAction action) {
  if (action is IdleTickAction) {
    return state.copyWith(gold: state.gold + state.rate);
  }
  if (action is UpgradeRate) {
    return state.copyWith(rate: state.rate + action.delta);
  }
  return state;
}

Future<void> main() async {
  final engine = IdleEngine<GameState>(
    config: IdleConfig<GameState>(dtMs: 1000),
    reducer: reducer,
    state: const GameState(gold: 0, rate: 1),
  );

  engine.tick(count: 5);
  engine.dispatch(const UpgradeRate(2));
  engine.tick(count: 3);

  final store = MemoryStore();
  final manager = idleCoreSaveManager<GameState>(
    store: store,
    codec: const JsonSaveCodec(),
    migrator: Migrator(latestVersion: 1),
    decoder: GameState.fromJson,
  );

  await manager.save(engine.state);

  final loaded = await manager.load();
  if (loaded case LoadSuccess<GameState>(:final value)) {
    print('Saved + loaded: ${value.toJson()}');
  } else if (loaded is LoadFailure) {
    print('Load failed: ${loaded.reason}');
  }
}
