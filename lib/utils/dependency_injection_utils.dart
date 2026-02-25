import 'package:get_it/get_it.dart';
import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';
import 'package:rmstock_scanner/features/home_page/domain/use_cases/cleanup_history.dart';
import 'package:rmstock_scanner/features/home_page/domain/use_cases/discover_host.dart';
import 'package:rmstock_scanner/features/home_page/domain/use_cases/load_retention_days.dart';
import 'package:rmstock_scanner/features/home_page/domain/use_cases/pair_device.dart';
import 'package:rmstock_scanner/features/home_page/domain/use_cases/run_auto_backup_if_due.dart';
import 'package:rmstock_scanner/features/home_page/domain/use_cases/load_auto_backup_enabled.dart';
import 'package:rmstock_scanner/features/home_page/domain/use_cases/update_auto_backup_enabled.dart';
import 'package:rmstock_scanner/features/home_page/domain/use_cases/update_retention_days.dart';
import 'package:rmstock_scanner/features/loading_splash/domain/repositories/loading_splash_repo.dart';
import 'package:rmstock_scanner/features/stock_lookup/domain/use_cases/fetch_full_image.dart';
import 'package:rmstock_scanner/features/stock_lookup/domain/use_cases/fetch_thumbnail.dart';
import 'package:rmstock_scanner/features/stock_lookup/domain/use_cases/upload_stock_image.dart';
import 'package:rmstock_scanner/features/stocktake/domain/repositories/stocktake_repo.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/backup_stocktake.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/fetch_counted_stock_by_id.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/fetch_sessions.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/fetch_sesstion_items.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/fetch_stocktake_audit_report.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/fetch_stocktake_limit.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/fetch_stocktake_page.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/load_backup_sessions.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/restore_backup_session.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/send_final_stocktake_to_rm.dart';
import 'package:rmstock_scanner/features/stocktake/domain/use_cases/update_stock_count.dart';
import '../features/home_page/domain/use_cases/auto_connect_to_default_folder.dart';
import '../features/home_page/domain/use_cases/check_if_shopfront_file_exists.dart';
import '../features/home_page/domain/use_cases/connect_and_write_to_folder.dart';
import '../features/home_page/domain/use_cases/connect_to_shopfront.dart';
import '../features/home_page/domain/use_cases/connect_to_shopfront_api.dart';
import '../features/home_page/domain/use_cases/fetch_network_pcs.dart';
import '../features/home_page/domain/use_cases/fetch_shopfront_list.dart';
import '../features/home_page/domain/use_cases/fetch_shopfronts_from_api.dart';
import '../features/home_page/domain/use_cases/fetch_stock_data.dart';
import '../features/home_page/domain/use_cases/get_to_shared_folder.dart';
import '../features/home_page/domain/use_cases/get_pair_codes.dart';
import '../features/home_page/models/home_screen_models.dart';
import '../features/home_page/presentation/BLoC/home_screen_bloc.dart';
import '../features/loading_splash/domain/use_cases/check_path_connection.dart';
import '../features/loading_splash/domain/use_cases/fetch_saved_paths.dart';
import '../features/loading_splash/models/loading_splash_models.dart';
import '../features/loading_splash/presentation/BLoC/loading_splash_bloc.dart';
import '../features/stock_lookup/domain/repositories/stock_lookup_repo.dart';
import '../features/stock_lookup/domain/use_cases/get_filter_options.dart';
import '../features/stock_lookup/domain/use_cases/get_paginated_stock.dart';
import '../features/stock_lookup/domain/use_cases/update_single_stock.dart';
import '../features/stock_lookup/models/stock_lookup_models.dart';
import '../features/stock_lookup/presentation/BLoC/stock_lookup_bloc.dart';
import '../features/stocktake/domain/use_cases/commit_stocktake.dart';
import '../features/stocktake/domain/use_cases/count_and_save_to_localdb.dart';
//import '../features/stocktake/domain/use_cases/fetch_all_stocktake_list.dart';
import '../features/stocktake/domain/use_cases/fetch_counting_stock.dart';
import '../features/stocktake/models/stocktake_model.dart';
import '../features/stocktake/presentation/BLoC/stocktake_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // registering dependencies

  //Blocs
  sl.registerFactory(() => StocktakeBloc(countAndSaveToLocaldb: sl()));
  sl.registerFactory(() => FetchingNetworkServerBloc(fetchNetworkPcs: sl()));
  sl.registerFactory(() => GettingDirectoryBloc(getToSharedFolder: sl()));
  sl.registerFactory(() => ConnectingFolderBloc(connectAndWriteToFolder: sl()));
  sl.registerFactory(
    () => ShopfrontBloc(fetchShopfrontList: sl(), fetchShopfrontsFromApi: sl()),
  );
  sl.registerFactory(
    () => ShopFrontConnectionBloc(
      connectToShopfront: sl(),
      connectToShopfrontApi: sl(),
    ),
  );
  sl.registerFactory(
    () => NetworkSavedPathValidationBloc(
      fetchSavedPaths: sl(),
      checkPathConnection: sl(),
    ),
  );
  sl.registerFactory(() => FetchingStocktakeListBloc(fetchStocktakePage: sl()));
  sl.registerFactory(() => CommittingStocktakeBloc(commitStocktake: sl()));
  sl.registerFactory(() => StocktakeLimitBloc(fetchStocktakeLimit: sl()));
  sl.registerFactory(
    () => AutoConnectionBloc(autoConnectToDefaultFolder: sl()),
  );
  sl.registerFactory(() => FetchStockBloc(fetchStockData: sl()));
  sl.registerFactory(() => StockListBloc(getPaginatedStock: sl()));
  sl.registerFactory(() => FilterOptionsBloc(getFilterOptions: sl()));
  sl.registerFactory(() => ScannerBloc(fetchCountingStock: sl()));
  sl.registerFactory(
    () => StocktakeValidationBloc(fetchStocktakeAuditReport: sl()),
  );
  sl.registerFactory(
    () => SendingFinalStocktakeBloc(sendFinalStocktakeToRm: sl()),
  );
  sl.registerFactory(() => ThumbnailBloc(fetchThumbnail: sl()));
  sl.registerFactory(() => FullImageBloc(fetchFullImage: sl()));
  sl.registerFactory(
    () => StocktakeHistoryBloc(fetchSessions: sl(), fetchItems: sl()),
  );
  sl.registerFactory(
    () => SettingsBloc(
      loadRetentionDays: sl(),
      updateRetentionDays: sl(),
      cleanupHistory: sl(),
      loadAutoBackupEnabled: sl(),
      updateAutoBackupEnabled: sl(),
      runAutoBackupIfDue: sl(),
    ),
  );
  sl.registerFactory(() => DiscoverHostBloc(discoverHost: sl()));
  sl.registerFactory(() => PairCodeBloc(getPairCodes: sl()));
  sl.registerFactory(() => PairDeviceBloc(pairDevice: sl()));
  sl.registerFactory(() => StockDetailsBloc(fetchCountedStockById: sl()));
  sl.registerFactory(() => StockCountUpdateBloc(updateStockCount: sl()));
  sl.registerFactory(() => StockImageUploadBloc(uploadUseCase: sl()));
  sl.registerFactory(() => BackupStocktakeBloc(backupStocktake: sl()));
  sl.registerFactory(
    () => BackupRestoreBloc(loadSessions: sl(), restoreSession: sl()),
  );
  sl.registerFactory(() => StockUpdateBloc(updateSingleStock: sl()));

  //Repos
  sl.registerLazySingleton<HomeRepo>(() => HomeScreenModels());
  sl.registerLazySingleton<StocktakeRepo>(() => StocktakeModel());
  sl.registerLazySingleton<LoadingSplashRepo>(() => LoadingSplashModels());
  sl.registerLazySingleton<StockLookupRepo>(() => StockLookupModels());

  //Use cases
  sl.registerLazySingleton(() => CountAndSaveToLocaldb(sl()));
  sl.registerLazySingleton(() => FetchNetworkPcs(sl()));
  sl.registerLazySingleton(() => GetToSharedFolder(sl()));
  sl.registerLazySingleton(() => ConnectAndWriteToFolder(sl()));
  sl.registerLazySingleton(() => FetchShopfrontList(sl()));
  sl.registerLazySingleton(() => FetchShopfrontsFromApi(sl()));
  sl.registerLazySingleton(() => ConnectToShopfront(sl()));
  sl.registerLazySingleton(() => ConnectToShopfrontApi(sl()));
  sl.registerLazySingleton(() => FetchSavedPaths(sl()));
  sl.registerLazySingleton(() => CheckPathConnection(sl()));
  //sl.registerLazySingleton(() => FetchAllStocktakeList(sl()));
  sl.registerLazySingleton(() => CommitStocktake(sl()));
  sl.registerLazySingleton(() => AutoConnectToDefaultFolder(sl()));
  sl.registerLazySingleton(() => CheckIfShopfrontFileExists(sl()));
  sl.registerLazySingleton(() => FetchStockData(sl()));
  sl.registerLazySingleton(() => GetPaginatedStock(sl()));
  sl.registerLazySingleton(() => GetFilterOptions(sl()));
  sl.registerLazySingleton(() => FetchCountingStock(sl()));
  sl.registerLazySingleton(() => FetchStocktakeAuditReport(sl()));
  sl.registerLazySingleton(() => FetchStocktakeLimit(sl()));
  sl.registerLazySingleton(() => SendFinalStocktakeToRm(sl()));
  sl.registerLazySingleton(() => FetchThumbnail(sl()));
  sl.registerLazySingleton(() => FetchFullImage(sl()));
  sl.registerLazySingleton(() => FetchStocktakeHistorySessions());
  sl.registerLazySingleton(() => FetchStocktakeHistoryItems());
  sl.registerLazySingleton(() => LoadRetentionDays(sl()));
  sl.registerLazySingleton(() => UpdateRetentionDays(sl()));
  sl.registerLazySingleton(() => CleanupHistory(sl()));
  sl.registerLazySingleton(() => LoadAutoBackupEnabled(sl()));
  sl.registerLazySingleton(() => UpdateAutoBackupEnabled(sl()));
  sl.registerLazySingleton(
    () => RunAutoBackupIfDue(repository: sl(), backupStocktake: sl()),
  );
  sl.registerLazySingleton(() => DiscoverHost(sl()));
  sl.registerLazySingleton(() => GetPairCodes(sl()));
  sl.registerLazySingleton(() => PairDevice(sl()));
  sl.registerLazySingleton(() => FetchCountedStockById(sl()));
  sl.registerLazySingleton(() => UpdateStockCount(sl()));
  sl.registerLazySingleton(() => FetchStocktakePage(sl()));
  sl.registerLazySingleton(() => UploadStockImageUseCase(sl()));
  sl.registerLazySingleton(() => BackupStocktake(sl()));
  sl.registerLazySingleton(() => LoadBackupSessions(sl()));
  sl.registerLazySingleton(() => RestoreBackupSession(sl()));
  sl.registerLazySingleton(() => UpdateSingleStock(sl()));
}
