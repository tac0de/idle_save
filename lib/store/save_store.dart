abstract class SaveStore {
  const SaveStore();

  Future<String?> read();

  Future<void> write(String data);

  Future<void> clear();
}

class MemoryStore extends SaveStore {
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
