import 'package:clock/clock.dart';
import 'package:idle_core/idle_core.dart';

import '../checksum/checksum.dart';
import '../codec/save_codec.dart';
import '../migrator/migrator.dart';
import '../save_manager/save_manager.dart';
import '../store/save_store.dart';

/// Decoder for an [IdleState] from a JSON-safe map.
typedef IdleStateDecoder<S extends IdleState> = S Function(
  Map<String, dynamic> json,
);

/// Builds a [SaveManager] wired for `idle_core` [IdleState] types.
///
/// Uses [IdleState.toJson] for encoding and the provided [decoder] for loading.
SaveManager<S> idleCoreSaveManager<S extends IdleState>({
  required SaveStore store,
  required SaveCodec codec,
  required Migrator migrator,
  required IdleStateDecoder<S> decoder,
  SaveStore? backupStore,
  TickClock? tickClock,
  Clock? clock,
  Checksum checksum = const Checksum(),
  bool useChecksum = true,
  bool verifyChecksum = true,
}) {
  final effectiveClock = clock ??
      (tickClock != null
          ? Clock(() => DateTime.fromMillisecondsSinceEpoch(tickClock.nowMs()))
          : null);

  return SaveManager<S>(
    store: store,
    backupStore: backupStore,
    codec: codec,
    migrator: migrator,
    encoder: (value) => value.toJson(),
    decoder: decoder,
    clock: effectiveClock,
    checksum: checksum,
    useChecksum: useChecksum,
    verifyChecksum: verifyChecksum,
  );
}
