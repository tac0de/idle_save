import 'save_change_set.dart';

/// Wrapper around a JSON-safe payload with schema metadata.
class SaveEnvelope {
  /// Creates a save envelope with schema/timestamp metadata.
  const SaveEnvelope({
    required this.schemaVersion,
    required this.createdAtMs,
    required this.updatedAtMs,
    required this.payload,
    this.changeSet,
    this.saveReason,
    this.checksum,
  });

  /// Schema version of the payload.
  final int schemaVersion;

  /// Creation timestamp in milliseconds since epoch.
  final int createdAtMs;

  /// Last update timestamp in milliseconds since epoch.
  final int updatedAtMs;

  /// JSON-safe payload.
  final Map<String, dynamic> payload;

  /// Optional change set describing what changed.
  final SaveChangeSet? changeSet;

  /// Optional reason describing why the save was written.
  final String? saveReason;

  /// Optional checksum over the payload.
  final String? checksum;

  /// Returns a copy with selected fields replaced.
  SaveEnvelope copyWith({
    int? schemaVersion,
    int? createdAtMs,
    int? updatedAtMs,
    Map<String, dynamic>? payload,
    Object? changeSet = _sentinel,
    Object? saveReason = _sentinel,
    Object? checksum = _sentinel,
  }) {
    final changeSetValue = identical(changeSet, _sentinel)
        ? this.changeSet
        : changeSet as SaveChangeSet?;
    final saveReasonValue = identical(saveReason, _sentinel)
        ? this.saveReason
        : saveReason as String?;
    final checksumValue =
        identical(checksum, _sentinel) ? this.checksum : checksum as String?;
    return SaveEnvelope(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      payload: payload ?? this.payload,
      changeSet: changeSetValue,
      saveReason: saveReasonValue,
      checksum: checksumValue,
    );
  }

  /// Serializes the envelope to a JSON-safe map.
  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'createdAtMs': createdAtMs,
      'updatedAtMs': updatedAtMs,
      'payload': payload,
      if (changeSet != null) 'changeSet': changeSet!.toJson(),
      if (saveReason != null) 'saveReason': saveReason,
      if (checksum != null) 'checksum': checksum,
    };
  }

  /// Parses an envelope from a JSON-safe map.
  static SaveEnvelope fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'];
    final createdAtMs = json['createdAtMs'];
    final updatedAtMs = json['updatedAtMs'];
    final payload = json['payload'];
    final changeSet = json['changeSet'];
    final saveReason = json['saveReason'];
    final checksum = json['checksum'];

    if (schemaVersion is! int || createdAtMs is! int || updatedAtMs is! int) {
      throw const FormatException('Invalid envelope metadata');
    }
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Invalid envelope payload');
    }
    SaveChangeSet? parsedChangeSet;
    if (changeSet != null) {
      if (changeSet is! Map<String, dynamic>) {
        throw const FormatException('Invalid envelope change set');
      }
      parsedChangeSet = SaveChangeSet.fromJson(changeSet);
    }
    if (saveReason != null && saveReason is! String) {
      throw const FormatException('Invalid envelope save reason');
    }
    if (checksum != null && checksum is! String) {
      throw const FormatException('Invalid envelope checksum');
    }

    return SaveEnvelope(
      schemaVersion: schemaVersion,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs,
      payload: payload,
      changeSet: parsedChangeSet,
      saveReason: saveReason as String?,
      checksum: checksum as String?,
    );
  }
}

const _sentinel = Object();
