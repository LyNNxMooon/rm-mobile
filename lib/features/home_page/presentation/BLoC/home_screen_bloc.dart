import 'package:bloc/bloc.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/cleanup_history.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/clear_sync_timestamps.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/discover_host.dart';
import 'package:rmmobile/entities/response/authenticate_staff_response.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/authenticate_staff.dart';
// SMB LEGACY - Commented out
// import 'package:rmmobile/features/home_page/domain/use_cases/fetch_shopfront_list.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/fetch_shopfronts_from_api.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/load_saved_staff_session.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/load_saved_connection_info.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/load_saved_staff_credentials.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/load_auto_backup_enabled.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/connect_to_shopfront_api.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/get_pair_codes.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/pair_device.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/sign_out_staff.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/load_retention_days.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/run_auto_backup_if_due.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/update_auto_backup_enabled.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/update_retention_days.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/get_cash_drawer_identifier.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/save_cash_drawer_identifier.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/export_database_file.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/import_database_file.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/get_rm_version.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/home_screen_events.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/home_screen_states.dart';
import 'package:rmmobile/features/stock_lookup/domain/entities/sync_status.dart';
import 'package:rmmobile/features/stocktake/domain/use_cases/delete_all_stocktake.dart';
// SMB LEGACY imports - Commented out
// import '../../../../entities/vos/network_server_vo.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../utils/log_utils.dart';
// import '../../domain/use_cases/auto_connect_to_default_folder.dart';
// import '../../domain/use_cases/connect_and_write_to_folder.dart';
// import '../../domain/use_cases/connect_to_shopfront.dart';
import '../../domain/use_cases/fetch_network_pcs.dart';
import '../../domain/use_cases/fetch_stock_data.dart';
// import '../../domain/use_cases/get_to_shared_folder.dart';

class FetchingNetworkServerBloc
    extends Bloc<HomeScreenEvents, FetchingNetworkServerStates> {
  final FetchNetworkPcs fetchNetworkPcs;

  FetchingNetworkServerBloc({required this.fetchNetworkPcs})
    : super(FetchingNetworkServerInitial()) {
    on<FetchNetworkServerEvent>(_onFetchNetworkServer);
  }

  Future<void> _onFetchNetworkServer(
    FetchNetworkServerEvent event,
    Emitter<FetchingNetworkServerStates> emit,
  ) async {
    emit(FetchingNetworkServers());
    try {
      final pcList = await fetchNetworkPcs();

      emit(NetworkServersLoaded(pcList: pcList));
    } catch (error) {
      emit(
        ErrorFetchingNetworkServers(
          message: "Error fetching network servers: $error",
        ),
      );
    }
  }
}

// ============================================================================
// SMB LEGACY BLOCS - Commented out (no longer used with API-based flow)
// ============================================================================

/*
class GettingDirectoryBloc
    extends Bloc<HomeScreenEvents, GettingDirectoryStates> {
  final GetToSharedFolder getToSharedFolder;

  GettingDirectoryBloc({required this.getToSharedFolder})
    : super(GettingDirectoryInitial()) {
    on<GetDirectoryEvent>(_onGetDirectoryEvent);
  }

  Future<void> _onGetDirectoryEvent(
    GetDirectoryEvent event,
    Emitter<GettingDirectoryStates> emit,
  ) async {
    emit(GettingDirectory());
    try {
      final folders = await getToSharedFolder(
        event.ipAddress,
        event.path,
        event.userName,
        event.pwd,
      );

      emit(DirectoryLoaded(directList: folders));
    } catch (error) {
      if (error is String) {
        emit(ErrorGettingDirectory(message: error));
      } else {
        var e = error as dynamic;
        emit(ErrorGettingDirectory(message: e.message.toString()));
      }
    }
  }
}

class ConnectingFolderBloc
    extends Bloc<HomeScreenEvents, ConnectingFolderStates> {
  final ConnectAndWriteToFolder connectAndWriteToFolder;

  ConnectingFolderBloc({required this.connectAndWriteToFolder})
    : super(ConnectingFolderInitial()) {
    on<ConnectToFolderEvent>(_onConnectFolderEvent);
  }

  Future<void> _onConnectFolderEvent(
    ConnectToFolderEvent event,
    Emitter<ConnectingFolderStates> emit,
  ) async {
    emit(ConnectingFolder(event.path));
    try {
      logger.d("What is the path after shopfront confrimation: ${event.path}");
      await connectAndWriteToFolder(
        event.ipAddress,
        event.hostName,
        event.path,
        event.userName,
        event.pwd,
      );

      emit(
        FolderConnected(
          message: "Connected to SharedFolder!",
          path: event.path,
        ),
      );
    } catch (e) {
      emit(ErrorConnectingFolder(message: e.toString()));
    }
  }
}
*/

