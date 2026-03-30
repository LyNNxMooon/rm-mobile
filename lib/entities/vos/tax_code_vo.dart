import 'package:json_annotation/json_annotation.dart';
part 'tax_code_vo.g.dart';

@JsonSerializable()
class TaxCodeVO {
  final String code;
  final String export;
  final String description;
  final double percentage;
  @JsonKey(name: 'tax_type')
  final int taxType;
  @JsonKey(name: 'sales_ac')
  final String salesAc;
  @JsonKey(name: 'goods_ac')
  final String goodsAc;
  @JsonKey(name: 'tax_id')
  final int taxId;
  @JsonKey(name: 'date_modified')
  final String dateModified;

  TaxCodeVO({
    required this.code,
    required this.export,
    required this.description,
    required this.percentage,
    required this.taxType,
    required this.salesAc,
    required this.goodsAc,
    required this.taxId,
    required this.dateModified,
  });

  factory TaxCodeVO.fromJson(Map<String, dynamic> json) =>
      _$TaxCodeVOFromJson(json);

  Map<String, dynamic> toJson() => _$TaxCodeVOToJson(this);

  /// Calculate tax amount for a given base amount
  double calculateTax(double baseAmount) {
    return baseAmount * (percentage / 100);
  }

  /// Calculate the inclusive price (base + tax)
  double calculateInclusivePrice(double baseAmount) {
    return baseAmount + calculateTax(baseAmount);
  }

  /// Extract the base amount from a tax-inclusive price
  double extractBaseFromInclusive(double inclusiveAmount) {
    return inclusiveAmount / (1 + (percentage / 100));
  }

  /// Extract tax amount from a tax-inclusive price
  double extractTaxFromInclusive(double inclusiveAmount) {
    return inclusiveAmount - extractBaseFromInclusive(inclusiveAmount);
  }

  factory TaxCodeVO.fromDbMap(Map<String, dynamic> map) {
    return TaxCodeVO(
      code: map['code'] as String,
      export: map['export_code'] as String,
      description: map['description'] as String,
      percentage: (map['percentage'] as num).toDouble(),
      taxType: map['tax_type'] as int,
      salesAc: map['sales_ac'] as String? ?? '',
      goodsAc: map['goods_ac'] as String? ?? '',
      taxId: map['tax_id'] as int,
      dateModified: map['date_modified'] as String,
    );
  }

  Map<String, dynamic> toDbMap(String shopfront) => {
        'code': code,
        'shopfront': shopfront,
        'export_code': export,
        'description': description,
        'percentage': percentage,
        'tax_type': taxType,
        'sales_ac': salesAc,
        'goods_ac': goodsAc,
        'tax_id': taxId,
        'date_modified': dateModified,
      };
}
