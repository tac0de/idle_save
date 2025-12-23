// ignore_for_file: public_member_api_docs
import 'package:idle_save/idle_save.dart';
import 'package:test/test.dart';

void main() {
  test('Migrator applies sequential migrations', () {
    final migrator = Migrator(
      latestVersion: 3,
      migrations: [
        Migration(
          from: 1,
          to: 2,
          migrate: (payload) => {
            ...payload,
            'v2': true,
          },
        ),
        Migration(
          from: 2,
          to: 3,
          migrate: (payload) => {
            ...payload,
            'v3': payload['v2'] == true,
          },
        ),
      ],
    );

    final result = migrator.migrate(fromVersion: 1, payload: {'level': 1});

    expect(result.version, 3);
    expect(result.payload['level'], 1);
    expect(result.payload['v2'], true);
    expect(result.payload['v3'], true);
  });

  test('Migrator rejects gaps', () {
    expect(
      () => Migrator(
        latestVersion: 3,
        migrations: [
          Migration(from: 1, to: 2, migrate: (payload) => payload),
          Migration(from: 3, to: 4, migrate: (payload) => payload),
        ],
      ),
      throwsStateError,
    );
  });
}
