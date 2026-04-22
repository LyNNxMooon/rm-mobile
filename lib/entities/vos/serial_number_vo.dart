class SerialNumberVO {
  final int? serialAuditId;
  final String number;
  final String warrantyDate;
  final int? ageInDays;

  const SerialNumberVO({
    this.serialAuditId,
    this.number = '',
    this.warrantyDate = '',
    this.ageInDays,
  });

  bool get hasNumber => number.trim().isNotEmpty;

  SerialNumberVO copyWith({
    int? serialAuditId,
    String? number,
    String? warrantyDate,
    int? ageInDays,
  }) {
    return SerialNumberVO(
      serialAuditId: serialAuditId ?? this.serialAuditId,
      number: number ?? this.number,
      warrantyDate: warrantyDate ?? this.warrantyDate,
      ageInDays: ageInDays ?? this.ageInDays,
    );
  }

  factory SerialNumberVO.fromJson(Map<String, dynamic> json) {
    return SerialNumberVO(
      serialAuditId: _asNullableInt(json['serialaudit_id']),
      number: _asString(json['number']),
      warrantyDate: _asString(json['warranty_date']),
      ageInDays: _asNullableInt(json['age']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serialaudit_id': serialAuditId,
      'number': number,
      'warranty_date': warrantyDate,
      'age': ageInDays,
    };
  }

  Map<String, dynamic> toApiPayload() {
    return {
      'serialaudit_id': serialAuditId,
      'number': number,
      'warranty_date': warrantyDate,
    };
  }

  static int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static String _asString(dynamic value) {
    return value == null ? '' : value.toString();
  }
}
