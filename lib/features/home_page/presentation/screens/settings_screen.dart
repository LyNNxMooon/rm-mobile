import 'dart:ui';
import 'dart:async';
import 'package:alert_info/alert_info.dart';
import 'package:file_selector/file_selector.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_lookup_states.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/entities/vos/network_server_vo.dart';
import 'package:rmmobile/features/theme/presentation/bloc/theme_cubit.dart';
//import 'package:rmmobile/features/home_page/presentation/BLoC/dashboard_style_cubit.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/font_size_cubit.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/home_screen_bloc.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/home_screen_events.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/home_screen_states.dart';
import 'package:rmmobile/features/home_page/presentation/widgets/restore_backup_dialog.dart';
import 'package:rmmobile/features/home_page/presentation/widgets/shopfronts_dialog.dart';
import 'package:rmmobile/utils/navigation_extension.dart';
import 'package:rmmobile/utils/sync_utils.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/modern_dialog_styles.dart';
import '../../../../constants/standard_dialog.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../local_db/local_db_dao.dart';
import '../../../../local_db/sqlite/sqlite_constants.dart';
import '../../../../utils/dialog_size_utils.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../stocktake/presentation/BLoC/stocktake_bloc.dart';
import '../../../stocktake/presentation/BLoC/stocktake_events.dart';
import '../../../stocktake/presentation/widgets/delete_all_confirmation_dialog.dart';
import '../../../customer_lookup/presentation/BLoC/customer_lookup_bloc.dart';
import 'staff_login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const int _defaultAgentPort = 5000;
  static const String _kCashDrawerIdentifierKey = "cash_drawer_identifier";

  double retentionDays = 30;
  bool backupToLan = true;
  bool _autoRemindServerConnection = true;
  String _cashDrawerIdentifier = "A";

  final TextEditingController _manualIpController = TextEditingController();
  final TextEditingController _manualCodeController = TextEditingController();
  final TextEditingController _manualPortController = TextEditingController(
    text: _defaultAgentPort.toString(),
  );

  bool _isManualConnectionFlow = false;
  int _selectedPort = _defaultAgentPort;
  String _selectedIp = "";
  String _selectedHostName = "";
  Timer? _autoBackupTimer;
  int? _savedPort;
  String _savedApiKey = "";
  String _savedShopfrontId = "";
  String _savedShopfrontName = "";
  bool _isRefreshingShopfront = false;
  bool _isForceFullSyncInProgress = false;

  bool _isSyncInProgress(BuildContext context) {
    return context.read<FetchStockBloc>().state is FetchStockProgress ||
        context.read<FetchCustomerBloc>().state is FetchCustomerProgress;
  }

  bool _blockIfSyncing(BuildContext context) {
    if (!_isSyncInProgress(context)) return false;
    _showError(context, "Sync in progress. Please wait.");
    return true;
  }

  @override
  void initState() {
    super.initState();
    context.read<StaffAuthBloc>().add(LoadConnectionInfoEvent());
    context.read<SettingsBloc>().add(LoadSettingsEvent());
    context.read<SettingsBloc>().add(CheckAutoBackupNowEvent());
    _autoBackupTimer = Timer.periodic(const Duration(hours: 1), (_) {
      if (!mounted) return;
      context.read<SettingsBloc>().add(CheckAutoBackupNowEvent());
    });
    context.read<SettingsBloc>().add(LoadCashDrawerIdentifierEvent());
    _loadAutoRemindServerConnection();
  }

  @override
  void dispose() {
    _autoBackupTimer?.cancel();
    _manualIpController.dispose();
    _manualCodeController.dispose();
    _manualPortController.dispose();
    super.dispose();
  }

  Future<void> _loadAutoRemindServerConnection() async {
    final raw = await LocalDbDAO.instance.getAppConfig(
      kAutoRemindServerConnectionKey,
    );
    final bool value = raw == null || raw.isEmpty
        ? true
        : raw.toLowerCase() == "true";
    if (!mounted) return;
    setState(() => _autoRemindServerConnection = value);
  }

  Future<void> _saveAutoRemindServerConnection(bool value) async {
    setState(() => _autoRemindServerConnection = value);
    await LocalDbDAO.instance.saveAppConfig(
      kAutoRemindServerConnectionKey,
      value.toString(),
    );
  }

  void _showError(BuildContext context, String message) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.error(message: message),
    );
  }

  void _saveCashDrawerIdentifier(String value) {
    setState(() {
      _cashDrawerIdentifier = value;
    });
    context.read<SettingsBloc>().add(SaveCashDrawerIdentifierEvent(value));
  }

  String _getShopfrontLabel() {
    final shop = AppGlobals.instance.shopfront;
    if (shop == null || shop.isEmpty) {
      return "No shopfront selected";
    }
    return shop.split(r'\\').last;
  }

  void _openShopfrontPicker(BuildContext context) {
    if (_blockIfSyncing(context)) return;

    final String hostIp = AppGlobals.instance.currentHostIp ?? "";

    if (hostIp.isEmpty || _savedApiKey.isEmpty || _savedPort == null) {
      _showError(context, "Connection info missing. Please reconnect to host.");
      return;
    }

    context.read<ShopfrontBloc>().add(
      FetchShopsFromApi(
        ipAddress: hostIp,
        port: _savedPort!,
        apiKey: _savedApiKey,
      ),
    );

    showDialog(
      context: context,
      builder: (_) => ShopfrontsDialog(
        pc: NetworkServerVO(
          ipAddress: hostIp,
          hostName: AppGlobals.instance.hostName ?? "",
        ),
        previousPath: "",
        isPairedFlow: true,
        port: _savedPort,
        apiKey: _savedApiKey,
      ),
    );
  }

  void _refreshShopfront(BuildContext context) {
    if (_blockIfSyncing(context)) return;

    final String hostIp = AppGlobals.instance.currentHostIp ?? "";
    final String shopfrontId = _savedShopfrontId;
    final String shopfrontName = _savedShopfrontName;

    if (hostIp.isEmpty || _savedApiKey.isEmpty || _savedPort == null) {
      _showError(context, "Connection info missing. Please reconnect to host.");
      return;
    }

    if (shopfrontId.isEmpty) {
      _showError(context, "No shopfront selected.");
      return;
    }

    context.read<ShopFrontConnectionBloc>().add(
      ConnectToShopfrontApiEvent(
        ip: hostIp,
        port: _savedPort!,
        apiKey: _savedApiKey,
        shopfrontId: shopfrontId,
        shopfrontName: shopfrontName,
      ),
    );
  }

  void _startManualConnection(BuildContext context) {
    final ip = _manualIpController.text.trim();
    final code = _manualCodeController.text.trim();
    final portText = _manualPortController.text.trim();

    if (ip.isEmpty) {
      _showError(context, "Please enter host IP.");
      return;
    }
    if (code.isEmpty) {
      _showError(context, "Please enter pairing code.");
      return;
    }

    int port = _defaultAgentPort;
    if (portText.isNotEmpty) {
      final parsedPort = int.tryParse(portText);
      if (parsedPort == null || parsedPort <= 0 || parsedPort > 65535) {
        _showError(context, "Please enter a valid port (1-65535).");
        return;
      }
      port = parsedPort;
    }

    _selectedIp = ip;
    _selectedHostName = ip;
    _selectedPort = port;
    _isManualConnectionFlow = true;

    context.read<DiscoverHostBloc>().add(
      DiscoverHostEvent(ip: _selectedIp, port: _selectedPort),
    );
  }

  void _showManualConnectionDialog(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool useDesktopNav = context.useDesktopNav;
    final double labelFontSize = useDesktopNav ? 11.0 : 13.0;
    final double inputFontSize = useDesktopNav ? 13.0 : 15.0;
    final double buttonFontSize = useDesktopNav ? 13.0 : 15.0;
    final double iconSize = useDesktopNav ? 18.0 : 20.0;
    _manualIpController.text = "";
    _manualCodeController.text = "";
    _manualPortController.text = _defaultAgentPort.toString();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final keyboardHeight = MediaQuery.of(dialogContext).viewInsets.bottom;
        final screenHeight = MediaQuery.of(dialogContext).size.height;
        final availableHeight = screenHeight - keyboardHeight - 48; // 48 for safe padding
        final double maxDialogHeight = (availableHeight * 0.85).clamp(380.0, 620.0);
        
        return Dialog(
        insetPadding: dialogInsetPadding(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernDialogStyles.dialogRadius),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: ModernDialogContainer(
          maxHeight: maxDialogHeight,
          maxWidth: context.useDesktopNav ? 520 : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modern header
              ModernDialogHeader(
                title: "Manual Connection",
                icon: Icons.link_rounded,
                subtitle: "Enter server details to connect",
                trailing: IconButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.white70 : kPrimaryColor,
                  ),
                  tooltip: "Close",
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(useDesktopNav ? 20 : 24),
                  child: Column(
                    children: [
                      // Host IP input
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Host IP Address",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : colors.onSurface,
                            fontSize: labelFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _manualIpController,
                        textAlignVertical: TextAlignVertical.center,
                        style: TextStyle(
                          color: isDark ? Colors.white : colors.onSurface,
                          fontSize: inputFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                        onEditingComplete: () {
                          final trimmedValue = _manualIpController.text.trim();
                          if (_manualIpController.text != trimmedValue) {
                            _manualIpController.value = _manualIpController
                                .value
                                .copyWith(
                                  text: trimmedValue,
                                  selection: TextSelection.collapsed(
                                    offset: trimmedValue.length,
                                  ),
                                );
                          }
                        },
                        decoration: ModernDialogStyles.inputDecoration(
                          context,
                          hintText: "Eg: 192.168.1.10",
                          prefixIcon: Icons.computer_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Pairing code input
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Pairing Code",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : colors.onSurface,
                            fontSize: labelFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _manualCodeController,
                        textAlignVertical: TextAlignVertical.center,
                        style: TextStyle(
                          color: isDark ? Colors.white : colors.onSurface,
                          fontSize: inputFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                        onEditingComplete: () {
                          final trimmedValue = _manualCodeController.text
                              .trim();
                          if (_manualCodeController.text != trimmedValue) {
                            _manualCodeController.value = _manualCodeController
                                .value
                                .copyWith(
                                  text: trimmedValue,
                                  selection: TextSelection.collapsed(
                                    offset: trimmedValue.length,
                                  ),
                                );
                          }
                        },
                        decoration: ModernDialogStyles.inputDecoration(
                          context,
                          hintText: "Eg: 123456",
                          prefixIcon: Icons.key_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Port input (optional)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Port",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : colors.onSurface,
                            fontSize: labelFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _manualPortController,
                        keyboardType: TextInputType.number,
                        textAlignVertical: TextAlignVertical.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: TextStyle(
                          color: isDark ? Colors.white : colors.onSurface,
                          fontSize: inputFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                        onEditingComplete: () {
                          final trimmedValue = _manualPortController.text
                              .trim();
                          if (_manualPortController.text != trimmedValue) {
                            _manualPortController.value = _manualPortController
                                .value
                                .copyWith(
                                  text: trimmedValue,
                                  selection: TextSelection.collapsed(
                                    offset: trimmedValue.length,
                                  ),
                                );
                          }
                        },
                        decoration: ModernDialogStyles.inputDecoration(
                          context,
                          hintText: "Eg: 5000",
                          prefixIcon: Icons.numbers_rounded,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Connect button with gradient
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: ModernDialogStyles.headerGradient,
                            borderRadius: BorderRadius.circular(
                              ModernDialogStyles.buttonRadius,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryColor.withOpacity(0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _startManualConnection(context),
                              borderRadius: BorderRadius.circular(
                                ModernDialogStyles.buttonRadius,
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: useDesktopNav ? 12 : 16,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.wifi_tethering_rounded,
                                      color: Colors.white,
                                      size: iconSize,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Connect",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: buttonFontSize,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return MultiBlocListener(
      listeners: [
        BlocListener<SettingsBloc, SettingsState>(
          listener: (context, state) async {
            if (state is SettingsStocktakeDeleted) {
              context.read<FetchingStocktakeListBloc>().add(
                FetchStocktakeListEvent(),
              );
              AlertInfo.show(
                context: context,
                text: state.message,
                typeInfo: TypeInfo.success,
                backgroundColor: colors.surface,
                iconColor: kPrimaryColor,
                textColor: colors.onSurface,
                position: MessagePosition.top,
                padding: 70,
              );
            }
            if (state is CashDrawerIdentifierLoaded) {
              setState(() {
                _cashDrawerIdentifier = state.identifier;
              });
            }
            if (state is SettingsError && _isForceFullSyncInProgress) {
              setState(() {
                _isForceFullSyncInProgress = false;
              });
              _showError(context, state.message);
            }
            if (state is DatabaseExported) {
              final xFile = XFile(state.path);
              await Share.shareXFiles(
                [xFile],
                subject: 'RM Mobile Database Export',
                text: 'Exported database file from RM Mobile app',
              );
            }
            if (state is DatabaseExportError) {
              showTopSnackBar(
                Overlay.of(context),
                CustomSnackBar.error(message: state.message),
              );
            }
            if (state is DatabaseImported) {
              AlertInfo.show(
                context: context,
                text: "Database imported successfully. Please restart the app.",
                typeInfo: TypeInfo.success,
                backgroundColor: colors.surface,
                iconColor: kPrimaryColor,
                textColor: colors.onSurface,
                position: MessagePosition.top,
                padding: 70,
              );
            }
            if (state is DatabaseImportError) {
              showTopSnackBar(
                Overlay.of(context),
                CustomSnackBar.error(message: state.message),
              );
            }
            if (state is ForceFullSyncTriggered) {
              setState(() {
                _isForceFullSyncInProgress = false;
              });
              // Trigger both stock and customer syncs
              runSequentialStockThenCustomerSync(context);
              AlertInfo.show(
                context: context,
                text: "Full sync started for stocks and customers",
                typeInfo: TypeInfo.info,
                backgroundColor: colors.surface,
                iconColor: kPrimaryColor,
                textColor: colors.onSurface,
                position: MessagePosition.top,
                padding: 70,
              );
            }
          },
        ),
        BlocListener<DiscoverHostBloc, DiscoverHostStates>(
          listener: (context, state) {
            if (!_isManualConnectionFlow) return;

            if (state is DiscoverHostLoaded) {
              if (!state.response.isAgent) {
                _showError(context, "Selected host is not a valid RM agent.");
                return;
              }

              _selectedPort = state.response.port;
              _selectedHostName = state.response.serverName;

              context.read<PairDeviceBloc>().add(
                PairDeviceEvent(
                  ip: _selectedIp,
                  hostName: _selectedHostName,
                  port: _selectedPort,
                  pairingCode: _manualCodeController.text.trim(),
                  isTablet: context.isTablet,
                ),
              );
            }

            if (state is DiscoverHostError) {
              _showError(context, state.message);
              // Port field is now in the Manual Connection dialog
            }
          },
        ),
        BlocListener<PairDeviceBloc, PairDeviceStates>(
          listener: (context, state) {
            if (!_isManualConnectionFlow) return;

            if (state is PairDeviceSuccess) {
              final navigator = Navigator.of(context, rootNavigator: true);
              navigator.popUntil((route) => route is! PopupRoute);

              // Save cash drawer from API response if available
              if (state.response.cashDrawer != null &&
                  state.response.cashDrawer!.isNotEmpty) {
                context.read<SettingsBloc>().add(
                  SaveCashDrawerIdentifierEvent(state.response.cashDrawer!),
                );
                setState(() {
                  _cashDrawerIdentifier = state.response.cashDrawer!;
                });
              }

              setState(() {
                _savedPort = _selectedPort;
                _savedApiKey = state.response.apiKey;
              });

              context.read<ShopfrontBloc>().add(
                FetchShopsFromApi(
                  ipAddress: _selectedIp,
                  port: _selectedPort,
                  apiKey: state.response.apiKey,
                ),
              );

              showDialog(
                //barrierDismissible: false,
                context: context,
                builder: (_) => ShopfrontsDialog(
                  pc: NetworkServerVO(
                    ipAddress: _selectedIp,
                    hostName: _selectedHostName,
                  ),
                  previousPath: "",
                  isPairedFlow: true,
                  port: _selectedPort,
                  apiKey: state.response.apiKey,
                ),
              );

              AlertInfo.show(
                context: context,
                text: state.response.message,
                typeInfo: TypeInfo.success,
                backgroundColor: colors.surface,
                iconColor: kPrimaryColor,
                textColor: colors.onSurface,
                padding: 70,
                position: MessagePosition.top,
              );

              _isManualConnectionFlow = false;
            }

            if (state is PairDeviceError) {
              _showError(context, state.message);
            }
          },
        ),
        BlocListener<ShopFrontConnectionBloc, ShopfrontConnectionStates>(
          listener: (context, state) {
            if (state is ConnectingToShopfront) {
              setState(() => _isRefreshingShopfront = true);
            }

            if (state is ConnectedToShopfront) {
              setState(() => _isRefreshingShopfront = false);
              final colors = context.appColors;
              AlertInfo.show(
                context: context,
                text: 'Shopfront refreshed successfully',
                typeInfo: TypeInfo.success,
                backgroundColor: colors.surface,
                iconColor: kPrimaryColor,
                textColor: colors.onSurface,
                position: MessagePosition.top,
                padding: 70,
              );
            }

            if (state is ShopfrontConnectionError) {
              setState(() => _isRefreshingShopfront = false);
              _showError(context, state.message);
            }
          },
        ),
        BlocListener<StaffAuthBloc, StaffAuthStates>(
          listener: (context, state) async {
            if (state is StaffConnectionInfoLoaded) {
              setState(() {
                _savedPort = state.port;
                _savedApiKey = state.apiKey;
                _savedShopfrontId = state.shopfrontId;
                _savedShopfrontName = state.shopfrontName;
              });
            }

            if (state is StaffSignedOut) {
              if (!mounted) return;
              await context.navigateToNext(const StaffLoginScreen());
              if (!mounted) return;
              setState(() {});
            }

            if (state is StaffAuthenticated) {
              if (!mounted) return;
              setState(() {});
            }
          },
        ),
      ],
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(color: Color.fromRGBO(7, 27, 54, 1)),
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: context.useDesktopNav ? 50 : 20,
                      vertical: 10,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: context.useDesktopNav ? 1000 : double.infinity,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),

                            _buildSectionTitle("Server Info"),
                        _buildGlassContainer(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 12,
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: kPrimaryColor.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.dns_outlined,
                                            size: 20,
                                            color: context.appColors.isDark
                                                ? Colors.white
                                                : context.appColors.onHero,
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Server Name",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: context.appColors.isDark
                                                      ? Colors.white70
                                                      : context.appColors.onHero,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                (AppGlobals.instance.hostName ?? "").isEmpty
                                                    ? "Not connected"
                                                    : AppGlobals.instance.hostName!,
                                                style: getSmartTitle(
                                                  fontSize: 14,
                                                  color: context.appColors.isDark
                                                      ? Colors.white
                                                      : context.appColors.onHero,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: kPrimaryColor.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.cloud_outlined,
                                            size: 20,
                                            color: context.appColors.isDark
                                                ? Colors.white
                                                : context.appColors.onHero,
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Server IP",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: context.appColors.isDark
                                                      ? Colors.white70
                                                      : context.appColors.onHero,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                (AppGlobals.instance.currentHostIp ?? "").isEmpty
                                                    ? "Not connected"
                                                    : AppGlobals.instance.currentHostIp!,
                                                style: getSmartTitle(
                                                  fontSize: 14,
                                                  color: context.appColors.isDark
                                                      ? Colors.white
                                                      : context.appColors.onHero,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15),
                                child: Divider(height: 1, thickness: 0.5),
                              ),
                              _buildSwitchRow(
                                "Auto Remind Server Connection When Offline",
                                "Prompt to reconnect to the server when you are offline on transaction screens",
                                _autoRemindServerConnection,
                                _saveAutoRemindServerConnection,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSectionTitle("Shopfront"),
                        _buildGlassContainer(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.storefront_outlined,
                                        size: 20,
                                        color: context.appColors.isDark
                                            ? Colors.white
                                            : context.appColors.onHero,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Current Shopfront",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: context.appColors.isDark
                                                  ? Colors.white70
                                                  : context.appColors.onHero,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _getShopfrontLabel(),
                                            style: getSmartTitle(
                                              fontSize: 14,
                                              color: context.appColors.isDark
                                                  ? Colors.white
                                                  : context.appColors.onHero,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: _isRefreshingShopfront
                                              ? null
                                              : () =>
                                                    _refreshShopfront(context),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: context.isTablet
                                                  ? 12
                                                  : 6,
                                              vertical: context.isTablet
                                                  ? 8
                                                  : 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(
                                                0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    context.isTablet ? 8 : 6,
                                                  ),
                                            ),
                                            child: _isRefreshingShopfront
                                                ? SizedBox(
                                                    width: context.isTablet
                                                        ? 28
                                                        : 24,
                                                    height: context.isTablet
                                                        ? 28
                                                        : 24,
                                                    child:
                                                        const CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : Icon(
                                                    Icons.refresh,
                                                    size: context.isTablet
                                                        ? 28
                                                        : 24,
                                                    color: Colors.white,
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: () =>
                                              _openShopfrontPicker(context),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: context.isTablet
                                                  ? 12
                                                  : 6,
                                              vertical: context.isTablet
                                                  ? 8
                                                  : 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: kPrimaryColor.withOpacity(
                                                0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    context.isTablet ? 8 : 6,
                                                  ),
                                            ),
                                            child: Icon(
                                              Icons.settings,
                                              size: context.isTablet ? 28 : 24,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 15,
                                  right: 15,
                                  bottom: 10,
                                ),
                                child: Row(
                                  children: [
                                    // Spacer to align with shopfront text (icon container width + spacing)
                                    const SizedBox(width: 51),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.refresh,
                                                size: 14,
                                                color: context.appColors.isDark
                                                    ? Colors.white54
                                                    : context.appColors.onHero
                                                        .withOpacity(0.6),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                "-",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: context.appColors.isDark
                                                      ? Colors.white54
                                                      : context.appColors.onHero
                                                          .withOpacity(0.6),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  "Get shopfront latest changes",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: context
                                                            .appColors.isDark
                                                        ? Colors.white54
                                                        : context
                                                            .appColors.onHero
                                                            .withOpacity(0.6),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.settings,
                                                size: 14,
                                                color: context.appColors.isDark
                                                    ? Colors.white54
                                                    : context.appColors.onHero
                                                        .withOpacity(0.6),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                "-",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: context.appColors.isDark
                                                      ? Colors.white54
                                                      : context.appColors.onHero
                                                          .withOpacity(0.6),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  "Select and sign-in to a RetailManager shopfront",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: context
                                                            .appColors.isDark
                                                        ? Colors.white54
                                                        : context
                                                            .appColors.onHero
                                                            .withOpacity(0.6),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15),
                                child: Divider(height: 1, thickness: 0.5),
                              ),
                              _buildCashDrawerDropdown(),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 15,
                                  right: 15,
                                  bottom: 10,
                                ),
                                child: Row(
                                  children: [
                                    // Spacer to align with cash drawer text (icon container width + spacing)
                                    const SizedBox(width: 51),
                                    Expanded(
                                      child: Text(
                                        "All transactions posted from this device will be assigned this cash drawer identifier.",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: context.appColors.isDark
                                              ? Colors.white54
                                              : context.appColors.onHero
                                                  .withOpacity(0.6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15),
                                child: Divider(height: 1, thickness: 0.5),
                              ),
                              _buildForceFullSyncTile(),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 15,
                                  right: 15,
                                  bottom: 10,
                                ),
                                child: Row(
                                  children: [
                                    // Spacer to align with force sync text (icon container width + spacing)
                                    const SizedBox(width: 51),
                                    Expanded(
                                      child: Text(
                                        "This will re-download all stocks and customers from the server. This may take some time depending on the data size.",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: context.appColors.isDark
                                              ? Colors.white54
                                              : context.appColors.onHero
                                                  .withOpacity(0.6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        _buildSectionTitle("Staff Profile"),
                        _buildGlassContainer(
                          child: Column(
                            children: [
                              _buildInfoRow(
                                Icons.badge_outlined,
                                "Staff ID",
                                AppGlobals.instance.staffNo ?? "-",
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15),
                                child: Divider(height: 1, thickness: 0.5),
                              ),
                              _buildInfoRow(
                                Icons.person_outline,
                                "Staff Name",
                                AppGlobals.instance.staffName ?? "-",
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15),
                                child: Divider(height: 1, thickness: 0.5),
                              ),
                              _buildInfoRow(
                                Icons.groups_2_outlined,
                                "Staff Group",
                                AppGlobals.instance.staffGroupNames.isEmpty
                                    ? "-"
                                    : AppGlobals.instance.staffGroupNames.join(
                                        ", ",
                                      ),
                              ),
                              const SizedBox(height: 10),
                              _buildSignOutButton(),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        _buildSectionTitle("Appearance"),
                        _buildGlassContainer(
                          child: Column(
                            children: [
                              BlocBuilder<ThemeCubit, ThemeMode>(
                                builder: (context, themeMode) {
                                  final bool isDark = themeMode == ThemeMode.dark;
                                  return _buildSwitchRow(
                                    "Dark Mode",
                                    "Use a darker color palette across the app",
                                    isDark,
                                    (val) {
                                      context.read<ThemeCubit>().setDarkMode(val);
                                    },
                                  );
                                },
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15),
                                child: Divider(height: 1, thickness: 0.5),
                              ),
                              BlocBuilder<FontSizeCubit, String>(
                                builder: (context, fontSize) {
                                  return _buildDropdownRow(
                                    "Font Size",
                                    "Adjust text size for better readability",
                                    fontSize.isEmpty ? "default" : fontSize,
                                    const ["default", "large"],
                                    const ["Default", "Large"],
                                    (val) {
                                      if (val != null) {
                                        context.read<FontSizeCubit>().setFontSize(val);
                                      }
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        _buildSectionTitle("Data & Backup"),
                        _buildGlassContainer(
                          child: Column(
                            children: [
                              _buildSliderRow(),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15),
                                child: Divider(height: 1, thickness: 0.5),
                              ),
                              _buildSwitchRow(
                                "Auto Backup Stocktake To Server",
                                "Automatically save current stocktake backup every 24 hours",
                                backupToLan,
                                (val) {
                                  if (_blockIfSyncing(context)) return;
                                  setState(() => backupToLan = val);
                                  context.read<SettingsBloc>().add(
                                    ToggleAutoBackupEvent(val),
                                  );
                                  if (val) {
                                    context.read<SettingsBloc>().add(
                                      CheckAutoBackupNowEvent(),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        _buildSectionTitle("Maintenance", lightOverrideColor: Colors.white),
                        _buildGlassContainer(
                          child: Column(
                            children: [
                              _buildActionRow(
                                Icons.settings_ethernet_outlined,
                                "Manual Connection",
                                "Connect with host IP and pairing code",
                                const Color.fromARGB(255, 34, 255, 5),
                                () {
                                  if (_blockIfSyncing(context)) return;
                                  _showManualConnectionDialog(context);
                                },
                                titleColor: Colors.white,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15),
                                child: Divider(height: 1, thickness: 0.5),
                              ),
                              _buildActionRow(
                                Icons.restore_page_outlined,
                                "Restore Stocktake",
                                "Recover backed up stocktake from server",
                                const Color.fromARGB(255, 40, 248, 255),
                                () {
                                  if (_blockIfSyncing(context)) return;
                                  context.read<BackupRestoreBloc>().add(
                                    LoadBackupSessionsEvent(),
                                  );
                                  showDialog(
                                    context: context,
                                    builder: (_) => const RestoreBackupDialog(),
                                  );
                                },
                                titleColor: Colors.white,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15),
                                child: Divider(height: 1, thickness: 0.5),
                              ),
                              _buildActionRow(
                                Icons.delete_forever_outlined,
                                "Delete All Current Stocktake",
                                "Clears all stocktake records in the current list on this device",
                                kErrorColor,
                                () {
                                  if (_blockIfSyncing(context)) return;
                                  _showDeleteConfirmation(context);
                                },
                                titleColor: Colors.white,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        _buildSectionTitle("Support", lightOverrideColor: Colors.white),
                        _buildGlassContainer(
                          child: Column(
                            children: [
                              _buildActionRow(
                                Icons.storage_outlined,
                                "Export Database",
                                "Share the database file for support",
                                Colors.orange,
                                () => _exportAndShareDatabase(context),
                                titleColor: Colors.white,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15),
                                child: Divider(height: 1, thickness: 0.5),
                              ),
                              _buildActionRow(
                                Icons.download_outlined,
                                "Import Database",
                                "Restore a fixed database from support",
                                Colors.teal,
                                () => _importDatabase(context),
                                titleColor: Colors.white,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),
                        Text(
                          "App Version 1.0.0 (AAAPOS Pty Ltd)",
                          style: TextStyle(
                            color: colors.isDark
                                ? Colors.white70
                                : colors.onHero.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool useDesktopNav = context.useDesktopNav;
    final double horizontalPadding = useDesktopNav ? 50 : 15;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => context.navigateBack(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.home_filled,
                size: 18,
                color: kPrimaryColor,
              ),
            ),
          ),
          Text(
            "Settings",
            style: getSmartTitle(
              fontSize: 18,
              color: isDark ? Colors.white : colors.onHero,
            ),
          ),
          const SizedBox(width: 40), // Spacer to balance back button
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Color? lightOverrideColor}) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final Color effectiveColor = isDark
        ? Colors.white70
        : (lightOverrideColor ?? colors.onHero.withOpacity(0.7));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: effectiveColor,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            // Asymmetric border: Thicker on top/left, thinner on right/bottom
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.5),
              left: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.5),
              right: BorderSide(color: Colors.white.withOpacity(0.12), width: 0.42),
              bottom: BorderSide(color: Colors.white.withOpacity(0.12), width: 0.42),
            ),
            // Glass gradient sweep
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF42A5F5).withOpacity(0.40),
                Colors.transparent,
              ],
              stops: const [0.0, 0.6],
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDark ? Colors.white : colors.onHero,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : colors.onHero,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: getSmartTitle(
                      fontSize: 14,
                      color: isDark ? Colors.white : colors.onHero,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildCashDrawerDropdown() {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = context.isTablet;

    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, top: 16, bottom: 3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.point_of_sale_outlined,
              size: 20,
              color: context.appColors.isDark
                  ? Colors.white
                  : context.appColors.onHero,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Active Cash Drawer",
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : colors.onHero,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "Drawer $_cashDrawerIdentifier",
                  style: getSmartTitle(
                    fontSize: 14,
                    color: isDark ? Colors.white : colors.onHero,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 16 : 10,
              vertical: isTablet ? 8 : 4,
            ),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: kPrimaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              _cashDrawerIdentifier,
              style: getSmartTitle(fontSize: 14, color: kPrimaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showForceFullSyncConfirmation(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;

    showDialog(
      context: context,
      builder: (ctx) => StandardDialog(
        title: "Force Full Sync",
        colors: colors,
        isDark: isDark,
        onClose: () => Navigator.of(ctx).pop(),
        content: Text(
          "This will re-download all stocks and customers from the server. This may take some time depending on the data size.\n\nDo you want to continue?",
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          DialogTextAction(
            label: "Cancel",
            style: DialogActionStyle.cancelOutline,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          DialogTextAction(
            label: "Continue",
            style: DialogActionStyle.primary,
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _isForceFullSyncInProgress = true;
              });
              context.read<SettingsBloc>().add(
                ForceFullSyncEvent(shopfrontId: _savedShopfrontId),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildForceFullSyncTile() {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = context.isTablet;

    return BlocBuilder<FetchStockBloc, FetchStockStates>(
      builder: (context, stockState) {
        return BlocBuilder<FetchCustomerBloc, FetchCustomerStates>(
          builder: (context, customerState) {
            final bool isSyncing = stockState is FetchStockProgress ||
                customerState is FetchCustomerProgress ||
                _isForceFullSyncInProgress;

            return InkWell(
              onTap: () {
                if (isSyncing) {
                  _showError(context, "Sync in progress. Please wait.");
                  return;
                }
                if (_savedShopfrontId.isEmpty) {
                  _showError(context, "No shopfront selected.");
                  return;
                }
                _showForceFullSyncConfirmation(context);
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 15, right: 15, top: 16, bottom: 3),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.sync,
                        size: 20,
                        color: isDark ? Colors.white : colors.onHero,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Force Full Sync",
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : colors.onHero,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Re-sync all stocks and customers",
                            style: getSmartTitle(
                              fontSize: 14,
                              color: isDark ? Colors.white : colors.onHero,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isSyncing)
                      SizedBox(
                        width: isTablet ? 28 : 24,
                        height: isTablet ? 28 : 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kPrimaryColor,
                        ),
                      )
                    else
                      Icon(
                        Icons.chevron_right,
                        size: isTablet ? 28 : 24,
                        color: isDark ? Colors.white54 : colors.onHero.withOpacity(0.5),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSignOutButton() {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isOffline = (AppGlobals.instance.hostName ?? "").trim().isEmpty;
    final bool isDesktopOrTablet = context.isTablet || context.useDesktopNav;
    
    final button = OutlinedButton(
      onPressed: () {
        if (isOffline) {
          _showError(context, "Connect to the network to sign off.");
          return;
        }
        if (_blockIfSyncing(context)) return;
        context.read<StaffAuthBloc>().add(SignOutStaffEvent());
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: kErrorColor.withOpacity(0.2),
        side: BorderSide(color: kErrorColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
      ),
      child: Text(
        "Sign Off",
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : colors.onHero,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
      child: isDesktopOrTablet
          ? Align(
              alignment: Alignment.centerRight,
              child: button,
            )
          : SizedBox(
              width: double.infinity,
              child: button,
            ),
    );
  }

  Widget _buildSliderRow() {
    return BlocConsumer<SettingsBloc, SettingsState>(
      listener: (context, state) {
        final colors = context.appColors;
        if (state is SettingsLoaded) {
          setState(() {
            retentionDays = state.retentionDays.toDouble();
            backupToLan = state.autoBackupEnabled;
          });
        }
        if (state is SettingsCleanupDone) {
          setState(() {
            retentionDays = state.retentionDays.toDouble();
            backupToLan = state.autoBackupEnabled;
          });
          // Optional: show a small snackbar/toast if wanted
        }
        if (state is AutoBackupRunDone) {
          setState(() {
            retentionDays = state.retentionDays.toDouble();
            backupToLan = state.autoBackupEnabled;
          });
          if (state.didBackup) {
            AlertInfo.show(
              context: context,
              text: "Auto backup completed.",
              typeInfo: TypeInfo.success,
              backgroundColor: colors.surface,
              iconColor: kPrimaryColor,
              textColor: colors.onSurface,
              padding: 70,
              position: MessagePosition.top,
            );
          }
        }
      },
      builder: (context, state) {
        final colors = context.appColors;
        final bool isDark = colors.isDark;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Keep Committed Stocktake History",
                      style: TextStyle(
                        color: isDark ? Colors.white : colors.onHero,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${retentionDays.toInt()} Days",
                        style: TextStyle(
                          color: isDark ? Colors.white : colors.onHero,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: kPrimaryColor,
                  inactiveTrackColor: colors.onSurfaceMuted,
                  thumbColor: isDark ? Colors.white : colors.onHero,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8.0,
                    elevation: 4,
                  ),
                  overlayColor: kPrimaryColor.withOpacity(0.2),
                ),
                child: Slider(
                  value: retentionDays,
                  min: 1,
                  max: 30,
                  divisions: 29,
                  onChanged: (val) => setState(() => retentionDays = val),

                  //save + cleanup only when user stops dragging
                  onChangeEnd: (val) {
                    context.read<SettingsBloc>().add(
                      ChangeRetentionDaysEvent(val.toInt()),
                    );
                  },
                ),
              ),

              Text(
                "Determines how long committed stocktake data is kept locally before auto-deletion.",
                style: TextStyle(
                  color: isDark
                      ? Colors.white70
                      : colors.onHero.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSwitchRow(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : colors.onHero,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2, // Prevent overflow
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white70
                        : colors.onHero.withOpacity(0.8),
                    fontSize: 11,
                  ),
                  maxLines: 3, // Prevent overflow
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          CupertinoSwitch(
            value: value,
            activeColor: kPrimaryColor,
            inactiveTrackColor: colors.divider,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow(
    String title,
    String subtitle,
    String value,
    List<String> options,
    List<String> labels,
    Function(String?) onChanged,
  ) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.white.withOpacity(0.4),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isDense: true,
                dropdownColor: isDark ? const Color(0xFF2A2A2E) : Colors.white,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white,
                ),
                selectedItemBuilder: (BuildContext context) {
                  return labels.map<Widget>((String label) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList();
                },
                items: List.generate(options.length, (index) {
                  return DropdownMenuItem<String>(
                    value: options[index],
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  );
                }),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap, {
    Color? titleColor,
  }) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDark ? Colors.white : colors.onHero,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : (titleColor ?? color),
                    ),
                    maxLines: 1, // Prevent overflow
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white70
                          : colors.onHero.withOpacity(0.8),
                      fontSize: 11,
                    ),
                    maxLines: 2, // Prevent overflow
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: isDark ? Colors.white70 : colors.onHero.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    context.read<BackupStocktakeBloc>().add(BackUpStocktakeEvent());

    HapticFeedback.vibrate();
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      builder: (ctx) => StocktakeDeleteConfirmationDialog(
        onConfirm: () async {
          context.read<SettingsBloc>().add(DeleteAllStocktakeEvent());
        },
      ),
    );
  }

  Future<void> _exportAndShareDatabase(BuildContext context) async {
    context.read<SettingsBloc>().add(ExportDatabaseEvent());
  }

  Future<void> _importDatabase(BuildContext context) async {
    final colors = context.appColors;
    final bool isDark = colors.isDark;

    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StandardDialog(
        title: "Import Database",
        colors: colors,
        isDark: isDark,
        onClose: () => Navigator.of(ctx).pop(false),
        content: Text(
          "This will replace your current database with the selected file. "
          "Make sure you have a backup of your current data.\n\n"
          "After importing, you will need to restart the app.",
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          DialogTextAction(
            label: "Cancel",
            style: DialogActionStyle.cancelOutline,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          DialogTextAction(
            label: "Import",
            style: DialogActionStyle.primary,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Open file picker to select database file
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'Database',
      extensions: ['db'],
      uniformTypeIdentifiers: ['public.database', 'public.data', 'public.item'],
    );

    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
    
    if (file != null) {
      if (!context.mounted) return;
      context.read<SettingsBloc>().add(ImportDatabaseEvent(filePath: file.path));
    }
  }
}
