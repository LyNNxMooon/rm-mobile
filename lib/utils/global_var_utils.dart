import 'package:flutter/foundation.dart';

class AppGlobals {
  AppGlobals._();

  static final AppGlobals instance = AppGlobals._();

  String? currentHostIp;
  String? currentPath;
  String? shopfront;
  String? salesCustom;
  String? shopfrontReminder;
  bool autoChargeSale = false;
  int? autoChargeSaleStock;
  int? autoChargeSalePercent;
  String? _hostName;
  final ValueNotifier<String?> hostNameNotifier = ValueNotifier<String?>(null);
  Map<String, String> pairedShopfrontIdsByName = {};
  bool securityEnabled = true;
  int? staffId;
  String? staffNo;
  String? staffName;
  List<int> staffGroupIds = <int>[];
  List<String> staffGroupNames = <String>[];
  Set<String> grantedPermissions = <String>{};
  Set<String> restrictedPermissions = <String>{};

  String stockCustom1Label = "Custom 1";
  String stockCustom2Label = "Custom 2";
  String customerCustom1Label = "Custom 1";
  String customerCustom2Label = "Custom 2";
  String customerStatusLabel = "Status";

  bool get isStaffSignedIn =>
      (staffNo ?? "").trim().isNotEmpty && (staffName ?? "").trim().isNotEmpty;

  String? get hostName => _hostName;
  set hostName(String? value) {
    _hostName = value;
    hostNameNotifier.value = value;
  }

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

  void updateCustomLabels({
    String? stock1,
    String? stock2,
    String? customer1,
    String? customer2,
    String? customer3,
  }) {
    stockCustom1Label = _applyLabel(stock1, stockCustom1Label);
    stockCustom2Label = _applyLabel(stock2, stockCustom2Label);
    customerCustom1Label = _applyLabel(customer1, customerCustom1Label);
    customerCustom2Label = _applyLabel(customer2, customerCustom2Label);
    customerStatusLabel = _applyLabel(customer3, customerStatusLabel);
  }

  String _applyLabel(String? incoming, String fallback) {
    final candidate = (incoming ?? "").trim();
    return candidate.isEmpty ? fallback : candidate;
  }

  /// Flag to track when ShopfrontsDialog is open (to prevent redirect on auth errors)
  bool isShopfrontDialogOpen = false;

  final String defaultLanFolder = "C/AAAPOS RM-Mobile";
  final String defaultUserName = "RM-Mobile-User";
  final String defaultPwd = "retailmanager";
}
