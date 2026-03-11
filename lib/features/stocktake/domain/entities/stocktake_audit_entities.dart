import 'package:rmstock_scanner/entities/vos/audit_item_vo.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';

class AuditWithStockVO {
  final AuditItem audit;
  final StockVO? stock;

  AuditWithStockVO({required this.audit, required this.stock});
}

class AuditSyncStatus {
  final int processed;
  final int total;
  final String message;

  final List<AuditWithStockVO>? rows;

  AuditSyncStatus(this.processed, this.total, this.message, {this.rows});
}
