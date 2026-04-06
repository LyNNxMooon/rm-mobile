class PromotionVO {
  final int? promotionId;
  final String? name;
  final String? startDate;
  final String? endDate;
  final int? pricingType;
  final double? pricingValue;
  final double? promotionRrp;
  final double? originalSellInc;

  PromotionVO({
    this.promotionId,
    this.name,
    this.startDate,
    this.endDate,
    this.pricingType,
    this.pricingValue,
    this.promotionRrp,
    this.originalSellInc,
  });

  factory PromotionVO.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    return PromotionVO(
      promotionId: toInt(json['promotion_id']),
      name: json['name']?.toString(),
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      pricingType: toInt(json['pricing_type']),
      pricingValue: toDouble(json['pricing_value']),
      promotionRrp: toDouble(json['promotion_rrp']),
      originalSellInc: toDouble(json['original_sell_inc']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'promotion_id': promotionId,
      'name': name,
      'start_date': startDate,
      'end_date': endDate,
      'pricing_type': pricingType,
      'pricing_value': pricingValue,
      'promotion_rrp': promotionRrp,
      'original_sell_inc': originalSellInc,
    };
  }
}
