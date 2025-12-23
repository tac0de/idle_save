import 'dart:io';

import 'save_store.dart';

/// File-backed store for simple persistence.
class FileStore extends SaveStore {
  /// Creates a file store targeting [path].
  FileStore(String path) : _file = File(path);

  /// Creates a file store targeting an existing [file].
  FileStore.file(File file) : _file = file;

  final File _file;

  /// The underlying file used for persistence.
  File get file => _file;

  @override
  Future<String?> read() async {
    if (!await _file.exists()) {
      return null;
    }
    return _file.readAsString();
  }

  @override
  Future<void> write(String data) async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(data);
  }

  @override
  Future<void> clear() async {
    if (await _file.exists()) {
      await _file.delete();
    }
  }
}
