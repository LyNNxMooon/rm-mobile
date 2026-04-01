import 'package:json_annotation/json_annotation.dart';

part 'package_component.g.dart';

@JsonSerializable()
class PackageComponent {
  @JsonKey(name: 'stock_id')
  final int stockId;
  final double quantity;
  final String? description;
  final String? barcode;
  @JsonKey(name: 'sell_inc')
  final double? sellInc;

  PackageComponent({
    required this.stockId,
    required this.quantity,
    this.description,
    this.barcode,
    this.sellInc,
  });

  factory PackageComponent.fromJson(Map<String, dynamic> json) =>
      _$PackageComponentFromJson(json);

  Map<String, dynamic> toJson() => _$PackageComponentToJson(this);
}
