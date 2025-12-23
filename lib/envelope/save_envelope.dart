class SaveEnvelope {
  const SaveEnvelope({
    required this.schemaVersion,
    required this.createdAtMs,
    required this.updatedAtMs,
    required this.payload,
    this.checksum,
  });

  final int schemaVersion;
  final int createdAtMs;
  final int updatedAtMs;
  final Map<String, dynamic> payload;
  final String? checksum;

  SaveEnvelope copyWith({
    int? schemaVersion,
    int? createdAtMs,
    int? updatedAtMs,
    Map<String, dynamic>? payload,
    Object? checksum = _sentinel,
  }) {
    final checksumValue =
        identical(checksum, _sentinel) ? this.checksum : checksum as String?;
    return SaveEnvelope(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      payload: payload ?? this.payload,
      checksum: checksumValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'createdAtMs': createdAtMs,
      'updatedAtMs': updatedAtMs,
      'payload': payload,
      if (checksum != null) 'checksum': checksum,
    };
  }

  static SaveEnvelope fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'];
    final createdAtMs = json['createdAtMs'];
    final updatedAtMs = json['updatedAtMs'];
    final payload = json['payload'];
    final checksum = json['checksum'];

    if (schemaVersion is! int || createdAtMs is! int || updatedAtMs is! int) {
      throw const FormatException('Invalid envelope metadata');
    }
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Invalid envelope payload');
    }
    if (checksum != null && checksum is! String) {
      throw const FormatException('Invalid envelope checksum');
    }

    return SaveEnvelope(
      schemaVersion: schemaVersion,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs,
      payload: payload,
      checksum: checksum as String?,
    );
  }
}

const _sentinel = Object();
