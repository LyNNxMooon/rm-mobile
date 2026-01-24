import 'package:json_annotation/json_annotation.dart';
part 'audit_item_vo.g.dart';

@JsonSerializable()
class AuditItem {
  @JsonKey(name: 'audit_date')
  final String auditDate; // keep raw string from server
  @JsonKey(name: 'tran_type')
  final String tranType;
  @JsonKey(name: 'source_id')
  final int sourceId;
  @JsonKey(name: 'stock_id')
  final num stockId;
  final double movement;

  AuditItem({
    required this.auditDate,
    required this.tranType,
    required this.sourceId,
    required this.stockId,
    required this.movement,
  });

    factory AuditItem.fromJson(Map<String, dynamic> json) =>
      _$AuditItemFromJson(json);
}
