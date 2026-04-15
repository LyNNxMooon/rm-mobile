import 'package:rmmobile/entities/vos/counted_stock_vo.dart';
import 'package:rmmobile/local_db/local_db_dao.dart';
import 'package:rmmobile/utils/global_var_utils.dart';

class FetchStocktakeHistoryItems {
  Future<List<CountedStockVO>> call({required String sessionId}) async {
    final shopfront = AppGlobals.instance.shopfront ?? "";
    final raw = await LocalDbDAO.instance.getStocktakeHistoryItems(
      sessionId: sessionId,
      shopfront: shopfront,
    );
    return raw.map((e) => CountedStockVO.countedFromHistoryMap(e)).toList();
  }
}
