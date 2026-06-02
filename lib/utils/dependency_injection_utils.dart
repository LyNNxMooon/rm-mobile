import 'package:get_it/get_it.dart';
import 'package:rmmobile/features/home_page/domain/repositories/home_repo.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/cleanup_history.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/clear_sync_timestamps.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/get_sale_session_counts.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/get_sale_session_summaries.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/discover_host.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/authenticate_staff.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/load_dark_mode_enabled.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/load_retention_days.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/load_saved_staff_session.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/load_saved_staff_credentials.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/load_saved_connection_info.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/pair_device.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/run_auto_backup_if_due.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/load_auto_backup_enabled.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/sign_out_staff.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/update_auto_backup_enabled.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/update_dark_mode_enabled.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/load_dashboard_style.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/update_dashboard_style.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/load_font_size.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/update_font_size.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/update_retention_days.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/get_cash_drawer_identifier.dart'
  as home_use_cases;
import 'package:rmmobile/features/home_page/domain/use_cases/save_cash_drawer_identifier.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/export_database_file.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/import_database_file.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/get_rm_version.dart';
import 'package:rmmobile/features/loading_splash/domain/repositories/loading_splash_repo.dart';
import 'package:rmmobile/features/stock_lookup/domain/use_cases/fetch_full_image.dart';
import 'package:rmmobile/features/stock_lookup/domain/use_cases/fetch_thumbnail.dart';
import 'package:rmmobile/features/stock_lookup/domain/use_cases/upload_stock_image.dart';
import 'package:rmmobile/features/stocktake/domain/repositories/stocktake_repo.dart';
import 'package:rmmobile/features/stocktake/domain/use_cases/backup_stocktake.dart';
import 'package:rmmobile/features/stocktake/domain/use_cases/fetch_counted_stock_by_id.dart';
import 'package:rmmobile/features/stocktake/domain/use_cases/fetch_sessions.dart';
import 'package:rmmobile/features/stocktake/domain/use_cases/fetch_sesstion_items.dart';
import 'package:rmmobile/features/stocktake/domain/use_cases/fetch_stocktake_audit_report.dart';
import 'package:rmmobile/features/stocktake/domain/use_cases/fetch_stocktake_limit.dart';
import 'package:rmmobile/features/stocktake/domain/use_cases/fetch_stocktake_page.dart';
import 'package:rmmobile/features/stocktake/domain/use_cases/has_unsynced_stocktakes.dart';
import 'package:rmmobile/features/stocktake/domain/use_cases/delete_stocktake_item.dart';
import 'package:rmmobile/features/stocktake/domain/use_cases/delete_all_stocktake.dart';
import 'package:rmmobile/features/stocktake/domain/use_cases/load_backup_sessions.dart';
import 'package:rmmobile/features/stocktake/domain/use_cases/restore_backup_session.dart';
import 'package:rmmobile/features/stocktake/domain/use_cases/send_final_stocktake_to_rm.dart';
import 'package:rmmobile/features/stocktake/domain/use_cases/update_stock_count.dart';
// SMB LEGACY imports - Commented out
// import '../features/home_page/domain/use_cases/auto_connect_to_default_folder.dart';
// import '../features/home_page/domain/use_cases/check_if_shopfront_file_exists.dart';
// import '../features/home_page/domain/use_cases/connect_and_write_to_folder.dart';
// import '../features/home_page/domain/use_cases/connect_to_shopfront.dart';
import '../features/home_page/domain/use_cases/connect_to_shopfront_api.dart';
import '../features/home_page/domain/use_cases/fetch_network_pcs.dart';
// SMB LEGACY import - Commented out
// import '../features/home_page/domain/use_cases/fetch_shopfront_list.dart';
import '../features/home_page/domain/use_cases/fetch_shopfronts_from_api.dart';
import '../features/home_page/domain/use_cases/fetch_stock_data.dart';
// SMB LEGACY import - Commented out
// import '../features/home_page/domain/use_cases/get_to_shared_folder.dart';
import '../features/home_page/domain/use_cases/get_pair_codes.dart';
import '../features/home_page/models/home_screen_models.dart';
import '../features/home_page/presentation/BLoC/home_screen_bloc.dart';
import '../features/home_page/presentation/BLoC/session_counts_cubit.dart';
import '../features/loading_splash/domain/use_cases/check_path_connection.dart';
import '../features/loading_splash/domain/use_cases/delete_saved_path.dart';
import '../features/loading_splash/domain/use_cases/fetch_saved_paths.dart';
import '../features/loading_splash/models/loading_splash_models.dart';
import '../features/loading_splash/presentation/BLoC/loading_splash_bloc.dart';
import '../features/stock_lookup/domain/repositories/stock_lookup_repo.dart';
import '../features/stock_lookup/domain/use_cases/get_filter_options.dart';
import '../features/stock_lookup/domain/use_cases/get_paginated_stock.dart';
import '../features/stock_lookup/domain/use_cases/get_pending_stock_updates.dart';
import '../features/stock_lookup/domain/use_cases/get_pending_stock_updates_count.dart';
import '../features/stock_lookup/domain/use_cases/send_pending_stock_updates.dart';
import '../features/stock_lookup/domain/use_cases/delete_pending_stock_updates.dart';
import '../features/stock_lookup/domain/use_cases/update_single_stock.dart';
import '../features/stock_lookup/domain/use_cases/resolve_package_component_stock.dart';
import '../features/stock_lookup/domain/use_cases/get_shopfront_name.dart' as stock_lookup;
import '../features/stock_lookup/domain/use_cases/seed_stock_sync_timestamp.dart';
import '../features/stock_lookup/models/stock_lookup_models.dart';
import '../features/stock_lookup/presentation/BLoC/stock_lookup_bloc.dart';
import '../features/stock_lookup/presentation/BLoC/package_component_bloc.dart';
import '../features/customer_lookup/domain/repositories/customer_lookup_repo.dart';
import '../features/customer_lookup/domain/use_cases/fetch_customer_data.dart';
import '../features/customer_lookup/domain/use_cases/fetch_customer_transactions.dart';
import '../features/customer_lookup/domain/use_cases/fetch_customer_transactions_by_type.dart';
import '../features/customer_lookup/domain/use_cases/get_customer_filter_options.dart';
import '../features/customer_lookup/domain/use_cases/get_host_ip_address.dart';
import '../features/customer_lookup/domain/use_cases/get_next_customer_address_id.dart';
import '../features/customer_lookup/domain/use_cases/get_next_customer_id.dart';
import '../features/customer_lookup/domain/use_cases/get_next_numeric_barcode.dart';
import '../features/customer_lookup/domain/use_cases/check_barcode_exists.dart';
import '../features/customer_lookup/domain/use_cases/create_customer.dart';
import '../features/customer_lookup/domain/use_cases/get_paginated_customers.dart';
import '../features/customer_lookup/domain/use_cases/get_staff_by_barcode.dart';
import '../features/customer_lookup/domain/use_cases/get_staff_detail.dart';
import '../features/customer_lookup/domain/use_cases/update_customer_details.dart';
import '../features/customer_lookup/domain/use_cases/get_pending_customer_updates.dart';
import '../features/customer_lookup/domain/use_cases/get_pending_customer_updates_count.dart';
import '../features/customer_lookup/domain/use_cases/get_pending_customer_creations.dart';
import '../features/customer_lookup/domain/use_cases/get_pending_customer_creations_count.dart';
import '../features/customer_lookup/domain/use_cases/send_pending_customer_updates.dart';
import '../features/customer_lookup/domain/use_cases/send_pending_customer_creations.dart';
import '../features/customer_lookup/domain/use_cases/delete_pending_customer_updates.dart';
import '../features/customer_lookup/domain/use_cases/delete_pending_customer_creations.dart';
import '../features/customer_lookup/domain/use_cases/resolve_customer_create_conflicts.dart';
import '../features/customer_lookup/domain/use_cases/get_shopfront_name.dart' as customer_lookup;
import '../features/customer_lookup/models/customer_lookup_models.dart';
import '../features/customer_lookup/presentation/BLoC/customer_lookup_bloc.dart';
import '../features/customer_lookup/presentation/BLoC/customer_create_bloc.dart';
import '../features/customer_lookup/presentation/BLoC/customer_transactions_bloc.dart';
import '../features/customer_lookup/presentation/BLoC/staff_barcode_lookup_bloc.dart';
import '../features/stocktake/domain/use_cases/commit_stocktake.dart';
import '../features/stocktake/domain/use_cases/batch_commit_stocktake.dart';
import '../features/stocktake/domain/use_cases/count_and_save_to_localdb.dart';
//import '../features/stocktake/domain/use_cases/fetch_all_stocktake_list.dart';
import '../features/stocktake/domain/use_cases/fetch_counting_stock.dart';
import '../features/stocktake/models/stocktake_model.dart';
import '../features/stocktake/presentation/BLoC/stocktake_bloc.dart';
import '../features/stocktake/presentation/BLoC/batch_commit_bloc.dart';
import '../features/transactions/domain/repositories/sales_repo.dart';
import '../features/transactions/domain/use_cases/search_stock_for_sale.dart';
import '../features/transactions/domain/use_cases/search_customer_for_sale.dart';
import '../features/transactions/domain/use_cases/check_low_stock_warning.dart';
import '../features/transactions/domain/use_cases/check_stock_availability.dart';
import '../features/transactions/domain/use_cases/validate_out_of_stock_items.dart';
import '../features/transactions/domain/use_cases/get_sale_sessions.dart';
import '../features/transactions/domain/use_cases/save_sale_session.dart';
import '../features/transactions/domain/use_cases/delete_sale_session.dart';
import '../features/transactions/domain/use_cases/restore_sale_session.dart';
import '../features/transactions/domain/use_cases/load_sales_settings.dart';
import '../features/transactions/domain/use_cases/save_sales_setting.dart';
import '../features/transactions/domain/use_cases/create_account_invoice.dart';
import '../features/transactions/domain/use_cases/create_sales_order.dart';
import '../features/transactions/domain/use_cases/create_quote.dart';
import '../features/transactions/domain/use_cases/get_cash_drawer_identifier.dart'
  as sales_use_cases;
