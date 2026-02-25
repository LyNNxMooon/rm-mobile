class AppGlobals {
  AppGlobals._();

  static final AppGlobals instance = AppGlobals._();

  String? currentHostIp;
  String? currentPath;
  String? shopfront;
  String? hostName;
  Map<String, String> pairedShopfrontIdsByName = {};
  bool securityEnabled = true;
  int? staffId;
  String? staffNo;
  String? staffName;
  List<int> staffGroupIds = <int>[];
  List<String> staffGroupNames = <String>[];
  Set<String> grantedPermissions = <String>{};
  Set<String> restrictedPermissions = <String>{};

  bool get isStaffSignedIn =>
      (staffNo ?? "").trim().isNotEmpty && (staffName ?? "").trim().isNotEmpty;

  bool hasPermission(String permission) {
    if (!securityEnabled) return true;
    if (!isStaffSignedIn) return false;
    return grantedPermissions.contains(permission) &&
        !restrictedPermissions.contains(permission);
  }

  bool hasAnyPermission(List<String> permissions) {
    return permissions.any(hasPermission);
  }

  void clearStaffSession() {
    staffId = null;
    staffNo = null;
    staffName = null;
    staffGroupIds = <int>[];
    staffGroupNames = <String>[];
    grantedPermissions = <String>{};
    restrictedPermissions = <String>{};
  }

  final String defaultLanFolder = "C/AAAPOS RM-Mobile";
  final String defaultUserName = "RM-Mobile-User";
  final String defaultPwd = "retailmanager";
}
