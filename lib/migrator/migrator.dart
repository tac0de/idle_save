/// Function that transforms a payload into the next schema version.
typedef MigrationFn = Map<String, dynamic> Function(
    Map<String, dynamic> payload);

/// Single schema migration from [from] to [to].
class Migration {
  /// Creates a migration definition.
  const Migration({
    required this.from,
    required this.to,
    required this.migrate,
  });

  /// Source schema version.
  final int from;

  /// Target schema version.
  final int to;

  /// Migration callback for transforming payloads.
  final MigrationFn migrate;
}

/// Result of applying a migration chain.
class MigrationResult {
  /// Creates a migration result.
  const MigrationResult({
    required this.version,
    required this.payload,
  });

  /// Final schema version after migrations.
  final int version;

  /// Migrated payload.
  final Map<String, dynamic> payload;
}

/// Applies ordered migrations and validates continuity.
class Migrator {
  /// Creates a migrator for [latestVersion] and [migrations].
  Migrator({
    required this.latestVersion,
    List<Migration> migrations = const [],
  }) : _migrations = List<Migration>.unmodifiable(migrations) {
    _validateChain();
  }

  /// Latest schema version supported by this migrator.
  final int latestVersion;
  final List<Migration> _migrations;

  /// Ordered list of migrations.
  List<Migration> get migrations => _migrations;

  void _validateChain() {
    if (_migrations.isEmpty) {
      return;
    }

    final sorted = _migrations.toList()
      ..sort((a, b) => a.from.compareTo(b.from));

    for (var i = 0; i < sorted.length; i++) {
      final migration = sorted[i];
      if (migration.to != migration.from + 1) {
        throw StateError(
            'Migration ${migration.from} -> ${migration.to} is not contiguous.');
      }
      if (i > 0 && migration.from != sorted[i - 1].to) {
        throw StateError('Migration chain has a gap at ${migration.from}.');
      }
    }

    final last = sorted.last;
    if (last.to != latestVersion) {
      throw StateError(
          'Latest version $latestVersion does not match last migration ${last.to}.');
    }
  }

  /// Migrates [payload] from [fromVersion] to [latestVersion].
  MigrationResult migrate({
    required int fromVersion,
    required Map<String, dynamic> payload,
  }) {
    if (fromVersion > latestVersion) {
      throw StateError(
          'Save schema $fromVersion is newer than latest $latestVersion.');
    }
    if (fromVersion == latestVersion) {
      return MigrationResult(version: fromVersion, payload: payload);
    }

    final migrationsByFrom = {
      for (final migration in _migrations) migration.from: migration,
    };

    var currentVersion = fromVersion;
    var currentPayload = Map<String, dynamic>.from(payload);

    while (currentVersion < latestVersion) {
      final migration = migrationsByFrom[currentVersion];
      if (migration == null) {
        throw StateError('Missing migration from $currentVersion.');
      }
      final nextPayload =
          migration.migrate(Map<String, dynamic>.from(currentPayload));
      currentPayload = Map<String, dynamic>.from(nextPayload);
      currentVersion = migration.to;
    }

    return MigrationResult(version: currentVersion, payload: currentPayload);
  }
}
