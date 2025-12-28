import 'save_store.dart';

/// Web fallback for file-backed persistence.
///
/// This implementation stores data in memory only and is not persistent.
/// Provide a custom [SaveStore] for durable web storage.
class FileStore extends SaveStore {
  /// Creates an in-memory fallback store.
  FileStore(String path)
      : _path = path,
        _fileRef = null;

  /// Creates an in-memory fallback store for a file-like handle.
  FileStore.file(Object file)
      : _path = null,
        _fileRef = file;

  final MemoryStore _delegate = MemoryStore();
  final String? _path;
  final Object? _fileRef;

  /// Returns the configured path when provided.
  String? get path => _path;

  /// Returns the file-like reference when provided.
  Object? get fileRef => _fileRef;

  @override
  Future<String?> read() {
    return _delegate.read();
  }

  @override
  Future<void> write(String data) {
    return _delegate.write(data);
  }

  @override
  Future<void> clear() {
    return _delegate.clear();
  }
}
