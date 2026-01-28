

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

