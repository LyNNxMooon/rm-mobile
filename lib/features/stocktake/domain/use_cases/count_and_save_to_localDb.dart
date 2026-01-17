import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import 'package:rmstock_scanner/features/stocktake/domain/repositories/stocktake_repo.dart';

import '../../../../entities/vos/counted_stock_vo.dart';
import '../../../../utils/global_var_utils.dart';

class CountAndSaveToLocaldb {
  final StocktakeRepo repository;

  CountAndSaveToLocaldb(this.repository);

  Future<void> call({required StockVO stock, required String qty}) async {
    try {
      if (stock.staticQuantity == "True") {
        return Future.error("Static/Package items cannot be counted!");
      }

      if (stock.package == "True") {
        return Future.error("Static/Package items cannot be counted!");
      }

      if (qty.isEmpty) {
        return Future.error("Enter qty to count!");
      }

      final processedStock = CountedStockVO(
        stockID: stock.stockID.toInt(),
        quantity: int.parse(qty),
        stocktakeDate: DateTime.now(),
        dateModified: DateTime.now(),
        isSynced: false,
        description: stock.description ?? "-",
        barcode: stock.barcode ?? "-",
      );

      await repository.stocktakeAndSaveToLocalDb(
        processedStock,
        AppGlobals.instance.shopfront ?? "",
      );
    } catch (error) {
      return Future.error(error);
    }
  }
}
