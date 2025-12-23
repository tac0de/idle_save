/// Abstract persistence layer for save data.
abstract class SaveStore {
  /// Creates a store.
  const SaveStore();

  /// Reads the stored save, or `null` if missing.
  Future<String?> read();

  /// Writes the raw save data.
  Future<void> write(String data);

  /// Clears the stored save data.
  Future<void> clear();
}

/// In-memory store for tests or samples.
class MemoryStore extends SaveStore {
  /// Creates an in-memory store with optional [initial] value.
  MemoryStore({String? initial}) : _value = initial;

  String? _value;

  @override
  Future<String?> read() async {
    return _value;
  }

  @override
  Future<void> write(String data) async {
    _value = data;
  }

  @override
  Future<void> clear() async {
    _value = null;
  }
}
