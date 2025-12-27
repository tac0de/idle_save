/// Versioned save + migration chain + integrity helpers for `idle_core` states.
library idle_save;

export 'checksum/checksum.dart';
export 'codec/canonical_json_save_codec.dart';
export 'codec/json_safe.dart';
export 'codec/json_save_codec.dart';
export 'codec/save_codec.dart';
export 'envelope/save_envelope.dart';
export 'idle_core/idle_core_save.dart';
export 'migrator/migrator.dart';
export 'save_manager/save_manager.dart';
export 'store/file_store.dart';
export 'store/save_store.dart';
