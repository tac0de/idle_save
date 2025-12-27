// ignore_for_file: public_member_api_docs
import 'package:idle_save/idle_save.dart';
import 'package:test/test.dart';

void main() {
  test('CanonicalJsonSaveCodec sorts map keys', () {
    const codec = CanonicalJsonSaveCodec();

    final first = {'b': 1, 'a': 2};
    final second = {'a': 2, 'b': 1};

    expect(codec.encode(first), codec.encode(second));
  });
}