class ShopfrontBloc extends Bloc<HomeScreenEvents, ShopFrontStates> {
  final FetchShopfrontsFromApi fetchShopfrontsFromApi;

  ShopfrontBloc({
    required this.fetchShopfrontsFromApi,
  }) : super(ShopInitial()) {
    // SMB LEGACY - _onFetchShops commented out
    // on<FetchShops>(_onFetchShops);
    on<FetchShopsFromApi>(_onFetchShopsFromApi);
  }

  /*
  // SMB LEGACY - Commented out
  Future<void> _onFetchShops(
    FetchShops event,
    Emitter<ShopFrontStates> emit,
  ) async {
    emit(ShopsLoading());
    try {
      logger.d("Bloc SF Path : ${event.path}");

      final shops = await fetchShopfrontList(
        event.ipAddress,
        event.path,
        event.userName,
        event.pwd,
      );

      emit(ShopsLoaded(shops));
    } catch (error) {
      emit(ShopsError("Error fetching shops: $error"));
    }
  }
  */

  Future<void> _onFetchShopsFromApi(
    FetchShopsFromApi event,
    Emitter<ShopFrontStates> emit,
  ) async {
    emit(ShopsLoading());
    try {
      final shops = await fetchShopfrontsFromApi(
        event.ipAddress,
        event.port,
        event.apiKey,
      );

      emit(ShopsLoaded(shops));
    } catch (error) {
      emit(ShopsError("Error fetching shops: $error"));
    }
  }
}

class ShopFrontConnectionBloc
    extends Bloc<HomeScreenEvents, ShopfrontConnectionStates> {
  // SMB LEGACY - ConnectToShopfront commented out
  // final ConnectToShopfront connectToShopfront;
  final ConnectToShopfrontApi connectToShopfrontApi;

  ShopFrontConnectionBloc({
    // required this.connectToShopfront,
    required this.connectToShopfrontApi,
  }) : super(ConnectionInitial()) {
    // SMB LEGACY - handler commented out
    // on<ConnectToShopfrontEvent>(_onConnectToShopfront);
    on<ConnectToShopfrontApiEvent>(_onConnectToShopfrontApi);
  }

  /*
  // SMB LEGACY - Commented out
  Future<void> _onConnectToShopfront(
    ConnectToShopfrontEvent event,
    Emitter<ShopfrontConnectionStates> emit,
  ) async {
    emit(ConnectingToShopfront());
    try {
      await connectToShopfront(
        event.ip,
        event.shopName,
        event.userName,
        event.pwd,
      );
      emit(ConnectedToShopfront("Shopfront Connected!"));
    } catch (error) {
      if (error is String) {
        emit(ShopfrontConnectionError(error));
      } else {
        var e = error as dynamic;
        emit(ShopfrontConnectionError(e.message.toString()));
      }
    }
  }
  */

  Future<void> _onConnectToShopfrontApi(
    ConnectToShopfrontApiEvent event,
    Emitter<ShopfrontConnectionStates> emit,
  ) async {
    emit(ConnectingToShopfront());
    try {
      final response = await connectToShopfrontApi(
        ip: event.ip,
        port: event.port,
        apiKey: event.apiKey,
        shopfrontId: event.shopfrontId,
        shopfrontName: event.shopfrontName,
      );

      if (response.success) {
        emit(ConnectedToShopfront(response.message));
      } else {
        emit(ShopfrontConnectionError(response.message));
      }
    } catch (error) {
      if (error is String) {
        emit(ShopfrontConnectionError(error));
      } else {
        var e = error as dynamic;
        emit(ShopfrontConnectionError(e.message.toString()));
      }
    }
  }
}

