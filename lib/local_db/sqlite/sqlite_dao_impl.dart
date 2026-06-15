import 'dart:convert';

import 'package:path/path.dart';

/// =============================================================================
/// SQLite DAO Implementation
/// =============================================================================
///
/// This file contains all local database operations for the RM Mobile app.
/// Methods are organized by screen/feature for easier navigation:
///
/// 1. DATABASE INITIALIZATION & MIGRATIONS
///    - Database setup, table creation, schema upgrades
///
/// 2. APP CONFIG & HOST CONNECTION SETTINGS
///    - Server IP, port, API key, shopfront info, device ID
///    - Used during app startup and settings configuration
///
/// 3. NETWORK CREDENTIALS & PATHS (***These are only when we did with SMB POSTMAN Connection. Deprecated)
///    - SMB/network share authentication and saved paths
///    - Used in shopfront connection screen
///
/// 4. STOCK MASTER DATA (Stock Screen)
///    - Bulk insert, search, filtering, sorting of stock items
///    - Fetching stock by barcode, ID, or description
///
/// 5. STOCKTAKE / COUNTING (Stocktake Screen)
///    - Recording counted stock, tracking sync status
///    - Managing unsynced/synced stocktake entries
///
/// 6. STOCKTAKE HISTORY (History Screen)
///    - Saving completed stocktake sessions
///    - Retention policy and cleanup operations
///
/// 7. PENDING STOCK UPDATES (Offline Sync Queue)
///    - Queue for stock edits made offline
///    - Conflict detection and resolution
///
/// 8. CUSTOMER MASTER DATA (Customer Screen)
///    - Customer records, addresses, search and filtering
///    - Next ID generation for new customers
///
/// 9. PENDING CUSTOMER UPDATES (Offline Sync Queue)
///    - Queue for customer edits made offline
///    - Conflict detection and payload management
///
/// 10. PENDING CUSTOMER CREATIONS (Offline Sync Queue)
///     - Queue for new customers created offline
///     - ID renewal before server sync
///
/// 11. CUSTOMER TRANSACTIONS (Customer Details Screen)
///     - Purchases, credits, invoices, laybys, CSO, SO/Quote data
///     - Transaction history for each customer
///
/// 12. SALE SESSIONS (Sale/Cart Screen)
///     - Parked sales, quotes, held transactions
///     - Session management for POS workflow
///
/// 13. TAX CODES (Sale Configuration)
///     - Tax code list for sales calculations
///
/// =============================================================================
import 'package:rmmobile/entities/response/customer_search_response.dart';
import 'package:rmmobile/entities/response/paginated_customer_response.dart';
import 'package:rmmobile/entities/response/paginated_stock_response.dart';
import 'package:rmmobile/entities/response/stock_search_resposne.dart';
import 'package:rmmobile/entities/vos/backup_stocktake_item_vo.dart';
import 'package:rmmobile/entities/vos/counted_stock_vo.dart';
import 'package:rmmobile/entities/vos/pending_customer_creation_vo.dart';
import 'package:rmmobile/entities/vos/pending_customer_update_vo.dart';
import 'package:rmmobile/entities/vos/pending_stock_update_vo.dart';
import 'package:rmmobile/entities/vos/pricing_rules.dart';
import 'package:rmmobile/entities/vos/customer_vo.dart';
import 'package:rmmobile/entities/vos/customer_address_vo.dart';
import 'package:rmmobile/entities/vos/search_mode.dart';
import 'package:rmmobile/entities/vos/stock_vo.dart';
import 'package:rmmobile/entities/vos/tax_code_vo.dart';
import 'package:rmmobile/entities/vos/sync_metadata.dart';
import 'package:rmmobile/local_db/local_db_dao.dart';
import 'package:rmmobile/local_db/sqlite/sqlite_constants.dart';
import 'package:sqflite/sqflite.dart';
import '../../entities/vos/filter_criteria.dart';
import '../../utils/log_utils.dart';

class SQLiteDAOImpl extends LocalDbDAO {
  Database? _database;

  // ===========================================================================
  // SECTION 1: DATABASE INITIALIZATION & MIGRATIONS
  // ===========================================================================
  // Handles SQLite database setup including:
  // - Creating the database file and configuring pragmas for performance
  // - Creating all required tables on first install
  // - Running schema migrations when upgrading from older versions
  // - Adding missing columns safely with _addColumnIfMissing helper
  // ===========================================================================

