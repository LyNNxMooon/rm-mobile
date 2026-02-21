import 'package:rmstock_scanner/entities/response/discover_response.dart';
import 'package:rmstock_scanner/entities/response/paircode_response.dart';
import 'package:rmstock_scanner/entities/response/pair_response.dart';
import 'package:rmstock_scanner/entities/response/shopfront_response.dart';
import 'package:rmstock_scanner/entities/vos/network_computer_vo.dart';

//Network PCs fetching states
abstract class FetchingNetworkPCStates {}

class FetchingNetworkPCInitial extends FetchingNetworkPCStates {}

class FetchingNetworkPCs extends FetchingNetworkPCStates {}

class NetworkPCsLoaded extends FetchingNetworkPCStates {
  final List<NetworkComputerVO> pcList;

  NetworkPCsLoaded({required this.pcList});
}

class ErrorFetchingNetworkPCs extends FetchingNetworkPCStates {
  final String message;

  ErrorFetchingNetworkPCs({required this.message});
}

//directory fetching states
abstract class GettingDirectoryStates {}

class GettingDirectoryInitial extends GettingDirectoryStates {}

class GettingDirectory extends GettingDirectoryStates {}

class DirectoryLoaded extends GettingDirectoryStates {
  final List<String> directList;

  DirectoryLoaded({required this.directList});
}

class ErrorGettingDirectory extends GettingDirectoryStates {
  final String message;

  ErrorGettingDirectory({required this.message});
}

//directory fetching states
abstract class ConnectingFolderStates {}

class ConnectingFolderInitial extends ConnectingFolderStates {}

class ConnectingFolder extends ConnectingFolderStates {
  final String lastDirect;

  ConnectingFolder(this.lastDirect);
}

class FolderConnected extends ConnectingFolderStates {
  final String message;
  final String path;

  FolderConnected({required this.path,required this.message});
}

class ErrorConnectingFolder extends ConnectingFolderStates {
  final String message;

  ErrorConnectingFolder({required this.message});
}

//Fetching shopfronts
abstract class ShopFrontStates {}

class ShopInitial extends ShopFrontStates {}

class ShopsLoading extends ShopFrontStates {}

class ShopsError extends ShopFrontStates {
  final String message;
  ShopsError(this.message);
}

class ShopsLoaded extends ShopFrontStates {
  final ShopfrontResponse shops;

  ShopsLoaded(this.shops);
}

//Shopfront connection
abstract class ShopfrontConnectionStates {}

class ConnectionInitial extends ShopfrontConnectionStates {}

class ConnectingToShopfront extends ShopfrontConnectionStates {}

class ShopfrontConnectionError extends ShopfrontConnectionStates {
  final String message;
  ShopfrontConnectionError(this.message);
}

class ConnectedToShopfront extends ShopfrontConnectionStates {
  final String message;

  ConnectedToShopfront(this.message);
}

//Auto Connection
abstract class AutoConnectionStates {}

class AutoConnectionStatesInitial extends AutoConnectionStates {}

class LoadingAutoConnection extends AutoConnectionStates {
  final String ipAddress;

  LoadingAutoConnection(this.ipAddress);
}

class AutoConnectedToPublicFolder extends AutoConnectionStates {
  final String message;

  AutoConnectedToPublicFolder(this.message);
}

class ErrorAutoConnection extends AutoConnectionStates {
  final NetworkComputerVO pcHolder;
  final String message;

  ErrorAutoConnection(this.message, this.pcHolder);
}

abstract class FetchStockStates {}

class FetchStockInitial extends FetchStockStates {}

class FetchStockProgress extends FetchStockStates {
  final int currentCount;
  final int totalCount;
  final String message;
  final double percentage;

  FetchStockProgress({
    required this.currentCount,
    required this.totalCount,
    required this.message,
  }) : percentage = totalCount == 0 ? 0 : (currentCount / totalCount);
}

class FetchStockSuccess extends FetchStockStates {
  final String message;
  FetchStockSuccess({this.message = "Sync Completed Successfully!"});
}

class FetchStockError extends FetchStockStates {
  final String message;
  FetchStockError({required this.message});
}

abstract class SettingsState {}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final int retentionDays;
  final bool autoBackupEnabled;
  SettingsLoaded(this.retentionDays, {required this.autoBackupEnabled});
}

class SettingsError extends SettingsState {
  final String message;
  SettingsError(this.message);
}

class SettingsCleanupDone extends SettingsState {
  final int deletedSessions;
  final int retentionDays;
  final bool autoBackupEnabled;
  SettingsCleanupDone({
    required this.deletedSessions,
    required this.retentionDays,
    required this.autoBackupEnabled,
  });
}

class AutoBackupRunDone extends SettingsState {
  final int retentionDays;
  final bool autoBackupEnabled;
  final bool didBackup;

  AutoBackupRunDone({
    required this.retentionDays,
    required this.autoBackupEnabled,
    required this.didBackup,
  });
}

abstract class DiscoverHostStates {}

class DiscoverHostInitial extends DiscoverHostStates {}

class DiscoveringHost extends DiscoverHostStates {}

class DiscoverHostLoaded extends DiscoverHostStates {
  final DiscoverResponse response;

  DiscoverHostLoaded(this.response);
}

class DiscoverHostError extends DiscoverHostStates {
  final String message;

  DiscoverHostError(this.message);
}

abstract class PairCodeStates {}

class PairCodeInitial extends PairCodeStates {}

class GettingPairCodes extends PairCodeStates {}

class PairCodesLoaded extends PairCodeStates {
  final PaircodeResponse response;

  PairCodesLoaded(this.response);
}

class PairCodeError extends PairCodeStates {
  final String message;

  PairCodeError(this.message);
}

abstract class PairDeviceStates {}

class PairDeviceInitial extends PairDeviceStates {}

class PairingDevice extends PairDeviceStates {}

class PairDeviceSuccess extends PairDeviceStates {
  final PairResponse response;

  PairDeviceSuccess(this.response);
}

class PairDeviceError extends PairDeviceStates {
  final String message;

  PairDeviceError(this.message);
}
