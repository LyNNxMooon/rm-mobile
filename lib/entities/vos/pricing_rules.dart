class PricingRules {
  final int defaultRule;
  final int ruleA;
  final int ruleB;
  final int ruleC;
  final int ruleD;
  final double defaultValue;
  final double valueA;
  final double valueB;
  final double valueC;
  final double valueD;
  final String? dateModified;

  const PricingRules({
    required this.defaultRule,
    required this.ruleA,
    required this.ruleB,
    required this.ruleC,
    required this.ruleD,
    required this.defaultValue,
    required this.valueA,
    required this.valueB,
    required this.valueC,
    required this.valueD,
    this.dateModified,
  });

  factory PricingRules.empty() {
    return const PricingRules(
      defaultRule: 0,
      ruleA: 0,
      ruleB: 0,
      ruleC: 0,
      ruleD: 0,
      defaultValue: 0,
      valueA: 0,
      valueB: 0,
      valueC: 0,
      valueD: 0,
      dateModified: null,
    );
  }

  factory PricingRules.fromJson(Map<String, dynamic> json) {
    return PricingRules(
      defaultRule: _asInt(json['DefaultRule']),
      ruleA: _asInt(json['RuleA']),
      ruleB: _asInt(json['RuleB']),
      ruleC: _asInt(json['RuleC']),
      ruleD: _asInt(json['RuleD']),
      defaultValue: _asDouble(json['DefaultValue']),
      valueA: _asDouble(json['ValueA']),
      valueB: _asDouble(json['ValueB']),
      valueC: _asDouble(json['ValueC']),
      valueD: _asDouble(json['ValueD']),
      dateModified: _asNullableString(json['date_modified']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'DefaultRule': defaultRule,
      'RuleA': ruleA,
      'RuleB': ruleB,
      'RuleC': ruleC,
      'RuleD': ruleD,
      'DefaultValue': defaultValue,
      'ValueA': valueA,
      'ValueB': valueB,
      'ValueC': valueC,
      'ValueD': valueD,
      'date_modified': dateModified,
    };
  }

  bool get isEmpty {
    return defaultRule == 0 &&
        ruleA == 0 &&
        ruleB == 0 &&
        ruleC == 0 &&
        ruleD == 0 &&
        defaultValue == 0 &&
        valueA == 0 &&
        valueB == 0 &&
        valueC == 0 &&
        valueD == 0;
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static String? _asNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