// ============================================================================
// SMB LEGACY BLOC - Commented out (no longer used with API-based flow)
// ============================================================================

/*
class AutoConnectionBloc extends Bloc<HomeScreenEvents, AutoConnectionStates> {
  final AutoConnectToDefaultFolder autoConnectToDefaultFolder;

  AutoConnectionBloc({required this.autoConnectToDefaultFolder})
    : super(AutoConnectionStatesInitial()) {
    on<AutoConnectToDefaultFolderEvent>(_onAutoConnectToPublicFolder);
  }

  Future<void> _onAutoConnectToPublicFolder(
    AutoConnectToDefaultFolderEvent event,
    Emitter<AutoConnectionStates> emit,
  ) async {
    logger.d('AutoConnection in bloc Was Triggered!');
    emit(LoadingAutoConnection(event.ipAddress));
    try {
      await autoConnectToDefaultFolder(event.ipAddress, event.hostName).then((
        value,
      ) {
        emit(AutoConnectedToPublicFolder("Connected to SharedFolder!"));
      });
    } catch (e) {
      emit(
        ErrorAutoConnection(
          e.toString(),
          NetworkServerVO(
            ipAddress: event.ipAddress,
            hostName: event.hostName ?? "",
          ),
        ),
      );
    }
  }
}
*/

class FetchStockBloc extends Bloc<FetchStockEvents, FetchStockStates> {
  final FetchStockData fetchStockData;

  FetchStockBloc({required this.fetchStockData}) : super(FetchStockInitial()) {
    on<StartSyncEvent>(_onStartSyncEvent);
  }

