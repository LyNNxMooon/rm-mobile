import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import 'package:rmstock_scanner/features/stocktake/domain/repositories/stocktake_repo.dart';

import '../../../../entities/vos/counted_stock_vo.dart';
import '../../../../utils/global_var_utils.dart';

class CountAndSaveToLocaldb {
  final StocktakeRepo repository;

  CountAndSaveToLocaldb(this.repository);

  Future<void> call({required StockVO stock, required String qty}) async {
    try {
      if (stock.staticQuantity) {
        return Future.error("Static/Package items cannot be counted!");
      }

      if (stock.package) {
        return Future.error("Static/Package items cannot be counted!");
      }

      if (qty.isEmpty) {
        return Future.error("Enter qty to count!");
      }

      //Determine the numeric value based on fractional support
      num parsedQty;
      if (stock.allowFractions == true) {
        // If fractional is allowed, parse directly to double
        parsedQty = double.tryParse(qty) ?? 0.0;
      } else {
        // If not allowed, parse input and round to nearest integer
        // We parse as double first in case the user typed a dot by accident
        double inputAsDouble = double.tryParse(qty) ?? 0.0;
        parsedQty = inputAsDouble.round();
      }

      final processedStock = CountedStockVO(
        stockID: stock.stockID.toInt(),
        quantity: parsedQty.toDouble(),
        stocktakeDate: DateTime.now(),
        dateModified: DateTime.now(),
        isSynced: false,
        description: stock.description,
        barcode: stock.barcode,
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
