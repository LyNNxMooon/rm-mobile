import 'package:path/path.dart';
import 'package:rmstock_scanner/entities/response/paginated_stock_response.dart';
import 'package:rmstock_scanner/entities/vos/counted_stock_vo.dart';
import 'package:rmstock_scanner/entities/vos/stock_vo.dart';
import 'package:rmstock_scanner/local_db/local_db_dao.dart';
import 'package:rmstock_scanner/local_db/sqlite/sqlite_constants.dart';
import 'package:sqflite/sqflite.dart';
import '../../entities/vos/filter_criteria.dart';
import '../../utils/log_utils.dart';

class SQLiteDAOImpl extends LocalDbDAO {
  Database? _database;

  @override
  Future<void> initDB() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, dbName);

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute(stocktakeTableCreationQuery);
          await db.execute(appConfigTableCreationQuery);
          await db.execute(networkCredentialsTableCreationQuery);
          await db.execute(savedPathsTableCreationQuery);
          await db.execute(stocksTableCreationQuery);
        },
      );
      logger.d('Successfully initialized SQLite local database!');
    } catch (error) {
      logger.e('Error initializing for SQLite local database: $error');
    }
  }

  //Get Data
  @override
  Future<Map<String, dynamic>?> getNetworkCredential({
    required String ip,
  }) async {
    try {
      final db = _database!;
      final result = await db.query(
        'NetworkCredentials',
        where: 'ip_address = ?',
        whereArgs: [ip],
      );

      if (result.isNotEmpty) {
        return result.first;
      }
      return null;
    } catch (error) {
      logger.e('Error getting network cred from local db: $error');
      return Future.error("Error getting network cred from local db: $error");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllNetworkPaths() async {
    try {
      final db = _database!;
      final List<Map<String, dynamic>> result = await db.query(
        'SavedNetworkPaths',
        orderBy: 'added_at DESC',
      );

      return result;
    } catch (error) {
      logger.e('Error getting paths from local db: $error');
      return Future.error("Error getting paths from local db: $error");
    }
  }

  @override
  Future<Map<String, dynamic>?> getSingleNetworkPath(String targetPath) async {
    try {
      final db = _database!;

      final List<Map<String, dynamic>> result = await db.query(
        'SavedNetworkPaths',
        where: 'path = ?',
        whereArgs: [targetPath],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return result.first;
      }

      return null;
    } catch (error) {
      logger.e('Error getting single path from local db: $error');
      return Future.error("Error retrieving path data: $error");
    }
  }

  @override
  Future<Map<String, dynamic>?> getSinglePathByIp(String ipAddress) async {
    try {
      final db = _database!;

      // We use LIKE '//ipAddress%' to match the start of the path string
      // Example: //192.168.1.10%
      final List<Map<String, dynamic>> result = await db.query(
        'SavedNetworkPaths',
        where: 'path LIKE ?',
        whereArgs: ['//$ipAddress%'],
        limit: 1, // Ensure we only get the primary connection for this IP
      );

      if (result.isNotEmpty) {
        return result.first;
      }

      return null;
    } catch (error) {
      logger.e('Error getting path by IP from local db: $error');
      return Future.error("Error retrieving path data by IP: $error");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStocktakeList({
    required String shopfront,
  }) async {
    try {
      final db = _database!;

      return await db.query(
        'Stocktake',
        where: 'shopfront = ? AND is_synced = ?',
        whereArgs: [shopfront, 0],
        orderBy: 'date_modified DESC',
      );
    } catch (error) {
      logger.e('Error retrieving stocktake list from local db: $error');
      return Future.error("Error retrieving stocktake list: $error");
    }
  }

  @override
  Future<List<CountedStockVO>> getUnsyncedStocks(String shopfront) async {
    try {
      final db = _database!;
      final List<Map<String, dynamic>> result = await db.query(
        'Stocktake',
        where: 'shopfront = ? AND is_synced = ?',
        whereArgs: [shopfront, 0],
        orderBy: 'stocktake_date ASC',
      );

      return result.map((map) {
        final Map<String, dynamic> mutableMap = Map<String, dynamic>.from(map);
        mutableMap['is_synced'] = mutableMap['is_synced'] == 1;
        return CountedStockVO.fromJson(mutableMap);
      }).toList();
    } catch (error) {
      logger.e('Error getting unsynced stocktake list from local db: $error');
      return Future.error("Error retrieving unsynced stocktake list: $error");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSyncedStocks(String shopfront) async {
    try {
      final db = _database!;

      return await db.query(
        'Stocktake',
        where: 'shopfront = ? AND is_synced = ?',
        whereArgs: [shopfront, 1],
        orderBy: 'date_modified DESC',
      );
    } catch (error) {
      logger.e('Error retrieving stocktake list from local db: $error');
      return Future.error("Error retrieving stocktake list: $error");
    }
  }

  @override
  Future<StockVO?> getStockBySearch(String query, String shopfront) async {
    try {
      final db = _database!;
      final result = await db.query(
        'Stocks',
        where: '(Barcode = ? OR stock_id = ?) AND shopfront = ?',
        whereArgs: [query, query, shopfront],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return StockVO.fromJson(result.first);
      }
      return null;
    } catch (error) {
      logger.e('Error searching stock in $shopfront: $error');
      return Future.error("Error searching stock: $error");
    }
  }

  @override
  Future<PaginatedStockResult> searchAndSortStocks({
    required String shopfront,
    required String query,
    required String filterColumn,
    required String sortColumn,
    required bool ascending,
    required int limit,
    required int offset,
    FilterCriteria? filters,
  }) async {
    try {
      final db = _database!;
      String orderBy = "$sortColumn ${ascending ? 'ASC' : 'DESC'}";

      // Base where clause
      String whereClause = 'shopfront = ?';
      List<dynamic> args = [shopfront];

      // Add Search logic if query exists
      if (query.isNotEmpty) {
        // Use LIKE for partial matches
        whereClause += ' AND $filterColumn LIKE ?';
        args.add('%$query%');
      }

      //ADD FILTER LOGIC (New)
      if (filters != null) {
        if (filters.dept != null) {
          whereClause += ' AND dept_name = ?';
          args.add(filters.dept);
        }
        if (filters.cat1 != null) {
          whereClause += ' AND cat1 = ?';
          args.add(filters.cat1);
        }
        if (filters.cat2 != null) {
          whereClause += ' AND cat2 = ?';
          args.add(filters.cat2);
        }
        if (filters.cat3 != null) {
          whereClause += ' AND cat3 = ?';
          args.add(filters.cat3);
        }
        // Text fields use LIKE for partial matching
        if (filters.supplier != null && filters.supplier!.isNotEmpty) {
          whereClause += ' AND supplier LIKE ?';
          args.add('%${filters.supplier}%');
        }
        if (filters.custom1 != null && filters.custom1!.isNotEmpty) {
          whereClause += ' AND custom1 LIKE ?';
          args.add('%${filters.custom1}%');
        }
        if (filters.custom2 != null && filters.custom2!.isNotEmpty) {
          whereClause += ' AND custom2 LIKE ?';
          args.add('%${filters.custom2}%');
        }
      }

      //Get filtered count (Parallel query for performance)
      final countFuture = db.rawQuery(
        'SELECT COUNT(*) as count FROM Stocks WHERE $whereClause',
        args,
      );

      //Get paginated data
      final dataFuture = db.query(
        'Stocks',
        where: whereClause,
        whereArgs: args,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );

      final results = await Future.wait([dataFuture, countFuture]);

      final List<StockVO> items = (results[0] as List<Map<String, dynamic>>)
          .map((e) => StockVO.fromJson(e))
          .toList();

      final int count =
          Sqflite.firstIntValue(results[1] as List<Map<String, dynamic>>) ?? 0;

      return PaginatedStockResult(items, count);
    } catch (error) {
      logger.e('Error searching stocks: $error');
      return Future.error(error);
    }
  }

  @override
  Future<List<String>> getDistinctValues(String columnName) async {
    try {
      final db = _database!;

      final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT DISTINCT $columnName 
      FROM Stocks 
      WHERE $columnName IS NOT NULL AND $columnName != '' 
      ORDER BY $columnName ASC
    ''');

      return result.map((row) => row[columnName] as String).toList();
    } catch (error) {
      logger.e('Error fetching distinct $columnName: $error');
      return [];
    }
  }

  @override
  Future<String?> getAppConfig(String key, {String? shopfront}) async {
    final db = _database!;
    final String effectiveKey = shopfront != null ? "${key}_$shopfront" : key;

    final List<Map<String, dynamic>> maps = await db.query(
      'AppConfig',
      where: 'key = ?',
      whereArgs: [effectiveKey],
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }

  //Save Data

  @override
  Future<void> saveAppConfig(
    String key,
    String value, {
    String? shopfront,
  }) async {
    final db = _database!;
    final String effectiveKey = shopfront != null ? "${key}_$shopfront" : key;
    await db.insert('AppConfig', {
      'key': effectiveKey,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> saveCountedStock(Map<String, dynamic> stockData) async {
    try {
      final db = _database!;

      await db.insert(
        'Stocktake',
        stockData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (error) {
      logger.e('Error saving counted stock to local db: $error');
      return Future.error("Error saving counted stock to local db: $error");
    }
  }

  @override
  Future<void> saveNetworkCredential({
    required String ip,
    required String username,
    required String password,
  }) async {
    try {
      final db = _database!;
      await db.insert('NetworkCredentials', {
        'ip_address': ip,
        'is_auth_required': 1,
        'username': username,
        'password': password,
      });
    } catch (error) {
      logger.e('Error saving network cred to local db: $error');
      return Future.error("Error saving network cred to local db: $error");
    }
  }

  @override
  Future<void> addNetworkPath(
    String path,
    String shopfront,
    String hostName,
  ) async {
    try {
      final db = _database!;
      await db.insert('SavedNetworkPaths', {
        'path': path,
        'added_at': DateTime.now().millisecondsSinceEpoch,
        'shopfront': shopfront,
        'host_name': hostName,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } catch (error) {
      logger.e('Error saving paths to local db: $error');
      return Future.error("Error saving paths to local db: $error");
    }
  }

  @override
  Future<void> insertStocks(List<StockVO> stocks, String shopfront) async {
    try {
      final db = _database!;
      final batch = db.batch();

      for (var stock in stocks) {
        batch.insert(
          'Stocks',
          stock.toJson(shopfront),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      logger.d('Successfully saved ${stocks.length} records for $shopfront');
    } catch (error) {
      logger.e('Error saving stocks for $shopfront: $error');
      return Future.error("Error saving master stocks: $error");
    }
  }

  //Removing Data
  @override
  Future<void> removeNetworkCredential({required String ip}) async {
    try {
      final db = _database!;
      await db.delete(
        'NetworkCredentials',
        where: 'ip_address = ?',
        whereArgs: [ip],
      );
    } catch (error) {
      logger.e('Error removing network cred from local db: $error');
      return Future.error("Error removing network cred from local db: $error");
    }
  }

  @override
  Future<void> deleteNetworkPath(String path) async {
    try {
      final db = _database!;
      await db.delete(
        'SavedNetworkPaths',
        where: 'path = ?',
        whereArgs: [path],
      );
    } catch (error) {
      logger.e('Error removing paths from local db: $error');
      return Future.error("Error removing paths from local db: $error");
    }
  }

  @override
  Future<void> deleteStocktake(int stockID, String shopfront) async {
    try {
      final db = _database!;
      await db.delete(
        'Stocktake',
        where: 'stock_id = ? AND shopfront = ?',
        whereArgs: [stockID, shopfront],
      );

      logger.d('Removed stock $stockID from $shopfront');
    } catch (error) {
      logger.e('Error removing stocktake from local db: $error');
      return Future.error("Error removing stocktake from local db: $error");
    }
  }

  @override
  Future<void> deleteAllStocktake() async {
    try {
      final db = _database!;

      await db.delete('Stocktake');

      logger.d('Successfully cleared all records from Stocktake table');
    } catch (error) {
      logger.e('Error clearing Stocktake table: $error');
      return Future.error("Error clearing all stocktake records: $error");
    }
  }

  @override
  Future<void> clearStocksForShop(String shopfront) async {
    try {
      final db = _database!;
      await db.delete('Stocks', where: 'shopfront = ?', whereArgs: [shopfront]);
      logger.d('Cleared master Stocks for $shopfront');
    } catch (error) {
      logger.e('Error clearing stocks for $shopfront: $error');
    }
  }

  //Update Data
  @override
  Future<void> updateShopfrontByIp({
    required String ip,
    required String selectedShopfront,
  }) async {
    try {
      final db = _database!;
      await db.update(
        'SavedNetworkPaths',
        {'shopfront': selectedShopfront},
        where: 'path LIKE ?',
        whereArgs: ['//$ip%'],
      );

      logger.d(
        'Successfully updated shopfront for IP: $ip to $selectedShopfront',
      );
    } catch (error) {
      logger.e('Error updating shopfront in local db: $error');
      return Future.error("Error updating shopfront: $error");
    }
  }

  @override
  Future<void> updatePathByIp({
    required String ip,
    required String selectedPath,
  }) async {
    try {
      final db = _database!;
      await db.update(
        'SavedNetworkPaths',
        {'path': selectedPath},
        where: 'path LIKE ?',
        whereArgs: ['//$ip%'],
      );

      logger.d('Successfully updated path for IP: $ip to $selectedPath');
    } catch (error) {
      logger.e('Error updating path in local db: $error');
      return Future.error("Error updating path: $error");
    }
  }

  @override
  Future<void> markStockAsSynced(List<int> stockIds, String shopfront) async {
    try {
      final db = _database!;
      final batch = db.batch();

      for (final id in stockIds) {
        // Use delete instead of update to remove the records
        batch.delete(
          'Stocktake',
          where: 'stock_id = ? AND shopfront = ?',
          whereArgs: [id, shopfront],
        );
      }

      await batch.commit(noResult: true);

      logger.d('Successfully deleted committed stocktake records');
    } catch (error) {
      logger.e('Error deleting stocktake list in local db: $error');
      return Future.error("Error deleting stocktake records: $error");
    }
  }
}