import '../features/transactions/domain/use_cases/create_layby.dart';
import '../features/transactions/models/sales_model.dart';
import '../features/transactions/presentation/BLoC/sales_bloc.dart';
import '../features/onboarding/domain/repositories/onboarding_repo.dart';
import '../features/onboarding/models/onboarding_models.dart';
import '../features/onboarding/domain/use_cases/get_terms_accepted.dart';
import '../features/onboarding/domain/use_cases/set_terms_accepted.dart';
import '../features/onboarding/presentation/BLoC/onboarding_bloc.dart';
import '../features/customer_lookup/domain/use_cases/get_customer_transactions_local.dart';
import '../features/theme/presentation/bloc/theme_cubit.dart';
import '../features/home_page/presentation/BLoC/dashboard_style_cubit.dart';
import '../features/home_page/presentation/BLoC/font_size_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // registering dependencies

  //Blocs
  sl.registerFactory(() => SalesBloc(
    searchStockForSale: sl(),
    searchCustomerForSale: sl(),
    checkLowStockWarning: sl(),
    checkStockAvailability: sl(),
    validateOutOfStockItems: sl(),
    getSaleSessions: sl(),
    saveSaleSession: sl(),
    deleteSaleSession: sl(),
    restoreSaleSession: sl(),
    loadSalesSettings: sl(),
    saveSalesSetting: sl(),
    createAccountInvoice: sl(),
    createSalesOrder: sl(),
    createQuote: sl(),
    createLayby: sl(),
    getCashDrawerIdentifier: sl(),
    updateCustomerDetails: sl(),
  ));
  sl.registerFactory(() => StocktakeBloc(countAndSaveToLocaldb: sl()));
  sl.registerFactory(() => FetchingNetworkServerBloc(fetchNetworkPcs: sl()));
  // SMB LEGACY - Commented out
  // sl.registerFactory(() => GettingDirectoryBloc(getToSharedFolder: sl()));
  // sl.registerFactory(() => ConnectingFolderBloc(connectAndWriteToFolder: sl()));
  sl.registerFactory(
    () => ShopfrontBloc(fetchShopfrontsFromApi: sl()),
  );
  sl.registerFactory(
    () => ShopFrontConnectionBloc(
      // SMB LEGACY - connectToShopfront commented out
      // connectToShopfront: sl(),
      connectToShopfrontApi: sl(),
    ),
  );
  sl.registerFactory(
    () => NetworkSavedPathValidationBloc(
      fetchSavedPaths: sl(),
      checkPathConnection: sl(),
      deleteSavedPath: sl(),
    ),
  );
  sl.registerFactory(() => FetchingStocktakeListBloc(fetchStocktakePage: sl()));
  sl.registerFactory(
    () => CommittingStocktakeBloc(
      commitStocktake: sl(),
      hasUnsyncedStocktakes: sl(),
    ),
  );
  sl.registerFactory(() => StocktakeLimitBloc(fetchStocktakeLimit: sl()));
  // SMB LEGACY - Commented out
  // sl.registerFactory(
  //   () => AutoConnectionBloc(autoConnectToDefaultFolder: sl()),
  // );
  sl.registerFactory(() => FetchStockBloc(fetchStockData: sl()));
  sl.registerFactory(() => StockListBloc(getPaginatedStock: sl()));
  sl.registerFactory(
    () => PackageComponentBloc(resolvePackageComponentStock: sl()),
  );
  sl.registerFactory(() => FilterOptionsBloc(getFilterOptions: sl()));
  sl.registerFactory(() => FetchCustomerBloc(fetchCustomerData: sl()));
  sl.registerFactory(() => CustomerListBloc(getPaginatedCustomers: sl()));
  sl.registerFactory(() => CustomerFilterOptionsBloc(getCustomerFilterOptions: sl()));
  sl.registerFactory(() => StaffDetailBloc(getStaffDetail: sl()));
  sl.registerFactory(() => CustomerUpdateBloc(updateCustomerDetails: sl()));
  sl.registerFactory(
    () => CustomerTransactionsBloc(
      getCustomerTransactionsLocal: sl(),
      fetchCustomerTransactions: sl(),
      fetchCustomerTransactionsByType: sl(),
    ),
  );
  sl.registerFactory(
    () => CustomerCreateBloc(
      createCustomer: sl(),
      checkBarcodeExists: sl(),
      getNextNumericBarcode: sl(),
      getNextCustomerId: sl(),
      getNextCustomerAddressId: sl(),
    ),
  );
  sl.registerFactory(() => StaffBarcodeLookupBloc(getStaffByBarcode: sl()));
  sl.registerFactory(() => ScannerBloc(fetchCountingStock: sl()));
  sl.registerFactory(
    () => StocktakeValidationBloc(fetchStocktakeAuditReport: sl()),
  );
  sl.registerFactory(
    () => SendingFinalStocktakeBloc(sendFinalStocktakeToRm: sl()),
  );
  sl.registerFactory(
    () => BatchCommitBloc(
      batchCommitStocktake: sl(),
      hasUnsyncedStocktakes: sl(),
      discoverHost: sl(),
    ),
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
      deleteAllStocktake: sl(),
      getCashDrawerIdentifier: sl(),
      saveCashDrawerIdentifier: sl(),
      exportDatabaseFile: sl(),
      importDatabaseFile: sl(),
      getRmVersion: sl(),
      clearSyncTimestamps: sl(),
    ),
  );
  sl.registerFactory(
    () => ThemeCubit(
      loadDarkModeEnabled: sl(),
      updateDarkModeEnabled: sl(),
    ),
  );
  sl.registerFactory(
    () => DashboardStyleCubit(
      loadDashboardStyle: sl(),
      updateDashboardStyle: sl(),
    ),
  );
  sl.registerFactory(
    () => FontSizeCubit(
      loadFontSize: sl(),
      updateFontSize: sl(),
    ),
  );
  sl.registerFactory(
    () => SessionCountsCubit(
      getSaleSessionCounts: sl(),
      getSaleSessionSummaries: sl(),
    ),
  );
  sl.registerFactory(() => DiscoverHostBloc(discoverHost: sl()));
  sl.registerFactory(() => PairCodeBloc(getPairCodes: sl()));
  sl.registerFactory(() => PairDeviceBloc(pairDevice: sl()));
  sl.registerFactory(
    () => StaffAuthBloc(
      authenticateStaff: sl(),
      loadSavedStaffSession: sl(),
      loadSavedConnectionInfo: sl(),
      loadSavedStaffCredentials: sl(),
      signOutStaff: sl(),
    ),
  );
  sl.registerFactory(() => StockDetailsBloc(fetchCountedStockById: sl()));
  sl.registerFactory(() => StockCountUpdateBloc(updateStockCount: sl()));
  sl.registerFactory(() => StockImageUploadBloc(uploadUseCase: sl()));
  sl.registerFactory(() => BackupStocktakeBloc(backupStocktake: sl()));
  sl.registerFactory(
    () => BackupRestoreBloc(loadSessions: sl(), restoreSession: sl()),
  );
  sl.registerFactory(() => StockUpdateBloc(updateSingleStock: sl()));
  sl.registerFactory(
    () => PendingStockUpdatesBloc(
      getPendingStockUpdatesCount: sl(),
      getPendingStockUpdates: sl(),
      sendPendingStockUpdates: sl(),
      deletePendingStockUpdates: sl(),
      getShopfrontName: sl(),
      seedStockSyncTimestamp: sl(),
    ),
  );
  sl.registerFactory(
    () => PendingCustomerUpdatesBloc(
      getPendingCustomerUpdatesCount: sl(),
      getPendingCustomerUpdates: sl(),
      getPendingCustomerCreationsCount: sl(),
      getPendingCustomerCreations: sl(),
      sendPendingCustomerUpdates: sl(),
      sendPendingCustomerCreations: sl(),
      resolveCustomerCreateConflicts: sl(),
      deletePendingCustomerUpdates: sl(),
      deletePendingCustomerCreations: sl(),
      getShopfrontName: sl(),
    ),
  );
  sl.registerFactory(() => StocktakeDeleteBloc(
    deleteStocktakeItem: sl(),
    deleteAllStocktake: sl(),
  ));
  sl.registerFactory(
    () => OnboardingBloc(
      getTermsAccepted: sl(),
      setTermsAccepted: sl(),
    ),
  );

  //Repos
  sl.registerLazySingleton<HomeRepo>(() => HomeScreenModels());
  sl.registerLazySingleton<CustomerLookupRepo>(() => CustomerLookupModels());
  sl.registerLazySingleton<StocktakeRepo>(() => StocktakeModel());
  sl.registerLazySingleton<LoadingSplashRepo>(() => LoadingSplashModels());
  sl.registerLazySingleton<StockLookupRepo>(() => StockLookupModels());
  sl.registerLazySingleton<OnboardingRepo>(() => OnboardingModels());
  sl.registerLazySingleton<SalesRepo>(() => SalesModel());

  //Use cases
  sl.registerLazySingleton(() => SearchStockForSale(sl()));
  sl.registerLazySingleton(() => SearchCustomerForSale(sl()));
  sl.registerLazySingleton(() => CheckLowStockWarning());
  sl.registerLazySingleton(() => CheckStockAvailability());
  sl.registerLazySingleton(() => ValidateOutOfStockItems());
  sl.registerLazySingleton(() => GetSaleSessions());
  sl.registerLazySingleton(() => SaveSaleSession());
  sl.registerLazySingleton(() => DeleteSaleSession());
  sl.registerLazySingleton(() => RestoreSaleSession());
  sl.registerLazySingleton(() => LoadSalesSettings());
  sl.registerLazySingleton(() => SaveSalesSetting());
  sl.registerLazySingleton(() => CreateAccountInvoice(sl()));
  sl.registerLazySingleton(() => CreateSalesOrder(sl()));
  sl.registerLazySingleton(() => CreateQuote(sl()));
  sl.registerLazySingleton(() => CreateLayby(sl()));
  sl.registerLazySingleton(() => sales_use_cases.GetCashDrawerIdentifier(sl()));
  sl.registerLazySingleton(() => CountAndSaveToLocaldb(sl()));
  sl.registerLazySingleton(() => FetchNetworkPcs(sl()));
  // SMB LEGACY - Commented out
  // sl.registerLazySingleton(() => GetToSharedFolder(sl()));
  // sl.registerLazySingleton(() => ConnectAndWriteToFolder(sl()));
  // sl.registerLazySingleton(() => FetchShopfrontList(sl()));
  sl.registerLazySingleton(() => FetchShopfrontsFromApi(sl()));
  // SMB LEGACY - Commented out
  // sl.registerLazySingleton(() => ConnectToShopfront(sl()));
  sl.registerLazySingleton(() => ConnectToShopfrontApi(sl()));
  sl.registerLazySingleton(() => FetchSavedPaths(sl()));
  sl.registerLazySingleton(() => CheckPathConnection(sl()));
  sl.registerLazySingleton(() => DeleteSavedPath(sl()));
  //sl.registerLazySingleton(() => FetchAllStocktakeList(sl()));
  sl.registerLazySingleton(() => CommitStocktake(sl()));
  sl.registerLazySingleton(() => BatchCommitStocktake(sl()));
  sl.registerLazySingleton(() => HasUnsyncedStocktakes(sl()));
  sl.registerLazySingleton(() => DeleteStocktakeItem(sl()));
  sl.registerLazySingleton(() => DeleteAllStocktake(sl()));
  // SMB LEGACY - Commented out
  // sl.registerLazySingleton(() => AutoConnectToDefaultFolder(sl()));
  // sl.registerLazySingleton(() => CheckIfShopfrontFileExists(sl()));
  sl.registerLazySingleton(() => FetchStockData(sl()));
  sl.registerLazySingleton(() => GetPaginatedStock(sl()));
  sl.registerLazySingleton(() => FetchCustomerData(sl()));
  sl.registerLazySingleton(() => FetchCustomerTransactions(sl()));
  sl.registerLazySingleton(() => FetchCustomerTransactionsByType(sl()));
  sl.registerLazySingleton(() => GetCustomerTransactionsLocal(sl()));
  sl.registerLazySingleton(() => CreateCustomer(sl()));
  sl.registerLazySingleton(() => GetPaginatedCustomers(sl()));
  sl.registerLazySingleton(() => GetCustomerFilterOptions(sl()));
  sl.registerLazySingleton(() => GetHostIpAddress(sl()));
  sl.registerLazySingleton(() => CheckBarcodeExists(sl()));
  sl.registerLazySingleton(() => GetNextNumericBarcode(sl()));
  sl.registerLazySingleton(() => GetNextCustomerId(sl()));
  sl.registerLazySingleton(() => GetNextCustomerAddressId(sl()));
  sl.registerLazySingleton(() => GetStaffByBarcode(sl()));
  sl.registerLazySingleton(() => GetStaffDetail(sl()));
  sl.registerLazySingleton(() => UpdateCustomerDetails(sl()));
  sl.registerLazySingleton(() => GetFilterOptions(sl()));
  sl.registerLazySingleton(() => FetchCountingStock(sl()));
  sl.registerLazySingleton(() => FetchStocktakeAuditReport(sl()));
  sl.registerLazySingleton(() => FetchStocktakeLimit(sl()));
  sl.registerLazySingleton(() => SendFinalStocktakeToRm(sl()));
  sl.registerLazySingleton(() => FetchThumbnail(sl()));
  sl.registerLazySingleton(() => FetchFullImage(sl()));
  sl.registerLazySingleton(() => ResolvePackageComponentStock(sl()));
  sl.registerLazySingleton(() => FetchStocktakeHistorySessions());
  sl.registerLazySingleton(() => FetchStocktakeHistoryItems());
  sl.registerLazySingleton(() => LoadRetentionDays(sl()));
  sl.registerLazySingleton(() => UpdateRetentionDays(sl()));
  sl.registerLazySingleton(() => CleanupHistory(sl()));
  sl.registerLazySingleton(() => LoadAutoBackupEnabled(sl()));
  sl.registerLazySingleton(() => UpdateAutoBackupEnabled(sl()));
  sl.registerLazySingleton(() => LoadDarkModeEnabled(sl()));
  sl.registerLazySingleton(() => UpdateDarkModeEnabled(sl()));
  sl.registerLazySingleton(() => LoadDashboardStyle(sl()));
  sl.registerLazySingleton(() => UpdateDashboardStyle(sl()));
  sl.registerLazySingleton(() => LoadFontSize(sl()));
  sl.registerLazySingleton(() => UpdateFontSize(sl()));
  sl.registerLazySingleton(() => ClearSyncTimestamps(sl()));
  sl.registerLazySingleton(() => GetSaleSessionCounts(sl()));
  sl.registerLazySingleton(() => GetSaleSessionSummaries(sl()));
  sl.registerLazySingleton(() => home_use_cases.GetCashDrawerIdentifier(sl()));
  sl.registerLazySingleton(() => SaveCashDrawerIdentifier(sl()));
  sl.registerLazySingleton(() => ExportDatabaseFile(sl()));
  sl.registerLazySingleton(() => ImportDatabaseFile(sl()));
  sl.registerLazySingleton(() => GetRmVersion(sl()));
  sl.registerLazySingleton(
    () => RunAutoBackupIfDue(repository: sl(), backupStocktake: sl()),
  );
  sl.registerLazySingleton(() => DiscoverHost(sl()));
  sl.registerLazySingleton(() => GetPairCodes(sl()));
  sl.registerLazySingleton(() => PairDevice(sl()));
  sl.registerLazySingleton(() => AuthenticateStaff(sl()));
  sl.registerLazySingleton(() => LoadSavedConnectionInfo(sl()));
  sl.registerLazySingleton(() => LoadSavedStaffCredentials(sl()));
  sl.registerLazySingleton(() => LoadSavedStaffSession(sl()));
  sl.registerLazySingleton(() => SignOutStaff(sl()));
  sl.registerLazySingleton(() => FetchCountedStockById(sl()));
  sl.registerLazySingleton(() => UpdateStockCount(sl()));
  sl.registerLazySingleton(() => FetchStocktakePage(sl()));
  sl.registerLazySingleton(() => UploadStockImageUseCase(sl()));
  sl.registerLazySingleton(() => BackupStocktake(sl()));
  sl.registerLazySingleton(() => LoadBackupSessions(sl()));
  sl.registerLazySingleton(() => RestoreBackupSession(sl()));
  sl.registerLazySingleton(() => UpdateSingleStock(sl()));
  sl.registerLazySingleton(() => GetPendingStockUpdates());
  sl.registerLazySingleton(() => GetPendingStockUpdatesCount());
  sl.registerLazySingleton(() => stock_lookup.GetShopfrontName(sl()));
  sl.registerLazySingleton(() => SeedStockSyncTimestamp(sl()));
  sl.registerLazySingleton(() => SendPendingStockUpdates(sl()));
  sl.registerLazySingleton(() => DeletePendingStockUpdates());
  sl.registerLazySingleton(() => GetTermsAccepted(sl()));
  sl.registerLazySingleton(() => SetTermsAccepted(sl()));
  sl.registerLazySingleton(() => GetPendingCustomerUpdates());
  sl.registerLazySingleton(() => GetPendingCustomerUpdatesCount());
  sl.registerLazySingleton(() => GetPendingCustomerCreations());
  sl.registerLazySingleton(() => GetPendingCustomerCreationsCount());
  sl.registerLazySingleton(() => customer_lookup.GetShopfrontName(sl()));
  sl.registerLazySingleton(() => SendPendingCustomerUpdates(sl()));
  sl.registerLazySingleton(() => SendPendingCustomerCreations(sl()));
  sl.registerLazySingleton(() => ResolveCustomerCreateConflicts());
  sl.registerLazySingleton(() => DeletePendingCustomerUpdates());
  sl.registerLazySingleton(() => DeletePendingCustomerCreations());
}
