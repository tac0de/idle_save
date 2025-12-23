// ignore_for_file: public_member_api_docs
import 'dart:io';

import 'package:idle_save/idle_save.dart';
import 'package:test/test.dart';

void main() {
  test('FileStore reads, writes, and clears', () async {
    final dir = await Directory.systemTemp.createTemp('idle_save_');
    final file = File('${dir.path}/save.json');
    final store = FileStore.file(file);

    expect(await store.read(), isNull);

    await store.write('payload');
    expect(await store.read(), 'payload');

    await store.clear();
    expect(await store.read(), isNull);

    await dir.delete(recursive: true);
  });
}
