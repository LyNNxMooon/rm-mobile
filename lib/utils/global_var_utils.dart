class AppGlobals {
  AppGlobals._();

  static final AppGlobals instance = AppGlobals._();

  String? currentHostIp;
  String? currentPath;
  String? shopfront;
  String? hostName;
  Map<String, String> pairedShopfrontIdsByName = {};

 final String defaultLanFolder = "C/AAAPOS RM-Mobile";
 final String defaultUserName = "RM-Mobile-User";
 final String defaultPwd = "retailmanager";
}