  @override
  Future<void> initDB() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, dbName);

      _database = await openDatabase(
        path,
        version: 10,
        onConfigure: (db) async {
          await db.rawQuery('PRAGMA journal_mode=WAL');
          await db.rawQuery('PRAGMA foreign_keys=ON');
          await db.rawQuery('PRAGMA busy_timeout=5000');
          await db.rawQuery('PRAGMA case_sensitive_like=OFF');
        },
        onCreate: (db, version) async {
          await db.execute(stocktakeTableCreationQuery);
          await db.execute(appConfigTableCreationQuery);
          await db.execute(networkCredentialsTableCreationQuery);
          await db.execute(savedPathsTableCreationQuery);
          await db.execute(stocksTableCreationQuery);
          await db.execute(stocktakeHistorySessionCreationQuery);
          await db.execute(stocktakeHistoryItemsCreationQuery);
          await db.execute(customersTableCreationQuery);
          await db.execute(customerAddressesTableCreationQuery);
          await db.execute(pendingStockUpdatesTableCreationQuery);
          await db.execute(pendingCustomerUpdatesTableCreationQuery);
          await db.execute(pendingCustomerUpdateAddressesTableCreationQuery);
          await db.execute(pendingCustomerCreationsTableCreationQuery);
          await db.execute(pendingCustomerCreationAddressesTableCreationQuery);
          await db.execute(customerPurchasesTableCreationQuery);
          await db.execute(customerCreditTableCreationQuery);
          await db.execute(customerInvoicesTableCreationQuery);
          await db.execute(customerIvPayTableCreationQuery);
          await db.execute(customerLaybysTableCreationQuery);
          await db.execute(customerLbPayTableCreationQuery);
          await db.execute(customerCsoTableCreationQuery);
          await db.execute(customerSoQuoteTableCreationQuery);
          await db.execute(customerSoPayTableCreationQuery);
          await db.execute(saleSessionsTableCreationQuery);
          await db.execute(taxCodesTableCreationQuery);

          // 2. Create Indexes for fast searching
          await db.execute(createIdxStocksBarcode);
          await db.execute(createIdxStocksBarcodeNoCase);
          await db.execute(createIdxStocksDesc);
          await db.execute(createIdxStocksDescNoCase);
          await db.execute(createIdxStocksCustom1);
          await db.execute(createIdxStocksCustom2);
          await db.execute(createIdxCustBarcode);
          await db.execute(createIdxCustBarcodeNoCase);
          await db.execute(createIdxCustSurname);
          await db.execute(createIdxCustGivenNames);
          await db.execute(createIdxCustCompany);
          await db.execute(createIdxCustPhone);
          await db.execute(createIdxCustMobile);
          await db.execute(createIdxCustFax);
          await db.execute(createIdxCustEmail);
          await db.execute(createIdxCustSuburb);
          await db.execute(createIdxCustState);
          await db.execute(createIdxCustPostcode);
          await db.execute(createIdxCustCustom1);
          await db.execute(createIdxCustCustom2);
          await db.execute(createIdxStocktakeBarcode);
          await db.execute(createIdxStocktakeDescription);
          await db.execute(createIdxStocktakeDate);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _addColumnIfMissing(
              db: db,
              table: 'Stocks',
              column: 'last_sale_date',
              definition: 'TEXT',
            );
          }
          if (oldVersion < 3) {
            await db.execute(customersTableCreationQuery);
            await db.execute(customerAddressesTableCreationQuery);
          }
          if (oldVersion < 4) {
            await db.execute(pendingStockUpdatesTableCreationQuery);
            await db.execute(pendingCustomerUpdatesTableCreationQuery);
          }
          if (oldVersion < 8) {
            await db.execute(pendingCustomerCreationsTableCreationQuery);
            await _addColumnIfMissing(
              db: db,
              table: 'PendingStockUpdates',
              column: 'error_message',
              definition: 'TEXT',
            );
            await _addColumnIfMissing(
              db: db,
              table: 'PendingCustomerUpdates',
              column: 'error_message',
              definition: 'TEXT',
            );
            try {
              final rows = await db.query(
                'PendingCustomerUpdates',
                where: 'action = ?',
                whereArgs: ['create'],
              );
              for (final row in rows) {
                await db.insert('PendingCustomerCreations', {
                  'shopfront': row['shopfront'],
                  'customer_id': row['customer_id'],
                  'payload_json': row['payload_json'],
                  'created_at': row['created_at'],
                  'status': row['status'] ?? 0,
                  'error_message': null,
                });
              }
              await db.delete(
                'PendingCustomerUpdates',
                where: 'action = ?',
                whereArgs: ['create'],
              );
            } catch (e) {
              logger.e('Error migrating pending customer creations: $e');
            }
          }
          if (oldVersion < 5) {
            await db.execute(customerPurchasesTableCreationQuery);
            await db.execute(customerCreditTableCreationQuery);
            await db.execute(customerInvoicesTableCreationQuery);
            await db.execute(customerIvPayTableCreationQuery);
            await db.execute(customerLaybysTableCreationQuery);
            await db.execute(customerLbPayTableCreationQuery);
            await db.execute(customerCsoTableCreationQuery);
            await db.execute(customerSoQuoteTableCreationQuery);
            await db.execute(customerSoPayTableCreationQuery);
          }
          if (oldVersion < 6) {
            await _addColumnIfMissing(
              db: db,
              table: 'Stocks',
              column: 'pricing_rules',
              definition: 'TEXT',
            );
          }
          if (oldVersion < 7) {
            await _addColumnIfMissing(
              db: db,
              table: 'CustomerPurchases',
              column: 'stock_id',
              definition: 'INTEGER',
            );
            await _addColumnIfMissing(
              db: db,
              table: 'CustomerPurchases',
              column: 'goods_tax',
              definition: 'TEXT',
            );
          }
        },
      );

      // Ensure new columns exist without bumping DB version
      await _addColumnIfMissing(
        db: _database!,
        table: 'Stocks',
        column: 'is_on_promotion',
        definition: 'INTEGER',
      );
      await _addColumnIfMissing(
        db: _database!,
        table: 'Stocks',
        column: 'promotion',
        definition: 'TEXT',
      );
      await _addColumnIfMissing(
        db: _database!,
        table: 'Stocks',
        column: 'serial_numbers',
        definition: 'TEXT',
      );
      await _addColumnIfMissing(
        db: _database!,
        table: 'Stocks',
        column: 'sales_prompt',
        definition: 'TEXT',
      );
      await _addColumnIfMissing(
        db: _database!,
        table: 'Stocks',
        column: 'purchaseorder_qty',
        definition: 'REAL',
      );
      await _addColumnIfMissing(
        db: _database!,
        table: 'Stocks',
        column: 'cso_qty',
        definition: 'REAL',
      );
      logger.d('Successfully initialized SQLite local database!');
    } catch (error) {
      logger.e('Error initializing for SQLite local database: $error');
    }
  }

  @override
  Future<void> checkpointDatabase() async {
    try {
      final db = _database;
      if (db == null) return;
      await db.rawQuery('PRAGMA wal_checkpoint(FULL)');
      logger.d('WAL checkpoint completed - data consolidated to main db file');
    } catch (error) {
      logger.e('Error during WAL checkpoint: $error');
    }
  }

  @override
  Future<void> closeDatabase() async {
    try {
      final db = _database;
      if (db == null) return;
      await db.close();
      _database = null;
      logger.d('Database closed successfully');
    } catch (error) {
      logger.e('Error closing database: $error');
      rethrow;
    }
  }

  @override
  Future<void> reopenDatabase() async {
    try {
      await initDB();
      logger.d('Database reopened successfully');
    } catch (error) {
      logger.e('Error reopening database: $error');
      rethrow;
    }
  }

  Future<void> _addColumnIfMissing({
    required Database db,
    required String table,
    required String column,
    required String definition,
  }) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final hasColumn = info.any((row) => row['name'] == column);
    if (!hasColumn) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  // ===========================================================================
  // SECTION 3: NETWORK CREDENTIALS & PATHS (Shopfront Connection Screen) (*****DEPRECATED***)
  // ===========================================================================
  // Manages SMB/Windows share authentication and saved network paths.
  // Used when connecting to retail management servers via network shares.
  //
  // Features:
  // - Stores username/password for network authentication per IP
  // - Saves previously used network paths for quick reconnection
  // - Tracks which shopfront is associated with each network path
  // ===========================================================================

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

  // ===========================================================================
  // SECTION 5: STOCKTAKE / COUNTING (Stocktake Screen)
  // ===========================================================================
  // Handles all stocktake counting operations:
  // - Recording counted quantities for each stock item
  // - Updating quantities when same item is scanned multiple times
  // - Deleting records after successful server commit
  //
  // The Stocktake table stores uncommitted counted items with:
  // - stock_id, shopfront, quantity, inStock (original qty)
  // - barcode, description for offline display
  //
  // When committed, records are saved to history tables then deleted.
  // ===========================================================================

  @override
  Future<List<Map<String, dynamic>>> getStocktakeList({
    required String shopfront,
  }) async {
    try {
      final db = _database!;

      return await db.query(
        'Stocktake',
        where: 'shopfront = ?',
        whereArgs: [shopfront],
        orderBy: 'date_modified DESC',
      );
    } catch (error) {
      logger.e('Error retrieving stocktake list from local db: $error');
      return Future.error("Error retrieving stocktake list: $error");
    }
  }

  @override
  Future<List<CountedStockVO>> getStocktakeItemsToCommit(String shopfront) async {
    try {
      final db = _database!;
      final List<Map<String, dynamic>> result = await db.query(
        'Stocktake',
        where: 'shopfront = ?',
        whereArgs: [shopfront],
        orderBy: 'stocktake_date ASC',
      );

      return result.map((map) {
        return CountedStockVO.fromJson(map);
      }).toList();
    } catch (error) {
      logger.e('Error getting stocktake items to commit from local db: $error');
      return Future.error("Error retrieving stocktake items to commit: $error");
    }
  }

  @override
  Future<Map<String, dynamic>?> getExistingStocktakeCount({
    required int stockId,
    required String shopfront,
  }) async {
    try {
      final db = _database!;

      // 1. Item currently counted (uncommitted) in this session
      final counted = await db.query(
        'Stocktake',
        columns: ['quantity'],
        where: 'stock_id = ? AND shopfront = ?',
        whereArgs: [stockId, shopfront],
        limit: 1,
      );
      if (counted.isNotEmpty) {
        return {'source': 'counted', 'quantity': counted.first['quantity']};
      }

      // 2. Item sent to shopfront (committed to history) within the last 24 hours
      final String cutoff = DateTime.now()
          .subtract(const Duration(hours: 24))
          .toIso8601String();
      final history = await db.rawQuery(
        '''
        SELECT i.quantity AS quantity
        FROM StocktakeHistoryItems i
        JOIN StocktakeHistorySession s ON i.session_id = s.session_id
        WHERE i.stock_id = ? AND i.shopfront = ? AND s.created_at >= ?
        ORDER BY s.created_at DESC
        LIMIT 1
        ''',
        [stockId, shopfront, cutoff],
      );
      if (history.isNotEmpty) {
        return {'source': 'history', 'quantity': history.first['quantity']};
      }

      return null;
    } catch (error) {
      logger.e('Error checking existing stocktake count from local db: $error');
      return null;
    }
  }

  // ===========================================================================
  // SECTION 4: STOCK MASTER DATA (Stock Screen / Stock Search)
  // ===========================================================================
  // Manages the local copy of stock master data synced from the server.
  //
  // Features:
  // - Bulk insert/update of stock items during sync
  // - Multi-column search (barcode, description, custom1, custom2)
  // - Paginated search with sorting and filtering
  // - Filter by department, category, supplier
  // - Get distinct values for filter dropdowns
  // - Update stock details locally after offline edits
  //
  // Search priority: Barcode > Description > Custom1 > Custom2
  // ===========================================================================

  @override
  Future<StockSearchResult> getStockBySearch(
    String query,
    String shopfront,
  ) async {
    try {
      final db = _database!;
      final trimmed = query.trim();
      if (trimmed.isEmpty) return StockSearchResult.none();

      // Calculate barcode variations for cross-platform compatibility (iOS/Android)
      // iOS (Apple Vision) reads UPC-A as 13-digit EAN-13 with leading zero
      // Android (ML Kit) reads UPC-A as 12 digits
      final withoutLeadingZero = (trimmed.length == 13 && trimmed.startsWith('0'))
          ? trimmed.substring(1)
          : trimmed;
      final withLeadingZero = (trimmed.length == 12)
          ? '0$trimmed'
          : trimmed;

      // 1) Barcode exact match (case-insensitive, ALL matches) - exclude default stock
      // Check all three variations: original, without leading zero, with leading zero
      final barcodeRows = await db.query(
        'Stocks',
        where: '(Barcode = ? OR Barcode = ? OR Barcode = ?) COLLATE NOCASE AND shopfront = ? AND stock_id != 0',
        whereArgs: [trimmed, withoutLeadingZero, withLeadingZero, shopfront],
      );

      if (barcodeRows.isNotEmpty) {
        final matches = barcodeRows.map((e) => StockVO.fromJson(e)).toList();

        if (matches.length == 1) {
          return StockSearchResult.found(matches.first);
        }

        // Duplicate barcode case
        return StockSearchResult.duplicates(matches);
      }

      // 2) Description exact match (case-insensitive, ALL matches) - exclude default stock
      final descriptionExactRows = await db.query(
        'Stocks',
        where:
            'description = ? COLLATE NOCASE AND shopfront = ? AND stock_id != 0',
        whereArgs: [trimmed, shopfront],
      );

      if (descriptionExactRows.isNotEmpty) {
        final matches =
            descriptionExactRows.map((e) => StockVO.fromJson(e)).toList();

        if (matches.length == 1) {
          return StockSearchResult.found(matches.first);
        }

        return StockSearchResult.duplicates(matches);
      }

      // 3) Description LIKE match (ALL matches) - exclude default stock
      final descriptionRows = await db.query(
        'Stocks',
        where: 'description LIKE ? AND shopfront = ? AND stock_id != 0',
        whereArgs: ['%$trimmed%', shopfront],
      );

      if (descriptionRows.isNotEmpty) {
        final matches = descriptionRows.map((e) => StockVO.fromJson(e)).toList();
        
        if (matches.length == 1) {
          return StockSearchResult.found(matches.first);
        }
        
        return StockSearchResult.duplicates(matches);
      }

      // 4) Custom1 LIKE match (ALL matches) - exclude default stock
      final custom1Rows = await db.query(
        'Stocks',
        where: 'custom1 LIKE ? AND shopfront = ? AND stock_id != 0',
        whereArgs: ['%$trimmed%', shopfront],
      );

      if (custom1Rows.isNotEmpty) {
        final matches = custom1Rows.map((e) => StockVO.fromJson(e)).toList();
        
        if (matches.length == 1) {
          return StockSearchResult.found(matches.first);
        }
        
        return StockSearchResult.duplicates(matches);
      }

      // 5) Custom2 LIKE match (ALL matches) - exclude default stock
      final custom2Rows = await db.query(
        'Stocks',
        where: 'custom2 LIKE ? AND shopfront = ? AND stock_id != 0',
        whereArgs: ['%$trimmed%', shopfront],
      );

      if (custom2Rows.isNotEmpty) {
        final matches = custom2Rows.map((e) => StockVO.fromJson(e)).toList();
        
        if (matches.length == 1) {
          return StockSearchResult.found(matches.first);
        }
        
        return StockSearchResult.duplicates(matches);
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
    SearchMode searchMode = SearchMode.partial,
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

      final String safeSortColumn = allowedColumns.contains(sortColumn)
          ? sortColumn
          : 'description';

      final String orderBy = "$safeSortColumn ${ascending ? 'ASC' : 'DESC'}";

      // Exclude default stock (stock_id = 0) from all queries
      String baseWhere = 'shopfront = ? AND stock_id != 0';
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
        String? matchedColumn,
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
            Sqflite.firstIntValue(results[1] as List<Map<String, dynamic>>) ??
            0;

        // Build matched fields map
        final Map<int, String> matchedFields = {};
        if (matchedColumn != null && q.isNotEmpty) {
          for (var item in items) {
            matchedFields[item.stockID.toInt()] = matchedColumn;
          }
        }

        return PaginatedStockResult(items, count, matchedFields: matchedFields);
      }

      if (q.isEmpty) {
        return runQuery(whereClause: baseWhere, args: baseArgs, matchedColumn: null);
      }

      // Determine search pattern based on search mode
      final String searchPattern = searchMode == SearchMode.prefix
          ? '$q%'  // Prefix search: matches start of string
          : '%$q%'; // Partial search: matches anywhere in string

      // Search priority is always:
      // Barcode -> Description -> Custom1 -> Custom2
      // Chips are used for sorting only.
      final searchPriority = <String>[
        'Barcode',
        'description',
        'custom1',
        'custom2',
      ];

      bool matchesValue(String value) {
        final normalized = value.toLowerCase();
        final needle = q.toLowerCase();
        if (searchMode == SearchMode.prefix) {
          return normalized.startsWith(needle);
        }
        return normalized.contains(needle);
      }

      String? matchedColumnForRow(Map<String, dynamic> row) {
        for (final column in searchPriority) {
          final value = row[column];
          if (value != null && matchesValue(value.toString())) {
            return column;
          }
        }
        return null;
      }

      final matchClause = searchPriority.map((col) => '$col LIKE ?').join(' OR ');
      final whereClause = '$baseWhere AND ($matchClause)';
      final whereArgs = [
        ...baseArgs,
        ...List.filled(searchPriority.length, searchPattern),
      ];

      final orderCase = searchPriority
          .asMap()
          .entries
          .map((entry) => 'WHEN ${entry.value} LIKE ? THEN ${entry.key}')
          .join(' ');
      final orderedBy =
          'CASE $orderCase ELSE ${searchPriority.length} END, $safeSortColumn ${ascending ? 'ASC' : 'DESC'}';

      final countFuture = db.rawQuery(
        'SELECT COUNT(*) as count FROM Stocks WHERE $whereClause',
        whereArgs,
      );

      final dataFuture = db.rawQuery(
        'SELECT * FROM Stocks WHERE $whereClause ORDER BY $orderedBy LIMIT ? OFFSET ?',
        [
          ...whereArgs,
          ...List.filled(searchPriority.length, searchPattern),
          limit,
          offset,
        ],
      );

      final results = await Future.wait([dataFuture, countFuture]);
      final rows = results[0] as List<Map<String, dynamic>>;
      final items = rows.map((e) => StockVO.fromJson(e)).toList();
      final int count =
          Sqflite.firstIntValue(results[1] as List<Map<String, dynamic>>) ?? 0;

      final Map<int, String> matchedFields = {};
      for (var i = 0; i < rows.length; i++) {
        final matchedColumn = matchedColumnForRow(rows[i]);
        if (matchedColumn != null) {
          matchedFields[items[i].stockID.toInt()] = matchedColumn;
        }
      }

      return PaginatedStockResult(items, count, matchedFields: matchedFields);
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

      // Exclude default stock (stock_id = 0) from distinct values
      final List<Map<String, dynamic>> result = await db.rawQuery(
        '''
      SELECT DISTINCT $columnName 
      FROM Stocks 
      WHERE shopfront = ? 
        AND stock_id != 0
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

  // ===========================================================================
  // SECTION 2: APP CONFIG & HOST CONNECTION SETTINGS (App Startup / Settings)
  // ===========================================================================
  // Stores application configuration including:
  // - Server connection details (IP, port, API key, hostname)
  // - Current shopfront selection (ID and name)
  // - RM software version on server
  // - Device ID for this mobile device
  // - History retention settings
  //
  // These values are saved on successful connection and loaded on app startup
  // to restore the previous session without requiring re-authentication.
  // ===========================================================================

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
  Future<String?> getHostIpAddress() async {
    try {
      return await getAppConfig(kHostIpAddressKey);
    } catch (error) {
      logger.e('Error getting host IP address from local db: $error');
      return Future.error(
        "Error getting host IP address from local db: $error",
      );
    }
  }

  @override
  Future<String?> getHostPort() async {
    try {
      return await getAppConfig(kHostPortKey);
    } catch (error) {
      logger.e('Error getting host port from local db: $error');
      return Future.error("Error getting host port from local db: $error");
    }
  }

  @override
  Future<String?> getApiKey() async {
    try {
      return await getAppConfig(kApiKey);
    } catch (error) {
      logger.e('Error getting API key from local db: $error');
      return Future.error("Error getting API key from local db: $error");
    }
  }

  @override
  Future<String?> getHostName() async {
    try {
      return await getAppConfig(kHostNameKey);
    } catch (error) {
      logger.e('Error getting host name from local db: $error');
      return Future.error("Error getting host name from local db: $error");
    }
  }

  @override
  Future<String?> getShopfrontId() async {
    try {
      return await getAppConfig(kShopfrontIdKey);
    } catch (error) {
      logger.e('Error getting shopfront id from local db: $error');
      return Future.error("Error getting shopfront id from local db: $error");
    }
  }

  @override
  Future<String?> getShopfrontName() async {
    try {
      return await getAppConfig(kShopfrontNameKey);
    } catch (error) {
      logger.e('Error getting shopfront name from local db: $error');
      return Future.error("Error getting shopfront name from local db: $error");
    }
  }

  @override
  Future<String?> getRMVersion() async {
    try {
      return await getAppConfig(kRMVersionKey);
    } catch (error) {
      logger.e('Error getting RM version from local db: $error');
      return Future.error("Error getting RM version from local db: $error");
    }
  }

  @override
  Future<String?> getDeviceId() async {
    try {
      return await getAppConfig(kDeviceIdKey);
    } catch (error) {
      logger.e('Error getting device id from local db: $error');
      return Future.error("Error getting device id from local db: $error");
    }
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
  Future<SyncMetadata> getStockSyncMetadata(String shopfront) async {
    try {
      final db = _database!;
      final result = await db.rawQuery(
        'SELECT COUNT(*) AS count, '
        'MIN(stock_id) AS min_id, '
        'MAX(stock_id) AS max_id, '
        'COALESCE(SUM(stock_id), 0) AS checksum '
        'FROM Stocks WHERE shopfront = ?',
        [shopfront],
      );

      final row = result.isNotEmpty ? result.first : <String, Object?>{};
      final count = (row['count'] as num?)?.toInt() ?? 0;
      final minId = (row['min_id'] as num?)?.toInt() ?? 0;
      final maxId = (row['max_id'] as num?)?.toInt() ?? 0;
      final checksum = (row['checksum'] as num?)?.toInt() ?? 0;

      return SyncMetadata(
        count: count,
        minId: minId,
        maxId: maxId,
        checksum: checksum,
      );
    } catch (error) {
      logger.e('Error getting stock metadata for $shopfront: $error');
      return Future.error("Error getting stock metadata: $error");
    }
  }

  @override
  Future<List<int>> getStockIdsInRange({
    required String shopfront,
    required int fromId,
    required int toId,
  }) async {
    try {
      if (toId < fromId) return [];
      final db = _database!;
      final rows = await db.query(
        'Stocks',
        columns: ['stock_id'],
        where: 'shopfront = ? AND stock_id BETWEEN ? AND ?',
        whereArgs: [shopfront, fromId, toId],
        orderBy: 'stock_id ASC',
      );
      return rows
          .map((row) => (row['stock_id'] as num).toInt())
          .toList();
    } catch (error) {
      logger.e('Error getting stock ids for $shopfront: $error');
      return Future.error("Error getting stock ids: $error");
    }
  }

  // ===========================================================================
  // SECTION 6: STOCKTAKE HISTORY (History Screen)
  // ===========================================================================
  // Manages the history of completed stocktake sessions.
  //
  // Features:
  // - Save completed stocktake sessions with all counted items
  // - View past stocktake sessions by date
  // - Configurable retention period (1-30 days)
  // - Automatic cleanup of old history entries
  // - Restore stocktake from backup if needed
  //
  // Structure:
  // - StocktakeHistorySession: Session metadata (date, device, total count)
  // - StocktakeHistoryItems: Individual items counted in each session
  // ===========================================================================

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
      final int days = int.tryParse(v ?? "") ?? 30;
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
  Future<StockVO?> getStockById(int stockId, String shopfront) async {
    try {
      final db = _database!;
      final result = await db.query(
        'Stocks',
        where: 'stock_id = ? AND shopfront = ?',
        whereArgs: [stockId, shopfront],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return StockVO.fromJson(result.first);
      }
      return null;
    } catch (error) {
      logger.e('Error getting stock by ID $stockId in $shopfront: $error');
      return null;
    }
  }

  @override
  Future<StockVO?> getStockByIdAnyShopfront(int stockId) async {
    try {
      final db = _database!;
      final result = await db.query(
        'Stocks',
        where: 'stock_id = ?',
        whereArgs: [stockId],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return StockVO.fromJson(result.first);
      }
      return null;
    } catch (error) {
      logger.e('Error getting stock by ID $stockId (any shopfront): $error');
      return null;
    }
  }

  @override
  Future<int> getStocktakeItemsToCommitCount({
    required String shopfront,
    String? query,
  }) async {
    try {
      final db = _database!;
      final q = (query ?? "").trim();

      if (q.isEmpty) {
        final result = await db.rawQuery(
          'SELECT COUNT(*) as cnt FROM Stocktake WHERE shopfront = ?',
          [shopfront],
        );
        return (result.first['cnt'] as int?) ?? 0;
      }

      final like = '%$q%';
      final result = await db.rawQuery(
        '''
      SELECT COUNT(*) as cnt
      FROM Stocktake
      WHERE shopfront = ?
        AND (barcode LIKE ? OR description LIKE ?)
      ''',
        [shopfront, like, like],
      );

      return (result.first['cnt'] as int?) ?? 0;
    } catch (e) {
      return Future.error("Error counting stocktake items to commit: $e");
    }
  }

  @override
  Future<List<CountedStockVO>> getStocktakeItemsToCommitPaged({
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
        result = await db.rawQuery('''
          SELECT 
            st.stocktake_date,
            st.stock_id,
            st.quantity,
            st.inStock,
            st.date_modified,
            st.barcode,
            st.description,
            s.cat1 AS category1,
            s.cat2 AS category2,
            s.cat3 AS category3
          FROM Stocktake st
          LEFT JOIN Stocks s ON st.stock_id = s.stock_id AND st.shopfront = s.shopfront
          WHERE st.shopfront = ?
          ORDER BY st.stocktake_date ASC
          LIMIT ? OFFSET ?
        ''', [shopfront, limit, offset]);
      } else {
        final like = '%$q%';
        result = await db.rawQuery('''
          SELECT 
            st.stocktake_date,
            st.stock_id,
            st.quantity,
            st.inStock,
            st.date_modified,
            st.barcode,
            st.description,
            s.cat1 AS category1,
            s.cat2 AS category2,
            s.cat3 AS category3
          FROM Stocktake st
          LEFT JOIN Stocks s ON st.stock_id = s.stock_id AND st.shopfront = s.shopfront
          WHERE st.shopfront = ? AND (st.barcode LIKE ? OR st.description LIKE ?)
          ORDER BY st.stocktake_date ASC
          LIMIT ? OFFSET ?
        ''', [shopfront, like, like, limit, offset]);
      }

      return result.map((map) {
        return CountedStockVO.fromJson(map);
      }).toList();
    } catch (e) {
      return Future.error("Error retrieving paged stocktake items to commit: $e");
    }
  }

  @override
  Future<List<StockVO>> getStocksByBarcode(
    String barcode,
    String shopfront,
  ) async {
    final db = _database!;
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return [];
    final rows = await db.query(
      'Stocks',
      where: 'Barcode = ? COLLATE NOCASE AND shopfront = ?',
      whereArgs: [trimmed, shopfront],
    );

    return rows.map((e) => StockVO.fromJson(e)).toList();
  }

  // ---------------------------------------------------------------------------
  // STOCKTAKE HELPER METHODS
  // ---------------------------------------------------------------------------

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
  Future<void> saveHostIpAddress(String hostIpAddress) async {
    try {
      await saveAppConfig(kHostIpAddressKey, hostIpAddress);
    } catch (error) {
      logger.e('Error saving host IP address to local db: $error');
      return Future.error("Error saving host IP address to local db: $error");
    }
  }

  @override
  Future<void> saveHostPort(String hostPort) async {
    try {
      await saveAppConfig(kHostPortKey, hostPort);
    } catch (error) {
      logger.e('Error saving host port to local db: $error');
      return Future.error("Error saving host port to local db: $error");
    }
  }

  @override
  Future<void> saveApiKey(String apiKey) async {
    try {
      await saveAppConfig(kApiKey, apiKey);
    } catch (error) {
      logger.e('Error saving API key to local db: $error');
      return Future.error("Error saving API key to local db: $error");
    }
  }

  @override
  Future<void> saveHostName(String hostName) async {
    try {
      await saveAppConfig(kHostNameKey, hostName);
    } catch (error) {
      logger.e('Error saving host name to local db: $error');
      return Future.error("Error saving host name to local db: $error");
    }
  }

  @override
  Future<void> saveShopfrontId(String shopfrontId) async {
    try {
      await saveAppConfig(kShopfrontIdKey, shopfrontId);
    } catch (error) {
      logger.e('Error saving shopfront id to local db: $error');
      return Future.error("Error saving shopfront id to local db: $error");
    }
  }

  @override
  Future<void> saveShopfrontName(String shopfrontName) async {
    try {
      await saveAppConfig(kShopfrontNameKey, shopfrontName);
    } catch (error) {
      logger.e('Error saving shopfront name to local db: $error');
      return Future.error("Error saving shopfront name to local db: $error");
    }
  }

  @override
  Future<void> saveRMVersion(String version) async {
    try {
      await saveAppConfig(kRMVersionKey, version);
    } catch (error) {
      logger.e('Error saving RM version to local db: $error');
      return Future.error("Error saving RM version to local db: $error");
    }
  }

  @override
  Future<void> saveDeviceId(String deviceId) async {
    try {
      await saveAppConfig(kDeviceIdKey, deviceId);
    } catch (error) {
      logger.e('Error saving device id to local db: $error');
      return Future.error("Error saving device id to local db: $error");
    }
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

  // ---------------------------------------------------------------------------
  // NETWORK CREDENTIAL & PATH DELETION
  // ---------------------------------------------------------------------------

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
  Future<void> deleteStocksByIds({
    required String shopfront,
    required List<int> stockIds,
  }) async {
    try {
      if (stockIds.isEmpty) return;
      final db = _database!;
      final ids = stockIds.where((id) => id > 0).toSet().toList();
      if (ids.isEmpty) return;

      const int batchSize = 900;
      await db.transaction((txn) async {
        for (int i = 0; i < ids.length; i += batchSize) {
          final chunk = ids.skip(i).take(batchSize).toList();
          final placeholders = List.filled(chunk.length, '?').join(',');
          await txn.delete(
            'Stocks',
            where: 'shopfront = ? AND stock_id IN ($placeholders)',
            whereArgs: [shopfront, ...chunk],
          );
        }
      });
    } catch (error) {
      logger.e('Error deleting stocks by ids for $shopfront: $error');
      return Future.error("Error deleting stocks by ids: $error");
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

  // ---------------------------------------------------------------------------
  // NETWORK PATH UPDATES
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // STOCK DETAIL UPDATES (Local edits before server sync)
  // ---------------------------------------------------------------------------

  @override
  Future<void> updateStockDetails({
    required int stockId,
    required String shopfront,
    required String description,
    required double sell,
    String? custom1,
    String? custom2,
    String? longDesc,
    PricingRules? pricingRules,
  }) async {
    try {
      final db = _database!;
      final Map<String, dynamic> valuesToUpdate = {
        'description': description,
        'sell': sell,
        'date_modified': DateTime.now().toIso8601String(),
      };

      if (custom1 != null) {
        valuesToUpdate['custom1'] = custom1;
      }
      if (custom2 != null) {
        valuesToUpdate['custom2'] = custom2;
      }
      if (longDesc != null) {
        valuesToUpdate['longdesc'] = longDesc;
      }
      if (pricingRules != null) {
        valuesToUpdate['pricing_rules'] = jsonEncode(pricingRules.toJson());
      }

      await db.update(
        'Stocks',
        valuesToUpdate,
        where: 'stock_id = ? AND shopfront = ?',
        whereArgs: [stockId, shopfront],
      );
    } catch (error) {
      logger.e('Error updating stock details in local db: $error');
      return Future.error("Error updating stock details: $error");
    }
  }

  // ===========================================================================
  // SECTION 7: PENDING STOCK UPDATES (Offline Sync Queue)
  // ===========================================================================
  // Queue system for stock edits made while offline or failed to sync.
  //
  // Features:
  // - Queue stock updates (description, price, custom fields)
  // - Merge multiple updates to same stock into single entry
  // - Track sync status and error messages
  // - Detect conflicts when server data is newer than pending edit
  // - Apply pending updates to local DB after successful sync
  //
  // Workflow:
  // 1. User edits stock -> addPendingStockUpdate()
  // 2. Sync attempts -> if fails, error stored
  // 3. Next sync -> detectPendingStockConflicts() checks for conflicts
  // 4. Successful sync -> deletePendingStockUpdates() removes from queue
  // ===========================================================================

  @override
  Future<int> addPendingStockUpdate({
    required String shopfront,
    required int stockId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final db = _database!;
      final existing = await db.query(
        'PendingStockUpdates',
        where: 'shopfront = ? AND stock_id = ? AND status = 0',
        whereArgs: [shopfront, stockId],
        limit: 1,
      );

      final Map<String, dynamic> mergedPayload = Map<String, dynamic>.from(
        payload,
      );

      if (existing.isNotEmpty) {
        final row = existing.first;
        final int id = row['id'] as int;
        final Map<String, dynamic> current = Map<String, dynamic>.from(
          jsonDecode(row['payload_json'] as String) as Map,
        );
        final Map<String, dynamic> combined = {
          ...current,
          ...mergedPayload,
        };

        await db.update(
          'PendingStockUpdates',
          {
            'payload_json': jsonEncode(combined),
            'created_at': DateTime.now().toIso8601String(),
            'status': 0,
            'error_message': null,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        return id;
      }

      return await db.insert('PendingStockUpdates', {
        'shopfront': shopfront,
        'stock_id': stockId,
        'payload_json': jsonEncode(mergedPayload),
        'created_at': DateTime.now().toIso8601String(),
        'status': 0,
        'error_message': null,
      });
    } catch (error) {
      logger.e('Error saving pending stock update: $error');
      return Future.error("Error saving pending stock update: $error");
    }
  }

  @override
  Future<int> getPendingStockUpdatesCount(String shopfront) async {
    try {
      final db = _database!;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM PendingStockUpdates WHERE shopfront = ? AND status = 0',
        [shopfront],
      );
      return (result.first['cnt'] as int?) ?? 0;
    } catch (error) {
      logger.e('Error getting pending stock update count: $error');
      return Future.error("Error getting pending stock update count: $error");
    }
  }

  @override
  Future<List<PendingStockUpdateVO>> getPendingStockUpdates(
    String shopfront,
  ) async {
    try {
      final db = _database!;
      final rows = await db.query(
        'PendingStockUpdates',
        where: 'shopfront = ? AND status = 0',
        whereArgs: [shopfront],
        orderBy: 'created_at DESC',
      );

      return rows.map((row) {
        final payload = jsonDecode(row['payload_json'] as String);
        return PendingStockUpdateVO(
          id: row['id'] as int,
          shopfront: row['shopfront'] as String,
          stockId: row['stock_id'] as int,
          payload: Map<String, dynamic>.from(payload as Map),
          createdAt: row['created_at'] as String,
          hasConflict: (row['has_conflict'] as int? ?? 0) == 1,
          errorMessage: row['error_message'] as String?,
        );
      }).toList();
    } catch (error) {
      logger.e('Error loading pending stock updates: $error');
      return Future.error("Error loading pending stock updates: $error");
    }
  }

  @override
  Future<void> deletePendingStockUpdates(List<int> ids) async {
    try {
      if (ids.isEmpty) return;
      final db = _database!;
      final placeholders = List.filled(ids.length, '?').join(',');
      await db.delete(
        'PendingStockUpdates',
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
    } catch (error) {
      logger.e('Error deleting pending stock updates: $error');
      return Future.error("Error deleting pending stock updates: $error");
    }
  }

  @override
  Future<void> setPendingStockUpdateError({
    required int id,
    String? errorMessage,
  }) async {
    try {
      final db = _database!;
      await db.update(
        'PendingStockUpdates',
        {'error_message': errorMessage},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (error) {
      logger.e('Error updating pending stock update error: $error');
      return Future.error("Error updating pending stock update error: $error");
    }
  }

  @override
  Future<void> setPendingStockConflict(List<int> ids, bool hasConflict) async {
    try {
      if (ids.isEmpty) return;
      final db = _database!;
      final placeholders = List.filled(ids.length, '?').join(',');
      await db.update(
        'PendingStockUpdates',
        {'has_conflict': hasConflict ? 1 : 0},
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
    } catch (error) {
      logger.e('Error setting pending stock conflict: $error');
      return Future.error("Error setting pending stock conflict: $error");
    }
  }

  @override
  Future<void> detectPendingStockConflicts(String shopfront) async {
    try {
      final pending = await getPendingStockUpdates(shopfront);
      if (pending.isEmpty) return;

      logger.d('Detecting conflicts for ${pending.length} pending stock updates');

      final List<int> conflictIds = [];
      final List<int> noConflictIds = [];

      for (final entry in pending) {
        final payload = entry.payload;
        final int stockId = (payload['stock_id'] as num?)?.toInt() ??
            (payload['stockId'] as num?)?.toInt() ??
            entry.stockId;

        // Get the pending update's date_modified from payload
        final String? pendingDateModified = payload['date_modified'] as String?;
        logger.d('Stock #$stockId - Pending date_modified: $pendingDateModified');
        
        if (pendingDateModified == null || pendingDateModified.isEmpty) {
          // No date_modified in pending update, skip conflict detection
          logger.d('Stock #$stockId - No date_modified in pending, skipping');
          noConflictIds.add(entry.id);
          continue;
        }

        // Get the current stock from DB
        final db = _database!;
        final rows = await db.query(
          'Stocks',
          columns: ['date_modified'],
          where: 'stock_id = ? AND shopfront = ?',
          whereArgs: [stockId, shopfront],
          limit: 1,
        );

        if (rows.isEmpty) {
          // Stock not found in DB, no conflict
          logger.d('Stock #$stockId - Not found in DB, no conflict');
          noConflictIds.add(entry.id);
          continue;
        }

        final String? dbDateModified = rows.first['date_modified'] as String?;
        logger.d('Stock #$stockId - DB date_modified: $dbDateModified');
        
        if (dbDateModified == null || dbDateModified.isEmpty) {
          // No date_modified in DB, no conflict
          logger.d('Stock #$stockId - No date_modified in DB, no conflict');
          noConflictIds.add(entry.id);
          continue;
        }

        // Parse and compare dates
        final DateTime? pendingDate = DateTime.tryParse(pendingDateModified);
        final DateTime? dbDate = DateTime.tryParse(dbDateModified);

        if (pendingDate == null || dbDate == null) {
          logger.d('Stock #$stockId - Failed to parse dates, no conflict');
          noConflictIds.add(entry.id);
          continue;
        }

        // If DB record was modified after the pending update was created,
        // mark as conflict
        if (dbDate.isAfter(pendingDate)) {
          logger.d('Stock #$stockId - CONFLICT: DB ($dbDateModified) is newer than pending ($pendingDateModified)');
          conflictIds.add(entry.id);
        } else {
          logger.d('Stock #$stockId - No conflict: pending is newer or equal');
          noConflictIds.add(entry.id);
        }
      }

      logger.d('Conflict detection complete: ${conflictIds.length} conflicts, ${noConflictIds.length} ok');

      // Update conflict status
      if (conflictIds.isNotEmpty) {
        await setPendingStockConflict(conflictIds, true);
      }
      if (noConflictIds.isNotEmpty) {
        await setPendingStockConflict(noConflictIds, false);
      }
    } catch (error) {
      logger.e('Error detecting pending stock conflicts: $error');
      // Don't throw - conflict detection failure shouldn't break sync
    }
  }

  @override
  Future<void> applyPendingStockUpdates(String shopfront) async {
    try {
      final pending = await getPendingStockUpdates(shopfront);
      if (pending.isEmpty) return;

      for (final entry in pending) {
        final payload = entry.payload;
        final int stockId = (payload['stock_id'] as num?)?.toInt() ??
            (payload['stockId'] as num?)?.toInt() ??
            entry.stockId;
        final String description = (payload['description'] as String?) ?? '';
        final double sell = (payload['sell'] as num?)?.toDouble() ?? 0.0;
        final String? custom1 = payload['custom1'] as String?;
        final String? custom2 = payload['custom2'] as String?;
        final String? longDesc = payload['longdesc'] as String?;
        final PricingRules? pricingRules = _parsePricingRules(
          payload['pricing_rules'],
        );

        await updateStockDetails(
          stockId: stockId,
          shopfront: shopfront,
          description: description,
          sell: sell,
          custom1: custom1,
          custom2: custom2,
          longDesc: longDesc,
          pricingRules: pricingRules,
        );
      }
    } catch (error) {
      logger.e('Error applying pending stock updates: $error');
      return Future.error("Error applying pending stock updates: $error");
    }
  }

  // ---------------------------------------------------------------------------
  // HELPER: Parse pricing rules from various formats
  // ---------------------------------------------------------------------------

  PricingRules? _parsePricingRules(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return PricingRules.fromJson(payload);
    }
    if (payload is Map) {
      return PricingRules.fromJson(Map<String, dynamic>.from(payload));
    }
    if (payload is String) {
      final trimmed = payload.trim();
      if (trimmed.isEmpty) return null;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          return PricingRules.fromJson(decoded);
        }
        if (decoded is Map) {
          return PricingRules.fromJson(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {}
    }
    return null;
  }

  // ===========================================================================
  // SECTION 9: PENDING CUSTOMER UPDATES (Offline Sync Queue)
  // ===========================================================================
  // Queue system for customer edits made while offline.
  //
  // Features:
  // - Queue customer field updates (address, contact info, etc.)
  // - Store address changes in separate table for complex updates
  // - Merge multiple updates to same customer into single entry
  // - Track sync status and error messages
  // - Detect conflicts when server data is newer
  //
  // Tables:
  // - PendingCustomerUpdates: Main update queue with JSON payload
  // - pending_customer_update_addresses: Address changes for each update
  // ===========================================================================

  @override
  Future<int> addPendingCustomerUpdate({
    required String shopfront,
    required int customerId,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final db = _database!;
      final existing = await db.query(
        'PendingCustomerUpdates',
        where: 'shopfront = ? AND customer_id = ? AND action = ? AND status = 0',
        whereArgs: [shopfront, customerId, action],
        limit: 1,
      );

      final Map<String, dynamic> mergedPayload = Map<String, dynamic>.from(
        payload,
      );

      if (existing.isNotEmpty) {
        final row = existing.first;
        final int id = row['id'] as int;
        final Map<String, dynamic> current = Map<String, dynamic>.from(
          jsonDecode(row['payload_json'] as String) as Map,
        );

        final List<dynamic> currentItems = current['items'] is List
            ? List<dynamic>.from(current['items'] as List)
            : <dynamic>[];
        final List<dynamic> newItems = mergedPayload['items'] is List
            ? List<dynamic>.from(mergedPayload['items'] as List)
            : <dynamic>[];

        final Map<String, dynamic> currentItem = currentItems.isNotEmpty
            ? Map<String, dynamic>.from(currentItems.first as Map)
            : <String, dynamic>{};
        final Map<String, dynamic> newItem = newItems.isNotEmpty
            ? Map<String, dynamic>.from(newItems.first as Map)
            : <String, dynamic>{};

        final Map<String, dynamic> combinedItem = {
          ...currentItem,
          ...newItem,
        };

        if (!newItem.containsKey('addresses') &&
            currentItem.containsKey('addresses')) {
          combinedItem['addresses'] = currentItem['addresses'];
        }

        final Map<String, dynamic> combinedPayload = {
          ...current,
          ...mergedPayload,
          'items': [combinedItem],
        };

        await db.update(
          'PendingCustomerUpdates',
          {
            'payload_json': jsonEncode(combinedPayload),
            'created_at': DateTime.now().toIso8601String(),
            'status': 0,
            'has_conflict': 0,
            'error_message': null,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        await _replacePendingCustomerUpdateAddresses(
          db,
          pendingId: id,
          shopfront: shopfront,
          customerId: customerId,
          payload: combinedPayload,
        );
        return id;
      }

      final int id = await db.insert('PendingCustomerUpdates', {
        'shopfront': shopfront,
        'customer_id': customerId,
        'action': action,
        'payload_json': jsonEncode(mergedPayload),
        'created_at': DateTime.now().toIso8601String(),
        'status': 0,
        'has_conflict': 0,
        'error_message': null,
      });
      await _replacePendingCustomerUpdateAddresses(
        db,
        pendingId: id,
        shopfront: shopfront,
        customerId: customerId,
        payload: mergedPayload,
      );
      return id;
    } catch (error) {
      logger.e('Error saving pending customer update: $error');
      return Future.error("Error saving pending customer update: $error");
    }
  }

  Future<void> _replacePendingCustomerUpdateAddresses(
    Database db, {
    required int pendingId,
    required String shopfront,
    required int customerId,
    required Map<String, dynamic> payload,
  }) async {
    await db.delete(
      'pending_customer_update_addresses',
      where: 'pending_update_id = ?',
      whereArgs: [pendingId],
    );

    final items = payload['items'];
    if (items is! List || items.isEmpty) return;
    final item = Map<String, dynamic>.from(items.first as Map);
    final addresses = item['addresses'];
    if (addresses is! List) return;

    for (final raw in addresses) {
      final map = Map<String, dynamic>.from(raw as Map);
      final int addressId = _readAddressInt(map, 'addressId', 'address_id');
      final int addressNumber =
          _readAddressInt(map, 'addressNumber', 'address_number');
      final int resolvedCustomerId = _readAddressInt(
        map,
        'customerId',
        'customer_id',
        fallback: customerId,
      );

      await db.insert('pending_customer_update_addresses', {
        'pending_update_id': pendingId,
        'shopfront': shopfront,
        'customer_id': resolvedCustomerId,
        'address_id': addressId,
        'address_number': addressNumber,
        'addr1': map['addr1'] as String? ?? '',
        'addr2': map['addr2'] as String? ?? '',
        'addr3': map['addr3'] as String? ?? '',
        'suburb': map['suburb'] as String? ?? '',
        'state': map['state'] as String? ?? '',
        'postcode': map['postcode'] as String? ?? '',
        'country': map['country'] as String? ?? '',
        'phone': map['phone'] as String? ?? '',
        'fax': map['fax'] as String? ?? '',
        'mobile': map['mobile'] as String? ?? '',
        'email': map['email'] as String? ?? '',
      });
    }
  }

  int _readAddressInt(
    Map<String, dynamic> map,
    String primaryKey,
    String fallbackKey, {
    int? fallback,
  }) {
    final value = map[primaryKey] ?? map[fallbackKey];
    if (value is num) return value.toInt();
    return fallback ?? 0;
  }

  @override
  Future<int> getPendingCustomerUpdatesCount(String shopfront) async {
    try {
      final db = _database!;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM PendingCustomerUpdates '
        'WHERE shopfront = ? AND status = 0 AND action = ?',
        [shopfront, 'update'],
      );
      return (result.first['cnt'] as int?) ?? 0;
    } catch (error) {
      logger.e('Error getting pending customer update count: $error');
      return Future.error(
        "Error getting pending customer update count: $error",
      );
    }
  }

  @override
  Future<List<PendingCustomerUpdateVO>> getPendingCustomerUpdates(
    String shopfront, {
    String? action,
    bool? conflictOnly,
  }) async {
    try {
      final db = _database!;
      final where = <String>['shopfront = ?', 'status = 0'];
      final args = <dynamic>[shopfront];

      if (action != null && action.isNotEmpty) {
        where.add('action = ?');
        args.add(action);
      }
      if (conflictOnly != null) {
        where.add('has_conflict = ?');
        args.add(conflictOnly ? 1 : 0);
      }

      final rows = await db.query(
        'PendingCustomerUpdates',
        where: where.join(' AND '),
        whereArgs: args,
        orderBy: 'created_at DESC',
      );

      return rows.map((row) {
        final payload = jsonDecode(row['payload_json'] as String);
        return PendingCustomerUpdateVO(
          id: row['id'] as int,
          shopfront: row['shopfront'] as String,
          customerId: row['customer_id'] as int,
          action: row['action'] as String,
          payload: Map<String, dynamic>.from(payload as Map),
          createdAt: row['created_at'] as String,
          hasConflict: (row['has_conflict'] as int? ?? 0) == 1,
          errorMessage: row['error_message'] as String?,
        );
      }).toList();
    } catch (error) {
      logger.e('Error loading pending customer updates: $error');
      return Future.error("Error loading pending customer updates: $error");
    }
  }

  @override
  Future<void> deletePendingCustomerUpdates(List<int> ids) async {
    try {
      if (ids.isEmpty) return;
      final db = _database!;
      final placeholders = List.filled(ids.length, '?').join(',');
      await db.delete(
        'pending_customer_update_addresses',
        where: 'pending_update_id IN ($placeholders)',
        whereArgs: ids,
      );
      await db.delete(
        'PendingCustomerUpdates',
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
    } catch (error) {
      logger.e('Error deleting pending customer updates: $error');
      return Future.error("Error deleting pending customer updates: $error");
    }
  }

  @override
  Future<void> setPendingCustomerConflict(
    List<int> ids,
    bool hasConflict,
  ) async {
    try {
      if (ids.isEmpty) return;
      final db = _database!;
      final placeholders = List.filled(ids.length, '?').join(',');
      await db.update(
        'PendingCustomerUpdates',
        {'has_conflict': hasConflict ? 1 : 0},
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
    } catch (error) {
      logger.e('Error updating pending customer conflict flag: $error');
      return Future.error(
        "Error updating pending customer conflict flag: $error",
      );
    }
  }

  @override
  Future<void> updatePendingCustomerPayload({
    required int id,
    required int customerId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final db = _database!;
      await db.update(
        'PendingCustomerUpdates',
        {
          'customer_id': customerId,
          'payload_json': jsonEncode(payload),
          'has_conflict': 0,
          'error_message': null,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (error) {
      logger.e('Error updating pending customer payload: $error');
      return Future.error("Error updating pending customer payload: $error");
    }
  }

  @override
  Future<void> setPendingCustomerUpdateError({
    required int id,
    String? errorMessage,
  }) async {
    try {
      final db = _database!;
      await db.update(
        'PendingCustomerUpdates',
        {'error_message': errorMessage},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (error) {
      logger.e('Error updating pending customer update error: $error');
      return Future.error(
        "Error updating pending customer update error: $error",
      );
    }
  }

  @override
  Future<void> detectPendingCustomerConflicts(String shopfront) async {
    try {
      final pending = await getPendingCustomerUpdates(shopfront, action: 'update');
      if (pending.isEmpty) return;

      logger.d('Detecting conflicts for ${pending.length} pending customer updates');

      final List<int> conflictIds = [];
      final List<int> noConflictIds = [];

      for (final entry in pending) {
        final payload = entry.payload;
        
        // Extract item from payload - date_modified is inside items[0]
        final items = payload['items'];
        final Map<String, dynamic>? item = (items is List && items.isNotEmpty)
            ? Map<String, dynamic>.from(items.first as Map)
            : null;
        
        final int customerId = (item?['customer_id'] as num?)?.toInt() ??
          (item?['customerId'] as num?)?.toInt() ??
          (payload['customer_id'] as num?)?.toInt() ??
          (payload['customerId'] as num?)?.toInt() ??
          entry.customerId;
        final String barcode =
          (item?['barcode'] as String?) ??
          (payload['barcode'] as String?) ??
          '';

        // Get the pending update's date_modified from payload item
        final String? pendingDateModified = item?['date_modified'] as String?;
        logger.d('Customer #$customerId - Pending date_modified: $pendingDateModified');
        
        if (pendingDateModified == null || pendingDateModified.isEmpty) {
          // No date_modified in pending update, skip conflict detection
          logger.d('Customer #$customerId - No date_modified in pending, skipping');
          noConflictIds.add(entry.id);
          continue;
        }

        // Get the current customer from DB
        final db = _database!;
        final List<Map<String, Object?>> rows;
        if (customerId > 0) {
          rows = await db.query(
            'Customers',
            columns: ['date_modified'],
            where: 'customer_id = ? AND shopfront = ?',
            whereArgs: [customerId, shopfront],
            limit: 1,
          );
        } else if (barcode.trim().isNotEmpty) {
          rows = await db.query(
            'Customers',
            columns: ['date_modified'],
            where: 'barcode = ? AND shopfront = ?',
            whereArgs: [barcode.trim(), shopfront],
            limit: 1,
          );
        } else {
          rows = const [];
        }

        if (rows.isEmpty) {
          // Customer not found in DB, no conflict
          logger.d('Customer #$customerId - Not found in DB, no conflict');
          noConflictIds.add(entry.id);
          continue;
        }

        final String? dbDateModified = rows.first['date_modified'] as String?;
        logger.d('Customer #$customerId - DB date_modified: $dbDateModified');
        
        if (dbDateModified == null || dbDateModified.isEmpty) {
          // No date_modified in DB, no conflict
          logger.d('Customer #$customerId - No date_modified in DB, no conflict');
          noConflictIds.add(entry.id);
          continue;
        }

        // Parse and compare dates
        final DateTime? pendingDate = DateTime.tryParse(pendingDateModified);
        final DateTime? dbDate = DateTime.tryParse(dbDateModified);

        if (pendingDate == null || dbDate == null) {
          logger.d('Customer #$customerId - Failed to parse dates, no conflict');
          noConflictIds.add(entry.id);
          continue;
        }

        // If DB record was modified after the pending update was created,
        // mark as conflict
        if (dbDate.isAfter(pendingDate)) {
          logger.d('Customer #$customerId - CONFLICT: DB ($dbDateModified) is newer than pending ($pendingDateModified)');
          conflictIds.add(entry.id);
        } else {
          logger.d('Customer #$customerId - No conflict: pending is newer or equal');
          noConflictIds.add(entry.id);
        }
      }

      logger.d('Conflict detection complete: ${conflictIds.length} conflicts, ${noConflictIds.length} ok');

      // Update conflict status
      if (conflictIds.isNotEmpty) {
        await setPendingCustomerConflict(conflictIds, true);
      }
      if (noConflictIds.isNotEmpty) {
        await setPendingCustomerConflict(noConflictIds, false);
      }
    } catch (error) {
      logger.e('Error detecting pending customer conflicts: $error');
      // Don't throw - conflict detection failure shouldn't break sync
    }
  }

  @override
  Future<void> applyPendingCustomerUpdates(String shopfront) async {
    try {
      final pending = await getPendingCustomerUpdates(shopfront);
      if (pending.isEmpty) return;

      for (final entry in pending) {
        if (entry.action != 'update') {
          continue;
        }
        final payload = entry.payload;
        final items = payload['items'];
        if (items is! List || items.isEmpty) continue;
        final item = Map<String, dynamic>.from(items.first as Map);

        await _updateCustomerFromPayload(item, shopfront);
      }
    } catch (error) {
      logger.e('Error applying pending customer updates: $error');
      return Future.error("Error applying pending customer updates: $error");
    }
  }

  // ===========================================================================
  // SECTION 10: PENDING CUSTOMER CREATIONS (Offline Sync Queue)
  // ===========================================================================
  // Queue for new customers created while offline.
  //
  // Features:
  // - Queue new customer records with all details and addresses
  // - Temporary local IDs that get renewed before server sync
  // - renewPendingCustomerCreationIds() assigns proper sequential IDs
  // - Track creation status and any sync errors
  //
  // Workflow:
  // 1. User creates customer offline -> addPendingCustomerCreation()
  // 2. Before sync -> renewPendingCustomerCreationIds() assigns IDs
  // 3. Sync to server -> if success, delete from queue
  // 4. On failure -> error stored for retry
  // ===========================================================================

  @override
  Future<int> addPendingCustomerCreation({
    required String shopfront,
    required int customerId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final db = _database!;
      final existing = await db.query(
        'PendingCustomerCreations',
        where: 'shopfront = ? AND customer_id = ? AND status = 0',
        whereArgs: [shopfront, customerId],
        limit: 1,
      );

      final Map<String, dynamic> mergedPayload = Map<String, dynamic>.from(
        payload,
      );

      if (existing.isNotEmpty) {
        final row = existing.first;
        final int id = row['id'] as int;
        final Map<String, dynamic> current = Map<String, dynamic>.from(
          jsonDecode(row['payload_json'] as String) as Map,
        );
        final Map<String, dynamic> combined = {
          ...current,
          ...mergedPayload,
        };

        await db.update(
          'PendingCustomerCreations',
          {
            'payload_json': jsonEncode(combined),
            'created_at': DateTime.now().toIso8601String(),
            'status': 0,
            'error_message': null,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        await _replacePendingCustomerCreationAddresses(
          db,
          pendingId: id,
          shopfront: shopfront,
          customerId: customerId,
          payload: combined,
        );
        return id;
      }

      final int id = await db.insert('PendingCustomerCreations', {
        'shopfront': shopfront,
        'customer_id': customerId,
        'payload_json': jsonEncode(mergedPayload),
        'created_at': DateTime.now().toIso8601String(),
        'status': 0,
        'error_message': null,
      });
      await _replacePendingCustomerCreationAddresses(
        db,
        pendingId: id,
        shopfront: shopfront,
        customerId: customerId,
        payload: mergedPayload,
      );
      return id;
    } catch (error) {
      logger.e('Error saving pending customer creation: $error');
      return Future.error("Error saving pending customer creation: $error");
    }
  }

  Future<void> _replacePendingCustomerCreationAddresses(
    Database db, {
    required int pendingId,
    required String shopfront,
    required int customerId,
    required Map<String, dynamic> payload,
  }) async {
    await db.delete(
      'pending_customer_creation_addresses',
      where: 'pending_creation_id = ?',
      whereArgs: [pendingId],
    );

    final items = payload['items'];
    if (items is! List || items.isEmpty) return;
    final item = Map<String, dynamic>.from(items.first as Map);
    final addresses = item['addresses'];
    if (addresses is! List) return;

    for (final raw in addresses) {
      final map = Map<String, dynamic>.from(raw as Map);
      final int addressId = _readAddressInt(map, 'addressId', 'address_id');
      final int addressNumber =
          _readAddressInt(map, 'addressNumber', 'address_number');
      final int resolvedCustomerId = _readAddressInt(
        map,
        'customerId',
        'customer_id',
        fallback: customerId,
      );

      await db.insert('pending_customer_creation_addresses', {
        'pending_creation_id': pendingId,
        'shopfront': shopfront,
        'customer_id': resolvedCustomerId,
        'address_id': addressId,
        'address_number': addressNumber,
        'addr1': map['addr1'] as String? ?? '',
        'addr2': map['addr2'] as String? ?? '',
        'addr3': map['addr3'] as String? ?? '',
        'suburb': map['suburb'] as String? ?? '',
        'state': map['state'] as String? ?? '',
        'postcode': map['postcode'] as String? ?? '',
        'country': map['country'] as String? ?? '',
        'phone': map['phone'] as String? ?? '',
        'fax': map['fax'] as String? ?? '',
        'mobile': map['mobile'] as String? ?? '',
        'email': map['email'] as String? ?? '',
      });
    }
  }

  @override
  Future<int> getPendingCustomerCreationsCount(String shopfront) async {
    try {
      final db = _database!;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM PendingCustomerCreations '
        'WHERE shopfront = ? AND status = 0',
        [shopfront],
      );
      return (result.first['cnt'] as int?) ?? 0;
    } catch (error) {
      logger.e('Error getting pending customer creation count: $error');
      return Future.error(
        "Error getting pending customer creation count: $error",
      );
    }
  }

  @override
  Future<List<PendingCustomerCreationVO>> getPendingCustomerCreations(
    String shopfront,
  ) async {
    try {
      final db = _database!;
      final rows = await db.query(
        'PendingCustomerCreations',
        where: 'shopfront = ? AND status = 0',
        whereArgs: [shopfront],
        orderBy: 'created_at DESC',
      );

      return rows.map((row) {
        final payload = jsonDecode(row['payload_json'] as String);
        return PendingCustomerCreationVO(
          id: row['id'] as int,
          shopfront: row['shopfront'] as String,
          customerId: row['customer_id'] as int,
          payload: Map<String, dynamic>.from(payload as Map),
          createdAt: row['created_at'] as String,
          errorMessage: row['error_message'] as String?,
        );
      }).toList();
    } catch (error) {
      logger.e('Error loading pending customer creations: $error');
      return Future.error("Error loading pending customer creations: $error");
    }
  }

  @override
  Future<void> deletePendingCustomerCreations(List<int> ids) async {
    try {
      if (ids.isEmpty) return;
      final db = _database!;
      final placeholders = List.filled(ids.length, '?').join(',');
      await db.delete(
        'pending_customer_creation_addresses',
        where: 'pending_creation_id IN ($placeholders)',
        whereArgs: ids,
      );
      await db.delete(
        'PendingCustomerCreations',
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
    } catch (error) {
      logger.e('Error deleting pending customer creations: $error');
      return Future.error("Error deleting pending customer creations: $error");
    }
  }

  @override
  Future<void> updatePendingCustomerCreationPayload({
    required int id,
    required int customerId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final db = _database!;
      await db.update(
        'PendingCustomerCreations',
        {
          'customer_id': customerId,
          'payload_json': jsonEncode(payload),
          'error_message': null,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (error) {
      logger.e('Error updating pending customer creation payload: $error');
      return Future.error(
        "Error updating pending customer creation payload: $error",
      );
    }
  }

  @override
  Future<void> setPendingCustomerCreationError({
    required int id,
    String? errorMessage,
  }) async {
    try {
      final db = _database!;
      await db.update(
        'PendingCustomerCreations',
        {'error_message': errorMessage},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (error) {
      logger.e('Error updating pending customer creation error: $error');
      return Future.error(
        "Error updating pending customer creation error: $error",
      );
    }
  }

  @override
  Future<void> renewPendingCustomerCreationIds(String shopfront) async {
    try {
      final db = _database!;
      final maxResult = await db.rawQuery(
        'SELECT MAX(customer_id) as max_id FROM Customers WHERE shopfront = ?',
        [shopfront],
      );
      int maxId = (maxResult.first['max_id'] as int?) ?? 0;
      final maxAddressResult = await db.rawQuery(
        'SELECT MAX(address_id) as max_id FROM CustomerAddresses '
        'WHERE shopfront = ?',
        [shopfront],
      );
      int nextAddressId = (maxAddressResult.first['max_id'] as int?) ?? 0;

      final rows = await db.query(
        'PendingCustomerCreations',
        where: 'shopfront = ? AND status = 0',
        whereArgs: [shopfront],
        orderBy: 'created_at ASC',
      );

      if (rows.isEmpty) return;

      for (final row in rows) {
        maxId += 1;
        final payload = jsonDecode(row['payload_json'] as String);
        if (payload is! Map) continue;
        final payloadMap = Map<String, dynamic>.from(payload);
        final items = payloadMap['items'];
        if (items is! List || items.isEmpty) continue;

        final item = Map<String, dynamic>.from(items.first as Map);
        item['customerId'] = maxId;
        item['customer_id'] = maxId;

        final addressRows = await db.query(
          'pending_customer_creation_addresses',
          where: 'pending_creation_id = ?',
          whereArgs: [row['id'] as int],
          orderBy: 'address_number ASC, id ASC',
        );

        final Map<int, int> addressNumberToId = {};
        for (final addrRow in addressRows) {
          nextAddressId += 1;
          final int addressNumber =
              (addrRow['address_number'] as int?) ?? 0;
          addressNumberToId[addressNumber] = nextAddressId;
          await db.update(
            'pending_customer_creation_addresses',
            {
              'customer_id': maxId,
              'address_id': nextAddressId,
            },
            where: 'id = ?',
            whereArgs: [addrRow['id'] as int],
          );
        }

        if (item['addresses'] is List) {
          final addresses = item['addresses'] as List;
          for (var i = 0; i < addresses.length; i++) {
            final addr = Map<String, dynamic>.from(addresses[i] as Map);
            final int addressNumber = _readAddressInt(
              addr,
              'addressNumber',
              'address_number',
              fallback: i + 1,
            );
            final int? newAddressId = addressNumberToId[addressNumber];
            if (newAddressId != null) {
              addr['addressId'] = newAddressId;
              addr['address_id'] = newAddressId;
            }
            addr['customerId'] = maxId;
            addr['customer_id'] = maxId;
            addresses[i] = addr;
          }
          item['addresses'] = addresses;
        }

        payloadMap['items'] = [item];

        await db.update(
          'PendingCustomerCreations',
          {
            'customer_id': maxId,
            'payload_json': jsonEncode(payloadMap),
          },
          where: 'id = ?',
          whereArgs: [row['id'] as int],
        );
      }
    } catch (error) {
      logger.e('Error renewing pending customer creation ids: $error');
      return Future.error(
        "Error renewing pending customer creation ids: $error",
      );
    }
  }

  // ---------------------------------------------------------------------------
  // CUSTOMER PAYLOAD HELPERS
  // Used when applying pending updates/creations to local DB
  // ---------------------------------------------------------------------------

  Future<void> _insertCustomerFromPayload(
    Map<String, dynamic> item,
    String shopfront,
  ) async {
    final customer = CustomerVO.fromApiItem(item);
    await insertCustomers([customer], shopfront);
  }

  Future<void> _updateCustomerFromPayload(
    Map<String, dynamic> item,
    String shopfront,
  ) async {
    final int customerId = (item['customerId'] as num?)?.toInt() ??
        (item['customer_id'] as num?)?.toInt() ??
        0;

    final existing = await getCustomerById(customerId, shopfront);
    if (existing == null) {
      final customer = CustomerVO.fromApiItem(item);
      await insertCustomers([customer], shopfront);
      return;
    }

    final dynamic rawDateModified =
      item['date_modified'] ?? item['dateModified'];
    final String incomingDateModified = rawDateModified == null
      ? ''
      : rawDateModified.toString().trim();
    final String resolvedDateModified = incomingDateModified.isNotEmpty
      ? incomingDateModified
      : existing.dateModified;

    final Map<String, dynamic> updateData = {
      'surname': item['surname'] ?? existing.surname,
      'given_names': item['givenNames'] ?? item['given_names'] ?? existing.givenNames,
      'grade': item['grade'] ?? existing.grade,
      'company': item['company'] ?? existing.company,
      'position': item['position'] ?? existing.position,
      'salutation': item['salutation'] ?? existing.salutation,
      'status': _asDbBool(item['status'] ?? existing.status),
      'inactive': _asDbBool(item['inactive'] ?? existing.inactive),
      'account': _asDbBool(item['account'] ?? existing.account),
      'overseas': _asDbBool(item['overseas'] ?? existing.overseas),
      'abn': item['abn'] ?? existing.abn,
      'addr1': item['addr1'] ?? existing.addr1,
      'addr2': item['addr2'] ?? existing.addr2,
      'addr3': item['addr3'] ?? existing.addr3,
      'suburb': item['suburb'] ?? existing.suburb,
      'state': item['state'] ?? existing.state,
      'postcode': item['postcode'] ?? existing.postcode,
      'country': item['country'] ?? existing.country,
      'phone': item['phone'] ?? existing.phone,
      'fax': item['fax'] ?? existing.fax,
      'mobile': item['mobile'] ?? existing.mobile,
      'email': item['email'] ?? existing.email,
      'opened_id': item['openedId'] ?? item['opened_id'] ?? existing.openedId,
      'owner_id': item['ownerId'] ?? item['owner_id'] ?? existing.ownerId,
      'from_eom': _asDbBool(item['fromEOM'] ?? item['from_eom'] ?? existing.fromEOM),
      'days': item['days'] ?? existing.days,
      'limit': item['limit'] ?? existing.limit,
      'default_delivery_address':
          item['defaultDeliveryAddress'] ?? existing.defaultDeliveryAddress,
      'document_delivery_type':
          item['documentDeliveryType'] ?? existing.documentDeliveryType,
      'custom1': item['custom1'] ?? existing.custom1,
      'custom2': item['custom2'] ?? existing.custom2,
      'notes': item['notes'] ?? existing.notes,
      'comments': item['comments'] ?? existing.comments,
      // Preserve server date_modified to avoid flagging local edits as newer.
      'date_modified': resolvedDateModified,
    };

    final db = _database!;
    await db.update(
      'Customers',
      updateData,
      where: 'customer_id = ? AND shopfront = ?',
      whereArgs: [customerId, shopfront],
    );

    if (item['addresses'] is List) {
      final addresses = item['addresses'] as List;
      for (final raw in addresses) {
        final map = Map<String, dynamic>.from(raw as Map);
        await db.insert(
          'CustomerAddresses',
          {
            'address_id': map['addressId'] ?? 0,
            'customer_id': map['customerId'] ?? customerId,
            'shopfront': shopfront,
            'address_number': map['addressNumber'] ?? 0,
            'addr1': map['addr1'] ?? '',
            'addr2': map['addr2'] ?? '',
            'addr3': map['addr3'] ?? '',
            'suburb': map['suburb'] ?? '',
            'state': map['state'] ?? '',
            'postcode': map['postcode'] ?? '',
            'country': map['country'] ?? '',
            'phone': map['phone'] ?? '',
            'fax': map['fax'] ?? '',
            'mobile': map['mobile'] ?? '',
            'email': map['email'] ?? '',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  /// Converts various boolean representations to SQLite integer (0 or 1)
  int _asDbBool(dynamic value) {
    if (value is bool) return value ? 1 : 0;
    if (value is num) return value != 0 ? 1 : 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return (lower == 'true' || lower == '1') ? 1 : 0;
    }
    return 0;
  }

  // ===========================================================================
  // SECTION 8: CUSTOMER MASTER DATA (Customer Screen)
  // ===========================================================================
  // Manages the local copy of customer records synced from the server.
  //
  // Features:
  // - Bulk insert/update customers with addresses
  // - Multi-column search (barcode, name, company, phone, email, address)
  // - Paginated search with sorting and filtering
  // - Get next available customer ID for offline creation
  // - Generate numeric barcodes for new customers
  // - Check for duplicate barcodes before creation
  //
  // Structure:
  // - Customers: Main customer record
  // - CustomerAddresses: Multiple addresses per customer
  //
  // Search priority: Barcode > Given Names > Surname > Company > Phone > Email
  // ===========================================================================

  @override
  Future<void> insertCustomers(
    List<CustomerVO> customers,
    String shopfront,
  ) async {
    try {
      final db = _database!;

      await db.transaction((txn) async {
        final batch = txn.batch();

        for (var customer in customers) {
          batch.insert(
            'Customers',
            customer.toJson(shopfront),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // Insert addresses
          for (var address in customer.addresses) {
            batch.insert('CustomerAddresses', {
              'address_id': address.addressId,
              'customer_id': address.customerId,
              'shopfront': shopfront,
              'address_number': address.addressNumber,
              'addr1': address.addr1,
              'addr2': address.addr2,
              'addr3': address.addr3,
              'suburb': address.suburb,
              'state': address.state,
              'postcode': address.postcode,
              'country': address.country,
              'phone': address.phone,
              'fax': address.fax,
              'mobile': address.mobile,
              'email': address.email,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
        await batch.commit(noResult: true);
      });
      logger.d(
        'Successfully saved ${customers.length} customers for $shopfront',
      );
    } catch (error) {
      logger.e('Error saving customers for $shopfront: $error');
      return Future.error("Error saving customers: $error");
    }
  }

  @override
  Future<PaginatedCustomerResult> searchAndSortCustomers({
    required String shopfront,
    required String query,
    required String filterColumn,
    required String sortColumn,
    required bool ascending,
    required int limit,
    required int offset,
    FilterCriteria? filters,
    SearchMode searchMode = SearchMode.partial,
  }) async {
    try {
      final db = _database!;
      final String q = query.trim();

      const allowedColumns = <String>{
        'customer_id',
        'shopfront',
        'barcode',
        'surname',
        'given_names',
        'company',
        'email',
        'phone',
        'mobile',
        'suburb',
        'state',
        'postcode',
        'date_modified',
      };

      final String safeSortColumn = allowedColumns.contains(sortColumn)
          ? sortColumn
          : 'surname';

      final String orderBy = "$safeSortColumn ${ascending ? 'ASC' : 'DESC'}";

      String baseWhere = 'shopfront = ?';
      final List<dynamic> baseArgs = [shopfront];

      // Add filters if provided
      if (filters != null) {
        if (filters.custom1 != null && filters.custom1!.isNotEmpty) {
          baseWhere += ' AND custom1 LIKE ?';
          baseArgs.add('%${filters.custom1!}%');
        }
        if (filters.custom2 != null && filters.custom2!.isNotEmpty) {
          baseWhere += ' AND custom2 LIKE ?';
          baseArgs.add('%${filters.custom2!}%');
        }
        if (filters.state != null && filters.state!.isNotEmpty) {
          baseWhere += ' AND state = ?';
          baseArgs.add(filters.state!);
        }
        if (filters.suburb != null && filters.suburb!.isNotEmpty) {
          baseWhere += ' AND suburb = ?';
          baseArgs.add(filters.suburb!);
        }
        if (filters.postcode != null && filters.postcode!.isNotEmpty) {
          baseWhere += ' AND postcode = ?';
          baseArgs.add(filters.postcode!);
        }
      }

      Future<PaginatedCustomerResult> runQuery({
        required String whereClause,
        required List<dynamic> args,
        String? matchedColumn,
      }) async {
        final countFuture = db.rawQuery(
          'SELECT COUNT(*) as count FROM Customers WHERE $whereClause',
          args,
        );

        final dataFuture = db.query(
          'Customers',
          where: whereClause,
          whereArgs: args,
          orderBy: orderBy,
          limit: limit,
          offset: offset,
        );

        final results = await Future.wait([dataFuture, countFuture]);

        final rows = results[0] as List<Map<String, dynamic>>;
        final int count =
            Sqflite.firstIntValue(results[1] as List<Map<String, dynamic>>) ??
            0;

        // Load addresses for each customer
        final List<CustomerVO> customers = [];
        for (final row in rows) {
          final customerId = row['customer_id'] as int;
          final addresses = await _getCustomerAddresses(
            db,
            customerId,
            shopfront,
          );
          customers.add(_customerFromRow(row, addresses));
        }

        // Build matched fields map
        final Map<int, String> matchedFields = {};
        if (matchedColumn != null && q.isNotEmpty) {
          for (var customer in customers) {
            matchedFields[customer.customerId] = matchedColumn;
          }
        }

        return PaginatedCustomerResult(
          customers: customers,
          totalCount: count,
          hasMore: offset + customers.length < count,
          matchedFields: matchedFields,
        );
      }

      if (q.isEmpty) {
        return runQuery(whereClause: baseWhere, args: baseArgs, matchedColumn: null);
      }

      // Determine search pattern based on search mode
      final String searchPattern = searchMode == SearchMode.prefix
          ? '$q%'  // Prefix search: matches start of string
          : '%$q%'; // Partial search: matches anywhere in string

      // Search priority: barcode → given_names → surname → company → phone → fax → mobile → email
      final searchPriority = <String>[
        'barcode',
        'given_names',
        'surname',
        'company',
        'phone',
        'fax',
        'mobile',
        'email',
      ];

      bool matchesValue(String value) {
        final normalized = value.toLowerCase();
        final needle = q.toLowerCase();
        if (searchMode == SearchMode.prefix) {
          return normalized.startsWith(needle);
        }
        return normalized.contains(needle);
      }

      String? matchedColumnForRow(Map<String, dynamic> row) {
        for (final column in searchPriority) {
          final value = row[column];
          if (value != null && matchesValue(value.toString())) {
            return column;
          }
        }
        return null;
      }

      final matchClause = searchPriority.map((col) => '$col LIKE ?').join(' OR ');
      final whereClause = '$baseWhere AND ($matchClause)';
      final whereArgs = [
        ...baseArgs,
        ...List.filled(searchPriority.length, searchPattern),
      ];

      final orderCase = searchPriority
          .asMap()
          .entries
          .map((entry) => 'WHEN ${entry.value} LIKE ? THEN ${entry.key}')
          .join(' ');
      final orderedBy =
          'CASE $orderCase ELSE ${searchPriority.length} END, $safeSortColumn ${ascending ? 'ASC' : 'DESC'}';

      final countFuture = db.rawQuery(
        'SELECT COUNT(*) as count FROM Customers WHERE $whereClause',
        whereArgs,
      );

      final dataFuture = db.rawQuery(
        'SELECT * FROM Customers WHERE $whereClause ORDER BY $orderedBy LIMIT ? OFFSET ?',
        [
          ...whereArgs,
          ...List.filled(searchPriority.length, searchPattern),
          limit,
          offset,
        ],
      );

      final results = await Future.wait([dataFuture, countFuture]);
      final rows = results[0] as List<Map<String, dynamic>>;
      final int count =
          Sqflite.firstIntValue(results[1] as List<Map<String, dynamic>>) ?? 0;

      final List<CustomerVO> customers = [];
      for (final row in rows) {
        final customerId = row['customer_id'] as int;
        final addresses = await _getCustomerAddresses(
          db,
          customerId,
          shopfront,
        );
        customers.add(_customerFromRow(row, addresses));
      }

      final Map<int, String> matchedFields = {};
      for (var i = 0; i < rows.length; i++) {
        final matchedColumn = matchedColumnForRow(rows[i]);
        if (matchedColumn != null) {
          matchedFields[customers[i].customerId] = matchedColumn;
        }
      }

      return PaginatedCustomerResult(
        customers: customers,
        totalCount: count,
        hasMore: offset + customers.length < count,
        matchedFields: matchedFields,
      );
    } catch (error) {
      logger.e('Error searching customers: $error');
      return Future.error(error);
    }
  }

  Future<List<CustomerAddressVO>> _getCustomerAddresses(
    Database db,
    int customerId,
    String shopfront,
  ) async {
    final rows = await db.query(
      'CustomerAddresses',
      where: 'customer_id = ? AND shopfront = ?',
      whereArgs: [customerId, shopfront],
    );

    return rows
        .map(
          (row) => CustomerAddressVO(
            addressId: row['address_id'] as int,
            customerId: row['customer_id'] as int,
            addressNumber: row['address_number'] as int,
            addr1: row['addr1'] as String? ?? '',
            addr2: row['addr2'] as String? ?? '',
            addr3: row['addr3'] as String? ?? '',
            suburb: row['suburb'] as String? ?? '',
            state: row['state'] as String? ?? '',
            postcode: row['postcode'] as String? ?? '',
            country: row['country'] as String? ?? '',
            phone: row['phone'] as String? ?? '',
            fax: row['fax'] as String? ?? '',
            mobile: row['mobile'] as String? ?? '',
            email: row['email'] as String? ?? '',
          ),
        )
        .toList();
  }

  /// Converts a database row to CustomerVO with addresses
  CustomerVO _customerFromRow(
    Map<String, dynamic> row,
    List<CustomerAddressVO> addresses,
  ) {
    return CustomerVO(
      customerId: row['customer_id'] as int,
      barcode: row['barcode'] as String? ?? '',
      grade: row['grade'] as int? ?? 0,
      notes: row['notes'] as String? ?? '',
      comments: row['comments'] as String? ?? '',
      status: row['status'] == 1,
      custom1: row['custom1'] as String? ?? '',
      custom2: row['custom2'] as String? ?? '',
      inactive: row['inactive'] == 1,
      dateModified: row['date_modified'] as String? ?? '',
      surname: row['surname'] as String? ?? '',
      givenNames: row['given_names'] as String? ?? '',
      position: row['position'] as String? ?? '',
      company: row['company'] as String? ?? '',
      salutation: row['salutation'] as String? ?? '',
      account: row['account'] == 1,
      openedId: row['opened_id'] as int? ?? 0,
      ownerId: row['owner_id'] as int? ?? 0,
      limit: row['limit'] as num? ?? 0,
      days: row['days'] as int? ?? 0,
      fromEOM: row['from_eom'] == 1,
      addr1: row['addr1'] as String? ?? '',
      addr2: row['addr2'] as String? ?? '',
      addr3: row['addr3'] as String? ?? '',
      suburb: row['suburb'] as String? ?? '',
      state: row['state'] as String? ?? '',
      postcode: row['postcode'] as String? ?? '',
      country: row['country'] as String? ?? '',
      phone: row['phone'] as String? ?? '',
      fax: row['fax'] as String? ?? '',
      mobile: row['mobile'] as String? ?? '',
      email: row['email'] as String? ?? '',
      abn: row['abn'] as String? ?? '',
      overseas: row['overseas'] == 1,
      external: row['external'] == 1,
      dateCreated: row['date_created'] as String? ?? '',
      isBarcodePrinted: row['is_barcode_printed'] == 1,
      documentDeliveryType: row['document_delivery_type'] as int? ?? 0,
      groupEmailExclusionId: row['group_email_exclusion_id'] as int? ?? 0,
      defaultDeliveryAddress: row['default_delivery_address'] as int? ?? 1,
      addresses: addresses,
    );
  }

  @override
  Future<List<String>> getDistinctCustomerValues(
    String columnName,
    String shopfront,
  ) async {
    try {
      final db = _database!;

      final List<Map<String, dynamic>> result = await db.rawQuery(
        '''
      SELECT DISTINCT $columnName 
      FROM Customers 
      WHERE shopfront = ? 
        AND $columnName IS NOT NULL 
        AND $columnName != '' 
      ORDER BY $columnName ASC
    ''',
        [shopfront],
      );

      return result.map((row) => row[columnName] as String).toList();
    } catch (error) {
      logger.e(
        'Error fetching distinct $columnName for customers in $shopfront: $error',
      );
      return [];
    }
  }

  @override
  Future<CustomerVO?> getCustomerById(int customerId, String shopfront) async {
    try {
      final db = _database!;
      final result = await db.query(
        'Customers',
        where: 'customer_id = ? AND shopfront = ?',
        whereArgs: [customerId, shopfront],
        limit: 1,
      );

      if (result.isEmpty) {
        return null;
      }

      final addresses = await _getCustomerAddresses(db, customerId, shopfront);
      return _customerFromRow(result.first, addresses);
    } catch (error) {
      logger.e('Error getting customer by ID in $shopfront: $error');
      return Future.error("Error getting customer: $error");
    }
  }

  @override
  Future<SyncMetadata> getCustomerSyncMetadata(String shopfront) async {
    try {
      final db = _database!;
      final result = await db.rawQuery(
        'SELECT COUNT(*) AS count, '
        'MIN(customer_id) AS min_id, '
        'MAX(customer_id) AS max_id, '
        'COALESCE(SUM(customer_id), 0) AS checksum '
        'FROM Customers WHERE shopfront = ?',
        [shopfront],
      );

      final row = result.isNotEmpty ? result.first : <String, Object?>{};
      final count = (row['count'] as num?)?.toInt() ?? 0;
      final minId = (row['min_id'] as num?)?.toInt() ?? 0;
      final maxId = (row['max_id'] as num?)?.toInt() ?? 0;
      final checksum = (row['checksum'] as num?)?.toInt() ?? 0;

      return SyncMetadata(
        count: count,
        minId: minId,
        maxId: maxId,
        checksum: checksum,
      );
    } catch (error) {
      logger.e('Error getting customer metadata for $shopfront: $error');
      return Future.error("Error getting customer metadata: $error");
    }
  }

  @override
  Future<List<int>> getCustomerIdsInRange({
    required String shopfront,
    required int fromId,
    required int toId,
  }) async {
    try {
      if (toId < fromId) return [];
      final db = _database!;
      final rows = await db.query(
        'Customers',
        columns: ['customer_id'],
        where: 'shopfront = ? AND customer_id BETWEEN ? AND ?',
        whereArgs: [shopfront, fromId, toId],
        orderBy: 'customer_id ASC',
      );
      return rows
          .map((row) => (row['customer_id'] as num).toInt())
          .toList();
    } catch (error) {
      logger.e('Error getting customer ids for $shopfront: $error');
      return Future.error("Error getting customer ids: $error");
    }
  }

  @override
  Future<CustomerSearchResult> getCustomerBySearch(
    String query,
    String shopfront,
  ) async {
    try {
      final db = _database!;
      final String q = query.trim();

      if (q.isEmpty) {
        return CustomerSearchResult.none();
      }

      // Search priority: barcode → surname+givenNames → company → phone/mobile/fax → email → addr1/suburb/postcode

      // 1. Exact barcode match
      var results = await db.query(
        'Customers',
        where: 'shopfront = ? AND barcode = ? COLLATE NOCASE',
        whereArgs: [shopfront, q],
        limit: 10,
      );

      // 2. Partial barcode match
      if (results.isEmpty) {
        results = await db.query(
          'Customers',
          where: 'shopfront = ? AND barcode LIKE ?',
          whereArgs: [shopfront, '%$q%'],
          limit: 10,
        );
      }

      // 3. Name search (surname or given_names)
      if (results.isEmpty) {
        results = await db.query(
          'Customers',
          where: 'shopfront = ? AND (surname LIKE ? OR given_names LIKE ?)',
          whereArgs: [shopfront, '%$q%', '%$q%'],
          limit: 10,
        );
      }

      // 4. Company search
      if (results.isEmpty) {
        results = await db.query(
          'Customers',
          where: 'shopfront = ? AND company LIKE ?',
          whereArgs: [shopfront, '%$q%'],
          limit: 10,
        );
      }

      // 5. Phone/Mobile/Fax search
      if (results.isEmpty) {
        results = await db.query(
          'Customers',
          where: 'shopfront = ? AND (phone LIKE ? OR mobile LIKE ? OR fax LIKE ?)',
          whereArgs: [shopfront, '%$q%', '%$q%', '%$q%'],
          limit: 10,
        );
      }

      // 6. Email search
      if (results.isEmpty) {
        results = await db.query(
          'Customers',
          where: 'shopfront = ? AND email LIKE ?',
          whereArgs: [shopfront, '%$q%'],
          limit: 10,
        );
      }

      // 7. Address search (addr1, suburb, postcode)
      if (results.isEmpty) {
        results = await db.query(
          'Customers',
          where: 'shopfront = ? AND (addr1 LIKE ? OR suburb LIKE ? OR postcode LIKE ?)',
          whereArgs: [shopfront, '%$q%', '%$q%', '%$q%'],
          limit: 10,
        );
      }

      if (results.isEmpty) {
        return CustomerSearchResult.none();
      }

      // Convert results to CustomerVO list
      final List<CustomerVO> customers = [];
      for (final row in results) {
        final customerId = row['customer_id'] as int;
        final addresses = await _getCustomerAddresses(db, customerId, shopfront);
        customers.add(_customerFromRow(row, addresses));
      }

      if (customers.length == 1) {
        return CustomerSearchResult.found(customers.first);
      }

      return CustomerSearchResult.duplicates(customers);
    } catch (error) {
      logger.e('Error searching customer in $shopfront: $error');
      return Future.error("Error searching customer: $error");
    }
  }

  @override
  Future<int> getNextCustomerId(String shopfront) async {
    try {
      final db = _database!;
      final result = await db.rawQuery(
        'SELECT MAX(customer_id) as max_id FROM Customers WHERE shopfront = ?',
        [shopfront],
      );

      final maxCustomerId = (result.first['max_id'] as int?) ?? 0;
      final pendingResult = await db.rawQuery(
        'SELECT MAX(customer_id) as max_id FROM PendingCustomerCreations '
        'WHERE shopfront = ? AND status = 0',
        [shopfront],
      );
      final maxPendingId = (pendingResult.first['max_id'] as int?) ?? 0;
      final String? maxRemoteValue = await getAppConfig(
        '$kCustomerMaxIdPrefix$shopfront',
      );
      final int maxRemoteId = int.tryParse(maxRemoteValue ?? '') ?? 0;

      int maxId = maxCustomerId;
      if (maxPendingId > maxId) {
        maxId = maxPendingId;
      }
      if (maxRemoteId > maxId) {
        maxId = maxRemoteId;
      }

      return maxId <= 0 ? 1 : maxId + 1;
    } catch (error) {
      logger.e('Error getting next customer ID: $error');
      return 1;
    }
  }

  @override
  Future<int> getNextCustomerAddressId(String shopfront) async {
    try {
      final db = _database!;
      final result = await db.rawQuery(
        'SELECT MAX(address_id) as max_id FROM CustomerAddresses WHERE shopfront = ?',
        [shopfront],
      );

      final maxId = result.first['max_id'];
      if (maxId == null) {
        return 1; // Start from 1 if no addresses exist
      }

      return (maxId as int) + 1;
    } catch (error) {
      logger.e('Error getting next customer address ID: $error');
      return 1;
    }
  }

  @override
  Future<String> getNextNumericBarcode(String shopfront) async {
    try {
      final db = _database!;
      // Get all barcodes from the database
      final result = await db.rawQuery(
        'SELECT barcode FROM Customers WHERE shopfront = ?',
        [shopfront],
      );

      final pendingResult = await db.rawQuery(
        'SELECT payload_json FROM PendingCustomerCreations '
        'WHERE shopfront = ? AND status = 0',
        [shopfront],
      );

      if (result.isEmpty) {
        int maxPendingValue = 0;
        for (final row in pendingResult) {
          final payload = jsonDecode(row['payload_json'] as String);
          if (payload is! Map) continue;
          final items = payload['items'];
          if (items is! List || items.isEmpty) continue;
          final item = Map<String, dynamic>.from(items.first as Map);
          final barcode = item['barcode'] as String?;
          if (barcode == null || barcode.trim().isEmpty) continue;
          final numValue = int.tryParse(barcode.trim());
          if (numValue != null && numValue > maxPendingValue) {
            maxPendingValue = numValue;
          }
        }
        return (maxPendingValue + 1).toString();
      }

      int maxNumericValue = 0;
      for (var row in result) {
        final barcode = row['barcode'] as String?;
        if (barcode != null && barcode.isNotEmpty) {
          // Only process barcodes that are purely numeric (no characters at all)
          final numValue = int.tryParse(barcode.trim());
          if (numValue != null && numValue > maxNumericValue) {
            maxNumericValue = numValue;
          }
        }
      }

      for (final row in pendingResult) {
        final payload = jsonDecode(row['payload_json'] as String);
        if (payload is! Map) continue;
        final items = payload['items'];
        if (items is! List || items.isEmpty) continue;
        final item = Map<String, dynamic>.from(items.first as Map);
        final barcode = item['barcode'] as String?;
        if (barcode == null || barcode.trim().isEmpty) continue;
        final numValue = int.tryParse(barcode.trim());
        if (numValue != null && numValue > maxNumericValue) {
          maxNumericValue = numValue;
        }
      }

      // Generate next barcode (just the number)
      final nextNumber = maxNumericValue + 1;
      return nextNumber.toString();
    } catch (error) {
      logger.e('Error getting next numeric barcode: $error');
      return '1';
    }
  }

  @override
  Future<bool> checkBarcodeExists(String barcode, String shopfront) async {
    try {
      final db = _database!;
      final result = await db.query(
        'Customers',
        where: 'barcode = ? AND shopfront = ?',
        whereArgs: [barcode, shopfront],
        limit: 1,
      );
      if (result.isNotEmpty) return true;

      final pending = await db.rawQuery(
        'SELECT payload_json FROM PendingCustomerCreations '
        'WHERE shopfront = ? AND status = 0',
        [shopfront],
      );

      final needle = barcode.trim();
      if (needle.isEmpty) return false;

      for (final row in pending) {
        final payload = jsonDecode(row['payload_json'] as String);
        if (payload is! Map) continue;
        final items = payload['items'];
        if (items is! List || items.isEmpty) continue;
        final item = Map<String, dynamic>.from(items.first as Map);
        final pendingBarcode = item['barcode'] as String?;
        if (pendingBarcode != null && pendingBarcode.trim() == needle) {
          return true;
        }
      }

      return false;
    } catch (error) {
      logger.e('Error checking barcode existence: $error');
      return false;
    }
  }


  // ===========================================================================
  // SECTION 11: CUSTOMER TRANSACTIONS (Customer Details Screen)
  // ===========================================================================
  // Stores customer transaction history for offline viewing.
  //
  // Transaction Types:
  // - Purchases: Items bought by customer
  // - Credit: Store credit transactions
  // - Invoices: Account invoices
  // - IvPay: Invoice payments
  // - Laybys: Layby transactions
  // - LbPay: Layby payments
  // - CSO: Customer special orders
  // - SoQuote: Sales orders / quotes
  // - SoPay: Sales order payments
  //
  // Data is replaced on each sync from server (not incrementally updated)
  // ===========================================================================

  @override
  Future<void> replaceCustomerTransactions({
    required String shopfront,
    required int customerId,
    required List<Map<String, dynamic>> purchases,
    required List<Map<String, dynamic>> credit,
    required List<Map<String, dynamic>> invoices,
    required List<Map<String, dynamic>> ivPay,
    required List<Map<String, dynamic>> laybys,
    required List<Map<String, dynamic>> lbPay,
    required List<Map<String, dynamic>> cso,
    required List<Map<String, dynamic>> soQuote,
    required List<Map<String, dynamic>> soPay,
  }) async {
    try {
      final db = _database!;
      final batch = db.batch();
      final whereArgs = [shopfront, customerId];

      batch.delete(
        'CustomerPurchases',
        where: 'shopfront = ? AND customer_id = ?',
        whereArgs: whereArgs,
      );
      batch.delete(
        'CustomerCredit',
        where: 'shopfront = ? AND customer_id = ?',
        whereArgs: whereArgs,
      );
      batch.delete(
        'CustomerInvoices',
        where: 'shopfront = ? AND customer_id = ?',
        whereArgs: whereArgs,
      );
      batch.delete(
        'CustomerIvPay',
        where: 'shopfront = ? AND customer_id = ?',
        whereArgs: whereArgs,
      );
      batch.delete(
        'CustomerLaybys',
        where: 'shopfront = ? AND customer_id = ?',
        whereArgs: whereArgs,
      );
      batch.delete(
        'CustomerLbPay',
        where: 'shopfront = ? AND customer_id = ?',
        whereArgs: whereArgs,
      );
      batch.delete(
        'CustomerCso',
        where: 'shopfront = ? AND customer_id = ?',
        whereArgs: whereArgs,
      );
      batch.delete(
        'CustomerSoQuote',
        where: 'shopfront = ? AND customer_id = ?',
        whereArgs: whereArgs,
      );
      batch.delete(
        'CustomerSoPay',
        where: 'shopfront = ? AND customer_id = ?',
        whereArgs: whereArgs,
      );

      for (final item in purchases) {
        batch.insert('CustomerPurchases', item);
      }
      for (final item in credit) {
        batch.insert('CustomerCredit', item);
      }
      for (final item in invoices) {
        batch.insert('CustomerInvoices', item);
      }
      for (final item in ivPay) {
        batch.insert('CustomerIvPay', item);
      }
      for (final item in laybys) {
        batch.insert('CustomerLaybys', item);
      }
      for (final item in lbPay) {
        batch.insert('CustomerLbPay', item);
      }
      for (final item in cso) {
        batch.insert('CustomerCso', item);
      }
      for (final item in soQuote) {
        batch.insert('CustomerSoQuote', item);
      }
      for (final item in soPay) {
        batch.insert('CustomerSoPay', item);
      }

      await batch.commit(noResult: true);
    } catch (error) {
      logger.e('Error replacing customer transactions: $error');
      return Future.error("Error replacing customer transactions: $error");
    }
  }

  @override
  Future<void> replaceCustomerTransactionsByType({
    required String shopfront,
    required int customerId,
    required String transactionType,
    required List<Map<String, dynamic>> transactions,
  }) async {
    try {
      final db = _database!;
      final batch = db.batch();
      final whereArgs = [shopfront, customerId];

      // Map transaction type to table name
      final tableMap = {
        'purchase': 'CustomerPurchases',
        'credit': 'CustomerCredit',
        'invoice': 'CustomerInvoices',
        'ivpay': 'CustomerIvPay',
        'layby': 'CustomerLaybys',
        'lbpay': 'CustomerLbPay',
        'cso': 'CustomerCso',
        'soquote': 'CustomerSoQuote',
        'sopay': 'CustomerSoPay',
      };

      final tableName = tableMap[transactionType.toLowerCase()];
      if (tableName == null) {
        throw Exception('Invalid transaction type: $transactionType');
      }

      // Delete existing records for this customer and shopfront
      batch.delete(
        tableName,
        where: 'shopfront = ? AND customer_id = ?',
        whereArgs: whereArgs,
      );

      // Insert new records
      for (final item in transactions) {
        batch.insert(tableName, item);
      }

      await batch.commit(noResult: true);
    } catch (error) {
      logger.e('Error replacing customer $transactionType transactions: $error');
      return Future.error("Error replacing customer $transactionType transactions: $error");
    }
  }

  @override
  Future<void> appendCustomerTransactionsByType({
    required String shopfront,
    required int customerId,
    required String transactionType,
    required List<Map<String, dynamic>> transactions,
  }) async {
    try {
      final db = _database!;
      final batch = db.batch();

      // Map transaction type to table name
      final tableMap = {
        'purchase': 'CustomerPurchases',
        'credit': 'CustomerCredit',
        'invoice': 'CustomerInvoices',
        'ivpay': 'CustomerIvPay',
        'layby': 'CustomerLaybys',
        'lbpay': 'CustomerLbPay',
        'cso': 'CustomerCso',
        'soquote': 'CustomerSoQuote',
        'sopay': 'CustomerSoPay',
      };

      final tableName = tableMap[transactionType.toLowerCase()];
      if (tableName == null) {
        throw Exception('Invalid transaction type: $transactionType');
      }

      // Insert records (append without deleting)
      for (final item in transactions) {
        batch.insert(tableName, item);
      }

      await batch.commit(noResult: true);
    } catch (error) {
      logger.e('Error appending customer $transactionType transactions: $error');
      return Future.error("Error appending customer $transactionType transactions: $error");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomerPurchases({
    required String shopfront,
    required int customerId,
    int? limit,
  }) async {
    try {
      final db = _database!;
      return await db.query(
        'CustomerPurchases',
        where: 'shopfront = ? AND customer_id = ?',
        whereArgs: [shopfront, customerId],
        orderBy: 'date DESC',
        limit: limit,
      );
    } catch (error) {
      logger.e('Error getting customer purchases: $error');
      return Future.error("Error getting customer purchases: $error");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomerCredit({
    required String shopfront,
    required int customerId,
    int? limit,
  }) async {
    try {
      final db = _database!;
      return await db.query(
        'CustomerCredit',
        where: 'shopfront = ? AND customer_id = ?',
        whereArgs: [shopfront, customerId],
        orderBy: 'date DESC',
        limit: limit,
      );
    } catch (error) {
      logger.e('Error getting customer credit: $error');
      return Future.error("Error getting customer credit: $error");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomerInvoices({
    required String shopfront,
    required int customerId,
    int? limit,
  }) async {
    try {
      final db = _database!;
      return await db.query(
        'CustomerInvoices',
        where: 'shopfront = ? AND customer_id = ?',
        whereArgs: [shopfront, customerId],
        orderBy: 'date DESC',
        limit: limit,
      );
    } catch (error) {
      logger.e('Error getting customer invoices: $error');
      return Future.error("Error getting customer invoices: $error");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomerIvPay({
    required String shopfront,
    required int customerId,
    int? limit,
  }) async {
    try {
      final db = _database!;
      return await db.query(
        'CustomerIvPay',
        where: 'shopfront = ? AND customer_id = ?',
        whereArgs: [shopfront, customerId],
        orderBy: 'date DESC',
        limit: limit,
      );
    } catch (error) {
      logger.e('Error getting customer iv pay: $error');
      return Future.error("Error getting customer iv pay: $error");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomerLaybys({
    required String shopfront,
    required int customerId,
    int? limit,
  }) async {
    try {
      final db = _database!;
      return await db.query(
        'CustomerLaybys',
        where: 'shopfront = ? AND customer_id = ?',
        whereArgs: [shopfront, customerId],
        orderBy: 'date DESC',
        limit: limit,
      );
    } catch (error) {
      logger.e('Error getting customer laybys: $error');
      return Future.error("Error getting customer laybys: $error");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomerLbPay({
    required String shopfront,
    required int customerId,
    int? limit,
  }) async {
    try {
      final db = _database!;
      return await db.query(
        'CustomerLbPay',
        where: 'shopfront = ? AND customer_id = ?',
        whereArgs: [shopfront, customerId],
        orderBy: 'date DESC',
        limit: limit,
      );
    } catch (error) {
      logger.e('Error getting customer layby payments: $error');
      return Future.error("Error getting customer layby payments: $error");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomerCso({
    required String shopfront,
    required int customerId,
    int? limit,
  }) async {
    try {
      final db = _database!;
      return await db.query(
        'CustomerCso',
        where: 'shopfront = ? AND customer_id = ?',
        whereArgs: [shopfront, customerId],
        orderBy: 'date DESC',
        limit: limit,
      );
    } catch (error) {
      logger.e('Error getting customer CSO: $error');
      return Future.error("Error getting customer CSO: $error");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomerSoQuote({
    required String shopfront,
    required int customerId,
    int? limit,
  }) async {
    try {
      final db = _database!;
      return await db.query(
        'CustomerSoQuote',
        where: 'shopfront = ? AND customer_id = ?',
        whereArgs: [shopfront, customerId],
        orderBy: 'date DESC',
        limit: limit,
      );
    } catch (error) {
      logger.e('Error getting customer SO/Quote: $error');
      return Future.error("Error getting customer SO/Quote: $error");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomerSoPay({
    required String shopfront,
    required int customerId,
    int? limit,
  }) async {
    try {
      final db = _database!;
      return await db.query(
        'CustomerSoPay',
        where: 'shopfront = ? AND customer_id = ?',
        whereArgs: [shopfront, customerId],
        orderBy: 'date DESC',
        limit: limit,
      );
    } catch (error) {
      logger.e('Error getting customer SO payments: $error');
      return Future.error("Error getting customer SO payments: $error");
    }
  }

  @override
  Future<void> clearCustomersForShop(String shopfront) async {
    try {
      final db = _database!;
      await db.transaction((txn) async {
        await txn.delete(
          'CustomerAddresses',
          where: 'shopfront = ?',
          whereArgs: [shopfront],
        );
        await txn.delete(
          'Customers',
          where: 'shopfront = ?',
          whereArgs: [shopfront],
        );
      });
      logger.d('Cleared customers for $shopfront');
    } catch (error) {
      logger.e('Error clearing customers for $shopfront: $error');
    }
  }

  @override
  Future<void> deleteCustomersByIds({
    required String shopfront,
    required List<int> customerIds,
  }) async {
    try {
      if (customerIds.isEmpty) return;
      final db = _database!;
      final ids = customerIds.where((id) => id > 0).toSet().toList();
      if (ids.isEmpty) return;

      const int batchSize = 900;
      await db.transaction((txn) async {
        for (int i = 0; i < ids.length; i += batchSize) {
          final chunk = ids.skip(i).take(batchSize).toList();
          final placeholders = List.filled(chunk.length, '?').join(',');
          await txn.delete(
            'CustomerAddresses',
            where: 'shopfront = ? AND customer_id IN ($placeholders)',
            whereArgs: [shopfront, ...chunk],
          );
          await txn.delete(
            'Customers',
            where: 'shopfront = ? AND customer_id IN ($placeholders)',
            whereArgs: [shopfront, ...chunk],
          );
        }
      });
    } catch (error) {
      logger.e('Error deleting customers by ids for $shopfront: $error');
      return Future.error("Error deleting customers by ids: $error");
    }
  }

  // ===========================================================================
  // SECTION 12: SALE SESSIONS (Sale/Cart Screen)
  // ===========================================================================
  // Manages parked/held sale sessions for POS workflow.
  //
  // Features:
  // - Save current sale cart as a session
  // - Retrieve parked sales, quotes, or held transactions
  // - Track session type (sale, quote, layby, etc.)
  // - Count sessions by type for badge display
  // - Delete individual or all sessions
  //
  // Used when:
  // - Customer needs to leave but wants to hold their cart
  // - Creating quotes for later conversion to sale
  // - Switching between multiple customers at POS
  // ===========================================================================

  @override
  Future<List<Map<String, dynamic>>> getSaleSessions({
    required String shopfront,
    String? sessionType,
  }) async {
    try {
      final db = _database!;
      String where = 'shopfront = ?';
      List<dynamic> whereArgs = [shopfront];
      
      if (sessionType != null) {
        where += ' AND session_type = ?';
        whereArgs.add(sessionType);
      }
      
      final result = await db.query(
        'SaleSessions',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'updated_at DESC',
      );
      return result;
    } catch (error) {
      logger.e('Error getting sale sessions: $error');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> getSaleSession(int id) async {
    try {
      final db = _database!;
      final result = await db.query(
        'SaleSessions',
        where: 'id = ?',
        whereArgs: [id],
      );
      return result.isNotEmpty ? result.first : null;
    } catch (error) {
      logger.e('Error getting sale session: $error');
      return null;
    }
  }

  @override
  Future<int> saveSaleSession(Map<String, dynamic> session) async {
    try {
      final db = _database!;
      // Remove id if it's provided - let SQLite auto-generate it
      final data = Map<String, dynamic>.from(session);
      data.remove('id');
      
      final id = await db.insert('SaleSessions', data);
      logger.d('Saved sale session with id: $id');
      return id;
    } catch (error) {
      logger.e('Error saving sale session: $error');
      return -1;
    }
  }

  @override
  Future<void> updateSaleSession(Map<String, dynamic> session) async {
    try {
      final db = _database!;
      final id = session['id'];
      if (id == null) {
        logger.e('Cannot update sale session without id');
        return;
      }
      
      await db.update(
        'SaleSessions',
        session,
        where: 'id = ?',
        whereArgs: [id],
      );
      logger.d('Updated sale session: $id');
    } catch (error) {
      logger.e('Error updating sale session: $error');
    }
  }

  @override
  Future<void> deleteSaleSession(int id) async {
    try {
      final db = _database!;
      await db.delete(
        'SaleSessions',
        where: 'id = ?',
        whereArgs: [id],
      );
      logger.d('Deleted sale session: $id');
    } catch (error) {
      logger.e('Error deleting sale session: $error');
    }
  }

  @override
  Future<void> deleteAllSaleSessions({String? shopfront, String? sessionType}) async {
    try {
      final db = _database!;
      String? where;
      List<dynamic>? whereArgs;
      
      if (shopfront != null || sessionType != null) {
        final conditions = <String>[];
        whereArgs = <dynamic>[];
        
        if (shopfront != null) {
          conditions.add('shopfront = ?');
          whereArgs.add(shopfront);
        }
        if (sessionType != null) {
          conditions.add('session_type = ?');
          whereArgs.add(sessionType);
        }
        
        where = conditions.join(' AND ');
      }
      
      await db.delete('SaleSessions', where: where, whereArgs: whereArgs);
      logger.d('Deleted all sale sessions (shopfront: $shopfront, type: $sessionType)');
    } catch (error) {
      logger.e('Error deleting all sale sessions: $error');
    }
  }

  @override
  Future<Map<String, int>> getSaleSessionCounts(String shopfront) async {
    try {
      final db = _database!;
      final result = await db.rawQuery(
        'SELECT session_type, COUNT(*) as count FROM SaleSessions WHERE shopfront = ? GROUP BY session_type',
        [shopfront],
      );
      
      final counts = <String, int>{};
      for (final row in result) {
        final sessionType = row['session_type'] as String;
        final count = row['count'] as int;
        counts[sessionType] = count;
      }
      return counts;
    } catch (error) {
      logger.e('Error getting sale session counts: $error');
      return {};
    }
  }

  @override
  Future<Map<String, Map<String, dynamic>>> getSaleSessionSummaries(String shopfront) async {
    try {
      final db = _database!;
      final result = await db.rawQuery('''
        SELECT 
          session_type,
          COUNT(*) as count,
          SUM(total_inc) as total_value,
          MIN(created_at) as oldest_date,
          COUNT(DISTINCT customer_id) as customer_count
        FROM SaleSessions 
        WHERE shopfront = ? 
        GROUP BY session_type
      ''', [shopfront]);
      
      final summaries = <String, Map<String, dynamic>>{};
      for (final row in result) {
        final sessionType = row['session_type'] as String;
        summaries[sessionType] = {
          'count': row['count'] as int,
          'totalValue': (row['total_value'] as num?)?.toDouble() ?? 0.0,
          'oldestDate': row['oldest_date'] as String?,
          'customerCount': row['customer_count'] as int? ?? 0,
        };
      }
      
      // Get item counts separately (from cart_items_json)
      for (final sessionType in summaries.keys) {
        final sessions = await db.query(
          'SaleSessions',
          columns: ['cart_items_json'],
          where: 'shopfront = ? AND session_type = ?',
          whereArgs: [shopfront, sessionType],
        );
        
        int totalItems = 0;
        for (final session in sessions) {
          final cartJson = session['cart_items_json'] as String?;
          if (cartJson != null && cartJson.isNotEmpty) {
            try {
              // Count items in cart - look for common patterns
              // Try multiple patterns to catch different JSON structures
              final stockCodeMatches = RegExp(r'"stockCode"|"stock_code"|"StockCode"', caseSensitive: false).allMatches(cartJson);
              if (stockCodeMatches.isNotEmpty) {
                totalItems += stockCodeMatches.length;
              } else {
                // Fallback: count array elements by looking for opening braces after [
                final arrayMatches = RegExp(r'\{').allMatches(cartJson);
                totalItems += arrayMatches.length;
              }
            } catch (_) {}
          }
        }
        summaries[sessionType]!['itemCount'] = totalItems;
      }
      
      return summaries;
    } catch (error) {
      logger.e('Error getting sale session summaries: $error');
      return {};
    }
  }

  // ===========================================================================
  // SECTION 13: TAX CODES (Sale Configuration)
  // ===========================================================================
  // Stores tax codes synced from the server for sales calculations.
  //
  // Features:
  // - Replace all tax codes on sync (full refresh)
  // - Lookup tax code by code string
  // - List all available tax codes for dropdown selection
  //
  // Used during sales to apply correct tax rates to items.
  // ===========================================================================

  @override
  Future<void> saveTaxCodes(List<TaxCodeVO> taxCodes, String shopfront) async {
    try {
      final db = _database!;
      await db.transaction((txn) async {
        // Clear existing tax codes for this shopfront
        await txn.delete(
          'TaxCodes',
          where: 'shopfront = ?',
          whereArgs: [shopfront],
        );
        
        // Insert new tax codes
        for (final taxCode in taxCodes) {
          await txn.insert(
            'TaxCodes',
            taxCode.toDbMap(shopfront),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      logger.d('Saved ${taxCodes.length} tax codes for $shopfront');
    } catch (error) {
      logger.e('Error saving tax codes: $error');
    }
  }

  @override
  Future<List<TaxCodeVO>> getTaxCodes(String shopfront) async {
    try {
      final db = _database!;
      final result = await db.query(
        'TaxCodes',
        where: 'shopfront = ?',
        whereArgs: [shopfront],
        orderBy: 'code ASC',
      );
      return result.map((row) => TaxCodeVO.fromDbMap(row)).toList();
    } catch (error) {
      logger.e('Error getting tax codes: $error');
      return [];
    }
  }

  @override
  Future<TaxCodeVO?> getTaxCodeByCode(String code, String shopfront) async {
    try {
      final db = _database!;
      final result = await db.query(
        'TaxCodes',
        where: 'code = ? AND shopfront = ?',
        whereArgs: [code, shopfront],
        limit: 1,
      );
      if (result.isEmpty) return null;
      return TaxCodeVO.fromDbMap(result.first);
    } catch (error) {
      logger.e('Error getting tax code by code: $error');
      return null;
    }
  }

  @override
  Future<void> clearTaxCodesForShop(String shopfront) async {
    try {
      final db = _database!;
      await db.delete(
        'TaxCodes',
        where: 'shopfront = ?',
        whereArgs: [shopfront],
      );
      logger.d('Cleared tax codes for $shopfront');
    } catch (error) {
      logger.e('Error clearing tax codes for $shopfront: $error');
    }
  }
}