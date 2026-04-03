/// Represents pre-calculated pricing grade values from the API.
/// These values are returned directly from the server and stored as-is.
class PricingGrades {
  final double? gradeDefault;
  final double? gradeA;
  final double? gradeB;
  final double? gradeC;
  final double? gradeD;

  const PricingGrades({
    this.gradeDefault,
    this.gradeA,
    this.gradeB,
    this.gradeC,
    this.gradeD,
  });

  factory PricingGrades.empty() {
    return const PricingGrades();
  }

  factory PricingGrades.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PricingGrades();
    return PricingGrades(
      gradeDefault: _asNullableDouble(json['default']),
      gradeA: _asNullableDouble(json['gradeA']),
      gradeB: _asNullableDouble(json['gradeB']),
      gradeC: _asNullableDouble(json['gradeC']),
      gradeD: _asNullableDouble(json['gradeD']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'default': gradeDefault,
      'gradeA': gradeA,
      'gradeB': gradeB,
      'gradeC': gradeC,
      'gradeD': gradeD,
    };
  }

  bool get isEmpty {
    return gradeDefault == null &&
        gradeA == null &&
        gradeB == null &&
        gradeC == null &&
        gradeD == null;
  }

  bool get isNotEmpty => !isEmpty;

  /// Returns the effective price for a given grade letter.
  /// Grade letters: 'Def', 'A', 'B', 'C', 'D'
  double? priceForGrade(String grade) {
    switch (grade) {
      case 'Def':
        return gradeDefault;
      case 'A':
        return gradeA;
      case 'B':
        return gradeB;
      case 'C':
        return gradeC;
      case 'D':
        return gradeD;
      default:
        return null;
    }
  }

  static double? _asNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
