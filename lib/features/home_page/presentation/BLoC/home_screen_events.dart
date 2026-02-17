

abstract class HomeScreenEvents {}

class FetchShops extends HomeScreenEvents {
  final String ipAddress;
  final String path;
  final String? userName;
  final String? pwd;

  FetchShops({
    required this.ipAddress,
    required this.path,
    this.userName,
    this.pwd,
  });
}

class ConnectToShopfrontEvent extends HomeScreenEvents {
  final String ip;
  final String shopName;
  final String? userName;
  final String? pwd;

  ConnectToShopfrontEvent({
    required this.ip,
    required this.shopName,
    this.userName,
    this.pwd,
  });
}

class FetchNetworkPCEvent extends HomeScreenEvents {}

class GetDirectoryEvent extends HomeScreenEvents {
  final String ipAddress;
  final String path;
  final String? userName;
  final String? pwd;

  GetDirectoryEvent({
    required this.ipAddress,
    required this.path,
    this.userName,
    this.pwd,
  });
}

class ConnectToFolderEvent extends HomeScreenEvents {
  final String ipAddress;
  final String? hostName;
  final String path;
  final String? userName;
  final String? pwd;

  ConnectToFolderEvent({
    required this.ipAddress,
    required this.hostName,
    required this.path,
    this.userName,
    this.pwd,
  });
}

class AutoConnectToDefaultFolderEvent extends HomeScreenEvents {
  final String ipAddress;
  final String? hostName;

  AutoConnectToDefaultFolderEvent({required this.ipAddress, this.hostName});
}

class FetchStockDataEvent extends HomeScreenEvents {
  final String ipAddress;
  final String? userName;
  final String? pwd;

  FetchStockDataEvent({required this.ipAddress, this.userName, this.pwd});
}


abstract class FetchStockEvents {}

class StartSyncEvent extends FetchStockEvents {
  final String ipAddress;
  final String? username;
  final String? password;

  StartSyncEvent({
    required this.ipAddress,
    this.username,
    this.password,
  });


}


abstract class SettingsEvent {}

class LoadSettingsEvent extends SettingsEvent {}

class ChangeRetentionDaysEvent extends SettingsEvent {
  final int days;
  ChangeRetentionDaysEvent(this.days);
}

class RunHistoryCleanupEvent extends SettingsEvent {}

abstract class DiscoverHostEvents {}

class DiscoverHostEvent extends DiscoverHostEvents {
  final String ip;
  final int port;

  DiscoverHostEvent({required this.ip, required this.port});
}

abstract class PairCodeEvents {}

class GetPairCodesEvent extends PairCodeEvents {
  final String ip;
  final int port;

  GetPairCodesEvent({required this.ip, required this.port});
}

abstract class PairDeviceEvents {}

class PairDeviceEvent extends PairDeviceEvents {
  final String ip;
  final String hostName;
  final int port;
  final String pairingCode;

  PairDeviceEvent({
    required this.ip,
    required this.hostName,
    required this.port,
    required this.pairingCode,
  });
}

class ConnectToShopfrontApiEvent extends HomeScreenEvents {
  final String ip;
  final int port;
  final String apiKey;
  final String shopfrontId;
  final String shopfrontName;

  ConnectToShopfrontApiEvent({
    required this.ip,
    required this.port,
    required this.apiKey,
    required this.shopfrontId,
    required this.shopfrontName,
  });
}

class FetchShopsFromApi extends HomeScreenEvents {
  final String ipAddress;
  final int port;
  final String apiKey;

  FetchShopsFromApi({
    required this.ipAddress,
    required this.port,
    required this.apiKey,
  });
}

