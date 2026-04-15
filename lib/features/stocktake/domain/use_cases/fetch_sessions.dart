import 'package:rmmobile/entities/vos/stocktake_history_session_row.dart';
import 'package:rmmobile/local_db/local_db_dao.dart';
import 'package:rmmobile/utils/global_var_utils.dart';

class FetchStocktakeHistorySessions {
  Future<List<StocktakeHistorySessionRow>> call() async {
    final shopfront = AppGlobals.instance.shopfront ?? "";
    final raw = await LocalDbDAO.instance.getStocktakeHistorySessions(
      shopfront: shopfront,
    );
    return raw.map((e) => StocktakeHistorySessionRow.fromMap(e)).toList();
  }
}