  Future<void> _onStartSyncEvent(
    StartSyncEvent event,
    Emitter<FetchStockStates> emit,
  ) async {
    if (state is FetchStockProgress) return;

    emit(
      FetchStockProgress(
        currentCount: 0,
        totalCount: 1,
        message: "Initializing connection...",
      ),
    );

    try {
      await emit.forEach<SyncStatus>(
        fetchStockData(event.ipAddress, event.username, event.password),
        onData: (status) {
          return FetchStockProgress(
            currentCount: status.processed,
            totalCount: status.total,
            message: status.message,
          );
        },
        onError: (error, stackTrace) {
          return FetchStockError(message: error.toString());
        },
      );

      if (state is FetchStockProgress) {
        emit(FetchStockSuccess());
        await Future.delayed(const Duration(seconds: 5));
        emit(FetchStockInitial());
      }
      // else if (state is FetchStockError) {
      //   await Future.delayed(const Duration(seconds: 3));
      //   emit(FetchStockInitial());
      // }
    } catch (e) {
      emit(FetchStockError(message: e.toString()));
      // await Future.delayed(const Duration(seconds: 3));
      // emit(FetchStockInitial());
    }
  }
}

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final LoadRetentionDays loadRetentionDays;
  final UpdateRetentionDays updateRetentionDays;
  final CleanupHistory cleanupHistory;
  final LoadAutoBackupEnabled loadAutoBackupEnabled;
  final UpdateAutoBackupEnabled updateAutoBackupEnabled;
  final RunAutoBackupIfDue runAutoBackupIfDue;
  final DeleteAllStocktake deleteAllStocktake;
  final GetCashDrawerIdentifier getCashDrawerIdentifier;
  final SaveCashDrawerIdentifier saveCashDrawerIdentifier;
  final ExportDatabaseFile exportDatabaseFile;
  final ImportDatabaseFile importDatabaseFile;
  final GetRmVersion getRmVersion;
  final ClearSyncTimestamps clearSyncTimestamps;

  int _currentRetentionDays = 30;
  bool _autoBackupEnabled = true;
  String _cashDrawerIdentifier = 'A';

  SettingsBloc({
    required this.loadRetentionDays,
    required this.updateRetentionDays,
    required this.cleanupHistory,
    required this.loadAutoBackupEnabled,
    required this.updateAutoBackupEnabled,
    required this.runAutoBackupIfDue,
    required this.deleteAllStocktake,
    required this.getCashDrawerIdentifier,
    required this.saveCashDrawerIdentifier,
    required this.exportDatabaseFile,
    required this.importDatabaseFile,
    required this.getRmVersion,
    required this.clearSyncTimestamps,
  }) : super(SettingsInitial()) {
    on<LoadSettingsEvent>(_onLoad);
    on<ChangeRetentionDaysEvent>(_onChangeRetention);
    on<RunHistoryCleanupEvent>(_onCleanup);
    on<ToggleAutoBackupEvent>(_onToggleAutoBackup);
    on<CheckAutoBackupNowEvent>(_onCheckAutoBackupNow);
    on<DeleteAllStocktakeEvent>(_onDeleteAllStocktake);
    on<LoadCashDrawerIdentifierEvent>(_onLoadCashDrawerIdentifier);
    on<SaveCashDrawerIdentifierEvent>(_onSaveCashDrawerIdentifier);
    on<ExportDatabaseEvent>(_onExportDatabase);
    on<ImportDatabaseEvent>(_onImportDatabase);
    on<LoadRmVersionEvent>(_onLoadRmVersion);
    on<ForceFullSyncEvent>(_onForceFullSync);
  }

  String get cashDrawerIdentifier => _cashDrawerIdentifier;

  Future<void> _onLoad(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());
    try {
      _currentRetentionDays = await loadRetentionDays();
      _autoBackupEnabled = await loadAutoBackupEnabled();
      emit(
        SettingsLoaded(
          _currentRetentionDays,
          autoBackupEnabled: _autoBackupEnabled,
        ),
      );
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onChangeRetention(
    ChangeRetentionDaysEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await updateRetentionDays(event.days);
      _currentRetentionDays = event.days;

      // Run cleanup immediately after change (so setting takes effect now)
      final deleted = await cleanupHistory();
      emit(
        SettingsCleanupDone(
          deletedSessions: deleted,
          retentionDays: _currentRetentionDays,
          autoBackupEnabled: _autoBackupEnabled,
        ),
      );
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onCleanup(
    RunHistoryCleanupEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      _currentRetentionDays = await loadRetentionDays();
      final deleted = await cleanupHistory();
      emit(
        SettingsCleanupDone(
          deletedSessions: deleted,
          retentionDays: _currentRetentionDays,
          autoBackupEnabled: _autoBackupEnabled,
        ),
      );
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onToggleAutoBackup(
    ToggleAutoBackupEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await updateAutoBackupEnabled(event.enabled);
      _autoBackupEnabled = event.enabled;
      emit(
        SettingsLoaded(
          _currentRetentionDays,
          autoBackupEnabled: _autoBackupEnabled,
        ),
      );
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onCheckAutoBackupNow(
    CheckAutoBackupNowEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final didBackup = await runAutoBackupIfDue(force: event.force);
      emit(
        AutoBackupRunDone(
          retentionDays: _currentRetentionDays,
          autoBackupEnabled: _autoBackupEnabled,
          didBackup: didBackup,
        ),
      );
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onDeleteAllStocktake(
    DeleteAllStocktakeEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await deleteAllStocktake();
      emit(SettingsStocktakeDeleted("All stocktake data deleted."));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onLoadCashDrawerIdentifier(
    LoadCashDrawerIdentifierEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final value = await getCashDrawerIdentifier();
      _cashDrawerIdentifier = (value != null && value.isNotEmpty) ? value : 'A';
      emit(CashDrawerIdentifierLoaded(
        identifier: _cashDrawerIdentifier,
        retentionDays: _currentRetentionDays,
        autoBackupEnabled: _autoBackupEnabled,
      ));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onSaveCashDrawerIdentifier(
    SaveCashDrawerIdentifierEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await saveCashDrawerIdentifier(event.identifier);
      _cashDrawerIdentifier = event.identifier;
      emit(CashDrawerIdentifierSaved(
        identifier: _cashDrawerIdentifier,
        retentionDays: _currentRetentionDays,
        autoBackupEnabled: _autoBackupEnabled,
      ));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onExportDatabase(
    ExportDatabaseEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      emit(DatabaseExported(
        path: await exportDatabaseFile(),
        retentionDays: _currentRetentionDays,
        autoBackupEnabled: _autoBackupEnabled,
      ));
    } catch (e) {
      emit(DatabaseExportError(
        message: e.toString(),
        retentionDays: _currentRetentionDays,
        autoBackupEnabled: _autoBackupEnabled,
      ));
    }
  }

  Future<void> _onImportDatabase(
    ImportDatabaseEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await importDatabaseFile(event.filePath);
      emit(DatabaseImported(
        retentionDays: _currentRetentionDays,
        autoBackupEnabled: _autoBackupEnabled,
      ));
    } catch (e) {
      emit(DatabaseImportError(
        message: e.toString(),
        retentionDays: _currentRetentionDays,
        autoBackupEnabled: _autoBackupEnabled,
      ));
    }
  }

  Future<void> _onLoadRmVersion(
    LoadRmVersionEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final version = await getRmVersion();
      emit(RmVersionLoaded(version: version));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onForceFullSync(
    ForceFullSyncEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      // Clear sync timestamps to force full sync
      await clearSyncTimestamps(event.shopfrontId);
      emit(ForceFullSyncTriggered(
        retentionDays: _currentRetentionDays,
        autoBackupEnabled: _autoBackupEnabled,
      ));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }
}

class DiscoverHostBloc extends Bloc<DiscoverHostEvents, DiscoverHostStates> {
  final DiscoverHost discoverHost;

  DiscoverHostBloc({required this.discoverHost})
    : super(DiscoverHostInitial()) {
    on<DiscoverHostEvent>(_onDiscoverHost);
  }

  Future<void> _onDiscoverHost(
    DiscoverHostEvent event,
    Emitter<DiscoverHostStates> emit,
  ) async {
    emit(DiscoveringHost());
    try {
      final response = await discoverHost(event.ip, event.port);
      emit(DiscoverHostLoaded(response));
    } catch (e) {
      emit(DiscoverHostError(e.toString()));
    }
  }
}

class PairCodeBloc extends Bloc<PairCodeEvents, PairCodeStates> {
  final GetPairCodes getPairCodes;

  PairCodeBloc({required this.getPairCodes}) : super(PairCodeInitial()) {
    on<GetPairCodesEvent>(_onGetPairCodes);
  }

  Future<void> _onGetPairCodes(
    GetPairCodesEvent event,
    Emitter<PairCodeStates> emit,
  ) async {
    emit(GettingPairCodes());
    try {
      final response = await getPairCodes(event.ip, event.port);
      emit(PairCodesLoaded(response));
    } catch (e) {
      emit(PairCodeError(e.toString()));
    }
  }
}

class PairDeviceBloc extends Bloc<PairDeviceEvents, PairDeviceStates> {
  final PairDevice pairDevice;

  PairDeviceBloc({required this.pairDevice}) : super(PairDeviceInitial()) {
    on<PairDeviceEvent>(_onPairDevice);
  }

  Future<void> _onPairDevice(
    PairDeviceEvent event,
    Emitter<PairDeviceStates> emit,
  ) async {
    emit(PairingDevice());
    try {
      final response = await pairDevice(
        ip: event.ip,
        hostName: event.hostName,
        port: event.port,
        pairingCode: event.pairingCode,
        isTablet: event.isTablet,
      );

      if (response.success) {
        emit(PairDeviceSuccess(response));
      } else {
        emit(PairDeviceError(response.message));
      }
    } catch (e) {
      emit(PairDeviceError(e.toString()));
    }
  }
}

class StaffAuthBloc extends Bloc<StaffAuthEvents, StaffAuthStates> {
  final AuthenticateStaff authenticateStaff;
  final LoadSavedStaffSession loadSavedStaffSession;
  final LoadSavedConnectionInfo loadSavedConnectionInfo;
  final LoadSavedStaffCredentials loadSavedStaffCredentials;
  final SignOutStaff signOutStaff;

  StaffAuthBloc({
    required this.authenticateStaff,
    required this.loadSavedStaffSession,
    required this.loadSavedConnectionInfo,
    required this.loadSavedStaffCredentials,
    required this.signOutStaff,
  }) : super(StaffAuthInitial()) {
    on<AuthenticateStaffEvent>(_onAuthenticateStaff);
    on<LoadSavedStaffSessionEvent>(_onLoadSavedStaffSession);
    on<LoadConnectionInfoEvent>(_onLoadConnectionInfo);
    on<LoadSavedStaffCredentialsEvent>(_onLoadSavedStaffCredentials);
    on<SignOutStaffEvent>(_onSignOutStaff);
  }

  Future<void> _onAuthenticateStaff(
    AuthenticateStaffEvent event,
    Emitter<StaffAuthStates> emit,
  ) async {
    logger.d(
      "StaffAuthBloc AuthenticateStaffEvent: ip=${event.ip} shopfront=${event.shopfrontId} staffNo=${event.staffNo}",
    );
    emit(StaffAuthenticating());
    try {
      final response = await authenticateStaff(
        ip: event.ip,
        port: event.port,
        apiKey: event.apiKey,
        shopfrontId: event.shopfrontId,
        shopfrontName: event.shopfrontName,
        staffNo: event.staffNo,
        password: event.password,
      );

      if (response.success) {
        emit(StaffAuthenticated(response));
      } else {
        emit(StaffUnauthenticated(response.message));
      }
    } catch (error) {
      emit(StaffAuthError(error.toString()));
    }
  }

  Future<void> _onLoadSavedStaffSession(
    LoadSavedStaffSessionEvent event,
    Emitter<StaffAuthStates> emit,
  ) async {
    try {
      final loaded = await loadSavedStaffSession();
      if (loaded && AppGlobals.instance.isStaffSignedIn) {
        emit(
          StaffAuthenticated(
            AuthenticateStaffResponse(
              success: true,
              message: "Authenticated",
              securityEnabled: AppGlobals.instance.securityEnabled,
              staff: null,
              groupIds: AppGlobals.instance.staffGroupIds,
              grantedPermissions: const <StaffPermission>[],
              restrictedPermissions: const <StaffPermission>[],
            ),
          ),
        );
      } else {
        emit(StaffUnauthenticated("Please sign in."));
      }
    } catch (error) {
      emit(StaffAuthError(error.toString()));
    }
  }

  Future<void> _onSignOutStaff(
    SignOutStaffEvent event,
    Emitter<StaffAuthStates> emit,
  ) async {
    try {
      await signOutStaff();
      emit(StaffSignedOut());
    } catch (error) {
      emit(StaffAuthError(error.toString()));
    }
  }

  Future<void> _onLoadConnectionInfo(
    LoadConnectionInfoEvent event,
    Emitter<StaffAuthStates> emit,
  ) async {
    try {
      final info = await loadSavedConnectionInfo();
      emit(
        StaffConnectionInfoLoaded(
          port: info.port,
          apiKey: info.apiKey,
          shopfrontId: info.shopfrontId,
          shopfrontName: info.shopfrontName,
        ),
      );
    } catch (error) {
      emit(StaffConnectionInfoError(error.toString()));
    }
  }

  Future<void> _onLoadSavedStaffCredentials(
    LoadSavedStaffCredentialsEvent event,
    Emitter<StaffAuthStates> emit,
  ) async {
    try {
      final creds = await loadSavedStaffCredentials();
      emit(
        StaffCredentialsLoaded(
          staffNo: creds.staffNo,
          password: creds.password,
        ),
      );
    } catch (error) {
      emit(StaffCredentialsError(error.toString()));
    }
  }
}
