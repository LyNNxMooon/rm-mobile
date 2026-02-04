import 'package:path/path.dart';
import 'package:rmstock_scanner/entities/response/paginated_stock_response.dart';
import 'package:rmstock_scanner/entities/response/stock_search_resposne.dart';
import 'package:rmstock_scanner/entities/vos/backup_stocktake_item_vo.dart';
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
          await db.execute(stocktakeHistorySessionCreationQuery);
          await db.execute(stocktakeHistoryItemsCreationQuery);
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
  Future<StockSearchResult> getStockBySearch(
    String query,
    String shopfront,
  ) async {
    try {
      final db = _database!;

      // 1) Barcode exact match (ALL matches)
      final barcodeRows = await db.query(
        'Stocks',
        where: 'Barcode = ? AND shopfront = ?',
        whereArgs: [query, shopfront],
      );

      if (barcodeRows.isNotEmpty) {
        final matches = barcodeRows.map((e) => StockVO.fromJson(e)).toList();

        if (matches.length == 1) {
          return StockSearchResult.found(matches.first);
        }

        // Duplicate barcode case
        return StockSearchResult.duplicates(matches);
      }

      // 2) Fallback to description LIKE
      final descriptionRows = await db.query(
        'Stocks',
        where: 'description LIKE ? AND shopfront = ?',
        whereArgs: ['%$query%', shopfront],
        limit: 1,
      );

      if (descriptionRows.isNotEmpty) {
        return StockSearchResult.found(StockVO.fromJson(descriptionRows.first));
      }

      return StockSearchResult.none();
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
    final String q = query.trim();

    const allowedColumns = <String>{
      'stock_id',
      'shopfront',
      'Barcode',
      'description',
      'dept_name',
      'dept_id',
      'custom1',
      'custom2',
      'cat1',
      'cat2',
      'cat3',
      'supplier',
      'quantity',
      'picture_file_name',
      'date_modified',
      'cost',
      'sell',
    };

    final String safeSortColumn =
        allowedColumns.contains(sortColumn) ? sortColumn : 'description';

    final String orderBy = "$safeSortColumn ${ascending ? 'ASC' : 'DESC'}";

    String baseWhere = 'shopfront = ?';
    final List<dynamic> baseArgs = [shopfront];

    if (filters != null) {
      if (filters.dept != null) {
        baseWhere += ' AND dept_name = ?';
        baseArgs.add(filters.dept);
      }
      if (filters.cat1 != null) {
        baseWhere += ' AND cat1 = ?';
        baseArgs.add(filters.cat1);
      }
      if (filters.cat2 != null) {
        baseWhere += ' AND cat2 = ?';
        baseArgs.add(filters.cat2);
      }
      if (filters.cat3 != null) {
        baseWhere += ' AND cat3 = ?';
        baseArgs.add(filters.cat3);
      }
      if (filters.supplier != null && filters.supplier!.isNotEmpty) {
        baseWhere += ' AND supplier LIKE ?';
        baseArgs.add('%${filters.supplier!}%');
      }
      if (filters.custom1 != null && filters.custom1!.isNotEmpty) {
        baseWhere += ' AND custom1 LIKE ?';
        baseArgs.add('%${filters.custom1!}%');
      }
      if (filters.custom2 != null && filters.custom2!.isNotEmpty) {
        baseWhere += ' AND custom2 LIKE ?';
        baseArgs.add('%${filters.custom2!}%');
      }
    }

    Future<PaginatedStockResult> runQuery({
      required String whereClause,
      required List<dynamic> args,
    }) async {
      final countFuture = db.rawQuery(
        'SELECT COUNT(*) as count FROM Stocks WHERE $whereClause',
        args,
      );

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
    }

    // Fast existence check
    Future<bool> exists(String whereClause, List<dynamic> args) async {
      final res = await db.rawQuery(
        'SELECT 1 FROM Stocks WHERE $whereClause LIMIT 1',
        args,
      );
      return res.isNotEmpty;
    }

    if (q.isEmpty) {
      return runQuery(whereClause: baseWhere, args: baseArgs);
    }

    final bool isBarcodeChip = filterColumn == 'Barcode';
    final bool isDescChip = filterColumn == 'description';

    // Barcode chip: Barcode -> Description
    if (isBarcodeChip) {
      final barcodeWhere = '$baseWhere AND Barcode LIKE ?';
      final barcodeArgs = [...baseArgs, '%$q%'];

      if (await exists(barcodeWhere, barcodeArgs)) {
        return runQuery(whereClause: barcodeWhere, args: barcodeArgs);
      }

      final descWhere = '$baseWhere AND description LIKE ?';
      final descArgs = [...baseArgs, '%$q%'];
      return runQuery(whereClause: descWhere, args: descArgs);
    }

    // Description chip: Description -> Barcode
    if (isDescChip) {
      final descWhere = '$baseWhere AND description LIKE ?';
      final descArgs = [...baseArgs, '%$q%'];

      if (await exists(descWhere, descArgs)) {
        return runQuery(whereClause: descWhere, args: descArgs);
      }

      final barcodeWhere = '$baseWhere AND Barcode LIKE ?';
      final barcodeArgs = [...baseArgs, '%$q%'];
      return runQuery(whereClause: barcodeWhere, args: barcodeArgs);
    }

    // Other chips stay the same as before
    if (!allowedColumns.contains(filterColumn)) {
      final safeWhere = '$baseWhere AND description LIKE ?';
      final safeArgs = [...baseArgs, '%$q%'];
      return runQuery(whereClause: safeWhere, args: safeArgs);
    }

    final whereClause = '$baseWhere AND $filterColumn LIKE ?';
    final args = [...baseArgs, '%$q%'];
    return runQuery(whereClause: whereClause, args: args);
  } catch (error) {
    logger.e('Error searching stocks: $error');
    return Future.error(error);
  }
}


  @override
  Future<List<String>> getDistinctValues(
    String columnName,
    String shopfront,
  ) async {
    try {
      final db = _database!;

      final List<Map<String, dynamic>> result = await db.rawQuery(
        '''
      SELECT DISTINCT $columnName 
      FROM Stocks 
      WHERE shopfront = ? 
        AND $columnName IS NOT NULL 
        AND $columnName != '' 
      ORDER BY $columnName ASC
    ''',
        [shopfront],
      );

      return result.map((row) => row[columnName] as String).toList();
    } catch (error) {
      logger.e('Error fetching distinct $columnName for $shopfront: $error');
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

  @override
  Future<Map<num, StockVO>> getStocksByIds({
    required String shopfront,
    required List<num> stockIds,
  }) async {
    try {
      final db = _database!;
      final Map<num, StockVO> out = {};

      if (stockIds.isEmpty) return out;

      final ids = stockIds.where((e) => e > 0).toSet().toList();
      if (ids.isEmpty) return out;

      const int batchSize = 900;

      for (int i = 0; i < ids.length; i += batchSize) {
        final chunk = ids.skip(i).take(batchSize).toList();
        final placeholders = List.filled(chunk.length, '?').join(',');

        final rows = await db.query(
          'Stocks',
          where: 'shopfront = ? AND stock_id IN ($placeholders)',
          whereArgs: [shopfront, ...chunk],
        );

        for (final row in rows) {
          final stock = StockVO.fromJson(row);
          out[stock.stockID] = stock;
        }
      }

      return out;
    } catch (error) {
      logger.e('Error loading stocks by ids in $shopfront: $error');
      return Future.error("Error loading stocks by ids: $error");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStocktakeHistoryItems({
    required String sessionId,
    required String shopfront,
  }) async {
    try {
      final db = _database!;
      return await db.query(
        'StocktakeHistoryItems',
        where: 'session_id = ? AND shopfront = ?',
        whereArgs: [sessionId, shopfront],
        orderBy: 'date_modified DESC',
      );
    } catch (e) {
      return Future.error("Error loading history items: $e");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStocktakeHistorySessions({
    required String shopfront,
  }) async {
    try {
      final db = _database!;
      return await db.query(
        'StocktakeHistorySession',
        where: 'shopfront = ?',
        whereArgs: [shopfront],
        orderBy: 'created_at DESC',
      );
    } catch (e) {
      return Future.error("Error loading history sessions: $e");
    }
  }

  @override
  Future<int> getHistoryRetentionDays() async {
    try {
      final String? v = await getAppConfig(kHistoryRetentionDaysKey);
      final int days = int.tryParse(v ?? "") ?? 10;
      return days.clamp(1, 30);
    } catch (e) {
      return Future.error("Error loading retention days: $e");
    }
  }

  @override
  Future<StockVO?> getStockByIDSearch(String query, String shopfront) async {
    try {
      final db = _database!;
      final result = await db.query(
        'Stocks',
        where: 'stock_id = ? AND shopfront = ?',
        whereArgs: [query, shopfront],
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
  Future<int> getUnsyncedStocksCount({
    required String shopfront,
    String? query,
  }) async {
    try {
      final db = _database!;
      final q = (query ?? "").trim();

      if (q.isEmpty) {
        final result = await db.rawQuery(
          'SELECT COUNT(*) as cnt FROM Stocktake WHERE shopfront = ? AND is_synced = ?',
          [shopfront, 0],
        );
        return (result.first['cnt'] as int?) ?? 0;
      }

      final like = '%$q%';
      final result = await db.rawQuery(
        '''
      SELECT COUNT(*) as cnt
      FROM Stocktake
      WHERE shopfront = ?
        AND is_synced = ?
        AND (barcode LIKE ? OR description LIKE ?)
      ''',
        [shopfront, 0, like, like],
      );

      return (result.first['cnt'] as int?) ?? 0;
    } catch (e) {
      return Future.error("Error counting stocktake list: $e");
    }
  }

  @override
  Future<List<CountedStockVO>> getUnsyncedStocksPaged({
    required String shopfront,
    required int limit,
    required int offset,
    String? query,
  }) async {
    try {
      final db = _database!;
      final q = (query ?? "").trim();

      List<Map<String, dynamic>> result;

      if (q.isEmpty) {
        result = await db.query(
          'Stocktake',
          where: 'shopfront = ? AND is_synced = ?',
          whereArgs: [shopfront, 0],
          orderBy: 'stocktake_date ASC',
          limit: limit,
          offset: offset,
        );
      } else {
        final like = '%$q%';
        result = await db.query(
          'Stocktake',
          where:
              'shopfront = ? AND is_synced = ? AND (barcode LIKE ? OR description LIKE ?)',
          whereArgs: [shopfront, 0, like, like],
          orderBy: 'stocktake_date ASC',
          limit: limit,
          offset: offset,
        );
      }

      return result.map((map) {
        final mutableMap = Map<String, dynamic>.from(map);
        mutableMap['is_synced'] = mutableMap['is_synced'] == 1;
        return CountedStockVO.fromJson(mutableMap);
      }).toList();
    } catch (e) {
      return Future.error("Error retrieving paged stocktake list: $e");
    }
  }

  @override
  Future<List<StockVO>> getStocksByBarcode(
    String barcode,
    String shopfront,
  ) async {
    final db = _database!;
    final rows = await db.query(
      'Stocks',
      where: 'Barcode = ? AND shopfront = ?',
      whereArgs: [barcode, shopfront],
    );

    return rows.map((e) => StockVO.fromJson(e)).toList();
  }

  //Save Data

  Future<Map<int, Map<String, dynamic>>> _getStockBasicsByIds({
    required Database db,
    required String shopfront,
    required List<int> ids,
  }) async {
    final Map<int, Map<String, dynamic>> out = {};

    const int batchSize = 200;
    for (int i = 0; i < ids.length; i += batchSize) {
      final batch = ids.skip(i).take(batchSize).toList();
      final placeholders = List.filled(batch.length, '?').join(',');

      final rows = await db.rawQuery(
        '''
      SELECT stock_id, Barcode, description, quantity
      FROM Stocks
      WHERE shopfront = ?
        AND stock_id IN ($placeholders)
    ''',
        [shopfront, ...batch],
      );

      for (final r in rows) {
        final id = (r['stock_id'] as num).toInt();
        out[id] = r;
      }
    }
    return out;
  }

  @override
  Future<void> restoreStocktakeFromBackup({
    required String shopfront,
    required List<BackupStocktakeItemVO> items,
  }) async {
    final db = _database!;
    if (items.isEmpty) return;

    final ids = items.map((e) => e.stockId).toSet().toList();

    final basics = await _getStockBasicsByIds(
      db: db,
      shopfront: shopfront,
      ids: ids,
    );

    await db.transaction((txn) async {
      for (final it in items) {
        final b = basics[it.stockId];

        final barcode = (b?['Barcode']?.toString() ?? "");
        final desc = (b?['description']?.toString() ?? "Stock #${it.stockId}");

        // inStock comes from Stocks.quantity (safe fallback 0)
        final inStockNum = b?['quantity'];
        final int inStock = (inStockNum is num) ? inStockNum.toInt() : 0;

        await txn.insert('Stocktake', {
          'stock_id': it.stockId,
          'shopfront': shopfront,
          'quantity': (it.quantity).toInt(),
          'inStock': inStock,
          'stocktake_date': it.stocktakeDate.toIso8601String(),
          'date_modified': it.dateModified.toIso8601String(),
          'is_synced': 0,
          'description': desc,
          'barcode': barcode,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  @override
  Future<void> setHistoryRetentionDays(int days) async {
    try {
      final int safeDays = days.clamp(1, 30);
      await saveAppConfig(kHistoryRetentionDaysKey, safeDays.toString());
    } catch (e) {
      return Future.error("Error saving retention days: $e");
    }
  }

  @override
  Future<void> saveStocktakeHistorySession({
    required String sessionId,
    required String shopfront,
    required String mobileDeviceId,
    required String mobileDeviceName,
    required int totalStocks,
    required DateTime dateStarted,
    required DateTime dateEnded,
    required List<CountedStockVO> items,
  }) async {
    try {
      final db = _database!;
      await db.transaction((txn) async {
        await txn.insert('StocktakeHistorySession', {
          'session_id': sessionId,
          'shopfront': shopfront,
          'mobile_device_id': mobileDeviceId,
          'mobile_device_name': mobileDeviceName,
          'total_stocks': totalStocks,
          'date_started': dateStarted.toIso8601String(),
          'date_ended': dateEnded.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        final batch = txn.batch();
        for (final s in items) {
          batch.insert('StocktakeHistoryItems', {
            'session_id': sessionId,
            'stock_id': s.stockID,
            'shopfront': shopfront,
            'quantity': s.quantity,
            'inStock': s.inStock,
            'stocktake_date': s.stocktakeDate.toIso8601String(),
            'date_modified': s.dateModified.toIso8601String(),
            'description': s.description,
            'barcode': s.barcode,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      });
    } catch (e) {
      return Future.error("Error saving history session: $e");
    }
  }

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
      final int stockId = stockData['stock_id'];
      final String shopfront = stockData['shopfront'];
      final num newQty = stockData['quantity'];

      // Use a transaction to ensure reading and writing happens atomically
      await db.transaction((txn) async {
        //Check if the stock already exists for this shop
        final List<Map<String, dynamic>> existingRecords = await txn.query(
          'Stocktake',
          columns: ['quantity'],
          where: 'stock_id = ? AND shopfront = ?',
          whereArgs: [stockId, shopfront],
        );

        if (existingRecords.isNotEmpty) {
          //Calculate the new total (Existing + New)
          final num currentQty = existingRecords.first['quantity'];
          final double totalQty = currentQty.toDouble() + newQty.toDouble();

          // We copy the incoming stockData so we update the 'date_modified'
          // and other fields to the latest scan details, but force the new total qty.
          final Map<String, dynamic> updateData = Map.from(stockData);
          updateData['quantity'] = totalQty;

          await txn.update(
            'Stocktake',
            updateData,
            where: 'stock_id = ? AND shopfront = ?',
            whereArgs: [stockId, shopfront],
          );
        } else {
          await txn.insert(
            'Stocktake',
            stockData,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
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

  @override
  Future<int> cleanupHistoryByRetention() async {
    try {
      final int days = await getHistoryRetentionDays();

      // We store last cleanup to avoid doing heavy deletes too often
      final String? last = await getAppConfig(kHistoryLastCleanupKey);
      DateTime? lastDt;
      if (last != null && last.isNotEmpty) {
        try {
          lastDt = DateTime.parse(last).toUtc();
        } catch (_) {}
      }

      // Run cleanup at most once every 6 hours
      final nowUtc = DateTime.now().toUtc();
      if (lastDt != null &&
          nowUtc.difference(lastDt) < const Duration(hours: 6)) {
        return 0;
      }

      final cutoffUtc = nowUtc.subtract(Duration(days: days));
      final deleted = await deleteHistoryOlderThan(cutoffUtc);

      await saveAppConfig(kHistoryLastCleanupKey, nowUtc.toIso8601String());
      return deleted;
    } catch (e) {
      return Future.error("Error cleaning history: $e");
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
  Future<int> deleteHistoryOlderThan(DateTime cutoffUtc) async {
    try {
      final db = _database!;
      final cutoffIso = cutoffUtc.toIso8601String();

      return await db.transaction((txn) async {
        final sessions = await txn.query(
          'StocktakeHistorySession',
          columns: ['session_id'],
          where: 'created_at < ?',
          whereArgs: [cutoffIso],
        );

        if (sessions.isEmpty) return 0;

        final ids = sessions.map((e) => e['session_id'].toString()).toList();
        final placeholders = List.filled(ids.length, '?').join(',');

        await txn.delete(
          'StocktakeHistoryItems',
          where: 'session_id IN ($placeholders)',
          whereArgs: ids,
        );

        final deletedSessions = await txn.delete(
          'StocktakeHistorySession',
          where: 'session_id IN ($placeholders)',
          whereArgs: ids,
        );

        return deletedSessions;
      });
    } catch (e) {
      return Future.error("Error deleting old history: $e");
    }
  }

  @override
  Future<void> updateStockQuantity({
    required int stockId,
    required String shopfront,
    required num newQuantity,
  }) async {
    try {
      final db = _database!;

      final Map<String, dynamic> valuesToUpdate = {
        'quantity': newQuantity,
        'date_modified': DateTime.now().toIso8601String(),

        'is_synced': 0,
      };

      final rowsAffected = await db.update(
        'Stocktake',
        valuesToUpdate,
        where: 'stock_id = ? AND shopfront = ?',
        whereArgs: [stockId, shopfront],
      );

      if (rowsAffected == 0) {
        // Optional: Handle the case where the item wasn't found
        logger.w('Warning: No record found to update for Stock ID: $stockId');
      } else {
        logger.d(
          'Successfully updated quantity to $newQuantity for Stock ID: $stockId',
        );
      }
    } catch (error) {
      logger.e('Error updating stock quantity in local db: $error');
      return Future.error("Error updating stock quantity: $error");
    }
  }
}
