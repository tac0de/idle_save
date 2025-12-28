/// Records what changed in a save boundary.
class SaveChangeSet {
  /// Creates a change set with optional details.
  SaveChangeSet({
    this.added = const [],
    this.updated = const [],
    this.removed = const [],
    this.note,
  }) {
    final hasNote = note != null && note!.isNotEmpty;
    if (added.isEmpty && updated.isEmpty && removed.isEmpty && !hasNote) {
      throw ArgumentError(
        'ChangeSet must not be empty. '
        'Use SaveChangeSet.none() or provide a note.',
      );
    }
  }

  /// Explicitly indicates no meaningful changes.
  factory SaveChangeSet.none() => SaveChangeSet(note: 'none');

  /// Indicates the change set is unknown but explicit.
  factory SaveChangeSet.unknown({String? note}) {
    return SaveChangeSet(note: note ?? 'unknown');
  }

  /// Marks a migration-driven change set.
  factory SaveChangeSet.migration() => SaveChangeSet(note: 'migration');

  /// Marks a recovery-driven change set.
  factory SaveChangeSet.recovery() => SaveChangeSet(note: 'recovery');

  /// Added keys in this save.
  final List<String> added;

  /// Updated keys in this save.
  final List<String> updated;

  /// Removed keys in this save.
  final List<String> removed;

  /// Optional free-form note about the change set.
  final String? note;

  /// Serializes the change set to a JSON-safe map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'added': List<String>.unmodifiable(added),
      'updated': List<String>.unmodifiable(updated),
      'removed': List<String>.unmodifiable(removed),
      if (note != null) 'note': note,
    };
  }

  /// Parses a change set from a JSON-safe map.
  factory SaveChangeSet.fromJson(Map<String, dynamic> json) {
    final added = json['added'];
    final updated = json['updated'];
    final removed = json['removed'];
    final note = json['note'];

    final addedList = _stringList(added, 'added');
    final updatedList = _stringList(updated, 'updated');
    final removedList = _stringList(removed, 'removed');

    if (note != null && note is! String) {
      throw const FormatException('Invalid change set note');
    }

    return SaveChangeSet(
      added: addedList,
      updated: updatedList,
      removed: removedList,
      note: note as String?,
    );
  }
}

List<String> _stringList(Object? value, String field) {
  if (value == null) {
    return const <String>[];
  }
  if (value is! List) {
    throw FormatException('Invalid change set $field');
  }
  final strings = <String>[];
  for (final item in value) {
    if (item is! String) {
      throw FormatException('Invalid change set $field');
    }
    strings.add(item);
  }
  return List<String>.unmodifiable(strings);
}
