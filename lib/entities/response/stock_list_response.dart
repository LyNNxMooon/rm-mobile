import 'package:json_annotation/json_annotation.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
part 'stock_list_response.g.dart';

@JsonSerializable()
class StockListResponse {
  final int totalItems;
  final List<StockVO> data;

  StockListResponse({required this.totalItems, required this.data});

  factory StockListResponse.fromJson(Map<String, dynamic> json) =>
      _$StockListResponseFromJson(json);
}
