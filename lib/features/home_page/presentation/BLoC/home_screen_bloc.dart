import 'package:bloc/bloc.dart';
import 'package:rmstock_scanner/features/home_page/domain/use_cases/cleanup_history.dart';
import 'package:rmstock_scanner/features/home_page/domain/use_cases/discover_host.dart';
import 'package:rmstock_scanner/features/home_page/domain/use_cases/fetch_shopfront_list.dart';
import 'package:rmstock_scanner/features/home_page/domain/use_cases/fetch_shopfronts_from_api.dart';
import 'package:rmstock_scanner/features/home_page/domain/use_cases/connect_to_shopfront_api.dart';
import 'package:rmstock_scanner/features/home_page/domain/use_cases/get_pair_codes.dart';
import 'package:rmstock_scanner/features/home_page/domain/use_cases/pair_device.dart';
import 'package:rmstock_scanner/features/home_page/domain/use_cases/load_retention_days.dart';
import 'package:rmstock_scanner/features/home_page/domain/use_cases/update_retention_days.dart';
import 'package:rmstock_scanner/features/home_page/presentation/BLoC/home_screen_events.dart';
import 'package:rmstock_scanner/features/home_page/presentation/BLoC/home_screen_states.dart';
import 'package:rmstock_scanner/features/stock_lookup/domain/entities/sync_status.dart';
import '../../../../entities/vos/network_computer_vo.dart';
import '../../../../utils/log_utils.dart';
import '../../domain/use_cases/auto_connect_to_default_folder.dart';
import '../../domain/use_cases/connect_and_write_to_folder.dart';
import '../../domain/use_cases/connect_to_shopfront.dart';
import '../../domain/use_cases/fetch_network_pcs.dart';
import '../../domain/use_cases/fetch_stock_data.dart';
import '../../domain/use_cases/get_to_shared_folder.dart';

class FetchingNetworkPCBloc
    extends Bloc<HomeScreenEvents, FetchingNetworkPCStates> {
  final FetchNetworkPcs fetchNetworkPcs;

  FetchingNetworkPCBloc({required this.fetchNetworkPcs})
    : super(FetchingNetworkPCInitial()) {
    on<FetchNetworkPCEvent>(_onFetchNetworkPC);
  }

  Future<void> _onFetchNetworkPC(
    FetchNetworkPCEvent event,
    Emitter<FetchingNetworkPCStates> emit,
  ) async {
    emit(FetchingNetworkPCs());
    try {
      final pcList = await fetchNetworkPcs();

      emit(NetworkPCsLoaded(pcList: pcList));
    } catch (error) {
      emit(
        ErrorFetchingNetworkPCs(
          message: "Error fetching network computers: $error",
        ),
      );
    }
  }
}

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

class ShopfrontBloc extends Bloc<HomeScreenEvents, ShopFrontStates> {
  final FetchShopfrontList fetchShopfrontList;
  final FetchShopfrontsFromApi fetchShopfrontsFromApi;

  ShopfrontBloc({
    required this.fetchShopfrontList,
    required this.fetchShopfrontsFromApi,
  }) : super(ShopInitial()) {
    on<FetchShops>(_onFetchShops);
    on<FetchShopsFromApi>(_onFetchShopsFromApi);
  }

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
  final ConnectToShopfront connectToShopfront;
  final ConnectToShopfrontApi connectToShopfrontApi;

  ShopFrontConnectionBloc({
    required this.connectToShopfront,
    required this.connectToShopfrontApi,
  })
    : super(ConnectionInitial()) {
    on<ConnectToShopfrontEvent>(_onConnectToShopfront);
    on<ConnectToShopfrontApiEvent>(_onConnectToShopfrontApi);
  }

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
          NetworkComputerVO(
            ipAddress: event.ipAddress,
            hostName: event.hostName ?? "",
          ),
        ),
      );
    }
  }
}

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

  SettingsBloc({
    required this.loadRetentionDays,
    required this.updateRetentionDays,
    required this.cleanupHistory,
  }) : super(SettingsInitial()) {
    on<LoadSettingsEvent>(_onLoad);
    on<ChangeRetentionDaysEvent>(_onChangeRetention);
    on<RunHistoryCleanupEvent>(_onCleanup);
  }

  Future<void> _onLoad(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());
    try {
      final days = await loadRetentionDays();
      emit(SettingsLoaded(days));
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

      // Run cleanup immediately after change (so setting takes effect now)
      final deleted = await cleanupHistory();
      emit(
        SettingsCleanupDone(
          deletedSessions: deleted,
          retentionDays: event.days,
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
      final currentDays = await loadRetentionDays();
      final deleted = await cleanupHistory();
      emit(
        SettingsCleanupDone(
          deletedSessions: deleted,
          retentionDays: currentDays,
        ),
      );
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }
}

class DiscoverHostBloc extends Bloc<DiscoverHostEvents, DiscoverHostStates> {
  final DiscoverHost discoverHost;

  DiscoverHostBloc({required this.discoverHost}) : super(DiscoverHostInitial()) {
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
