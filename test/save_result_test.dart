// ignore_for_file: public_member_api_docs
import 'package:idle_save/idle_save.dart';
import 'package:test/test.dart';

class ThrowingStore extends SaveStore {
  ThrowingStore({this.throwOnRead = false, this.throwOnWrite = false});

  final bool throwOnRead;
  final bool throwOnWrite;
  String? _value;

  @override
  Future<String?> read() async {
    if (throwOnRead) {
      throw StateError('read failed');
    }
    return _value;
  }

  @override
  Future<void> write(String data) async {
    if (throwOnWrite) {
      throw StateError('write failed');
    }
    _value = data;
  }

  @override
  Future<void> clear() async {
    _value = null;
  }
}

void main() {
  test('save reports invalid payloads', () async {
    final manager = SaveManager<Map<String, dynamic>>(
      store: MemoryStore(),
      codec: const JsonSaveCodec(),
      migrator: Migrator(latestVersion: 1),
      encoder: (value) => value,
      decoder: (payload) => payload,
    );

    final result = await manager.save(
      {'now': DateTime(2024)},
      context: const SaveContext(reason: SaveReason.manual),
    );

    expect(result, isA<SaveFailure>());
    expect((result as SaveFailure).reason, SaveFailureReason.invalidPayload);
  });

  test('save reports write failures', () async {
    final manager = SaveManager<Map<String, dynamic>>(
      store: ThrowingStore(throwOnWrite: true),
      codec: const JsonSaveCodec(),
      migrator: Migrator(latestVersion: 1),
      encoder: (value) => value,
      decoder: (payload) => payload,
    );

    final result = await manager.save(
      {'coins': 5},
      context: const SaveContext(reason: SaveReason.autosave),
    );

    expect(result, isA<SaveFailure>());
    expect((result as SaveFailure).reason, SaveFailureReason.writeFailed);
  });
}
