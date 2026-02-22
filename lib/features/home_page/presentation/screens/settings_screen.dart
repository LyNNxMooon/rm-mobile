import 'dart:ui';
import 'dart:async';
import 'package:alert_info/alert_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/entities/vos/network_server_vo.dart';
import 'package:rmstock_scanner/features/home_page/presentation/BLoC/home_screen_bloc.dart';
import 'package:rmstock_scanner/features/home_page/presentation/BLoC/home_screen_events.dart';
import 'package:rmstock_scanner/features/home_page/presentation/BLoC/home_screen_states.dart';
import 'package:rmstock_scanner/features/home_page/presentation/widgets/restore_backup_dialog.dart';
import 'package:rmstock_scanner/features/home_page/presentation/widgets/shopfronts_dialog.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../local_db/local_db_dao.dart';
import '../../../stocktake/presentation/BLoC/stocktake_bloc.dart';
import '../../../stocktake/presentation/BLoC/stocktake_events.dart';
import '../../../stocktake/presentation/widgets/delete_all_confirmation_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const int _defaultAgentPort = 5000;

  // Mock Data (Replace with BLoC state later)
  String staffName = "John Doe";
  String staffID = "STF-001";
  double retentionDays = 10;
  bool backupToLan = true;

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

  @override
  void initState() {
    super.initState();
    context.read<SettingsBloc>().add(LoadSettingsEvent());
    context.read<SettingsBloc>().add(CheckAutoBackupNowEvent());
    _autoBackupTimer = Timer.periodic(const Duration(hours: 1), (_) {
      if (!mounted) return;
      context.read<SettingsBloc>().add(CheckAutoBackupNowEvent());
    });
  }

  @override
  void dispose() {
    _autoBackupTimer?.cancel();
    _manualIpController.dispose();
    _manualCodeController.dispose();
    _manualPortController.dispose();
    super.dispose();
  }

  void _showError(BuildContext context, String message) {
    showTopSnackBar(Overlay.of(context), CustomSnackBar.error(message: message));
  }

  void _startManualConnection(BuildContext context) {
    final ip = _manualIpController.text.trim();
    final code = _manualCodeController.text.trim();

    if (ip.isEmpty) {
      _showError(context, "Please enter host IP.");
      return;
    }
    if (code.isEmpty) {
      _showError(context, "Please enter pairing code.");
      return;
    }

    _selectedIp = ip;
    _selectedHostName = ip;
    _selectedPort = _defaultAgentPort;
    _isManualConnectionFlow = true;

    context.read<DiscoverHostBloc>().add(
      DiscoverHostEvent(ip: _selectedIp, port: _selectedPort),
    );
  }

  void _retryDiscoverWithPort(BuildContext context, int port) {
    _selectedPort = port;
    context.read<DiscoverHostBloc>().add(
      DiscoverHostEvent(ip: _selectedIp, port: _selectedPort),
    );
  }

  void _showManualPortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 10,
        backgroundColor: kBgColor,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 260),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: kGColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.settings_ethernet, color: kSecondaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Enter Port",
                        style: getSmartTitle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 45,
                      child: TextField(
                        controller: _manualPortController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          hintText: "Port (e.g. 5000)",
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final int? manualPort = int.tryParse(
                            _manualPortController.text.trim(),
                          );

                          if (manualPort == null ||
                              manualPort <= 0 ||
                              manualPort > 65535) {
                            _showError(context, "Please enter a valid port.");
                            return;
                          }

                          Navigator.of(context).pop();
                          _retryDiscoverWithPort(context, manualPort);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: kSecondaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          "Try Port",
                          style: TextStyle(
                            color: kSecondaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showManualConnectionDialog(BuildContext context) {
    _manualIpController.text = "";
    _manualCodeController.text = "";

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 10,
        backgroundColor: kBgColor,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: kGColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, color: kSecondaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Manual Connection",
                        style: getSmartTitle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      height: 45,
                      child: TextField(
                        controller: _manualIpController,
                        decoration: InputDecoration(
                          hintText: "Host IP",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 45,
                      child: TextField(
                        controller: _manualCodeController,
                        decoration: InputDecoration(
                          hintText: "Pairing Code",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _startManualConnection(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: kSecondaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          "Connect",
                          style: TextStyle(
                            color: kSecondaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
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
                ),
              );
            }

            if (state is DiscoverHostError) {
              _showError(context, state.message);
              _showManualPortDialog(context);
            }
          },
        ),
        BlocListener<PairDeviceBloc, PairDeviceStates>(
          listener: (context, state) {
            if (!_isManualConnectionFlow) return;

            if (state is PairDeviceSuccess) {
              final navigator = Navigator.of(context, rootNavigator: true);
              navigator.popUntil((route) => route is! PopupRoute);

              context.read<ShopfrontBloc>().add(
                FetchShopsFromApi(
                  ipAddress: _selectedIp,
                  port: _selectedPort,
                  apiKey: state.response.apiKey,
                ),
              );

              showDialog(
                barrierDismissible: false,
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
                backgroundColor: kSecondaryColor,
                iconColor: kPrimaryColor,
                textColor: kThirdColor,
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
      ],
      child: Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kGColor),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      _buildSectionTitle("Staff Profile"),
                      _buildGlassContainer(
                        child: Column(
                          children: [
                            _buildInfoRow(
                              Icons.badge_outlined,
                              "Staff ID",
                              staffID,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              child: Divider(height: 1, thickness: 0.5),
                            ),
                            _buildInfoRow(
                              Icons.person_outline,
                              "Staff Name",
                              staffName,
                            ),
                            const SizedBox(height: 10),
                            _buildSignOutButton(),
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
                              "Auto Backup Stocktake",
                              "Automatically save current stocktake backup every 24 hours",
                              backupToLan,
                              (val) {
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

                      _buildSectionTitle("Maintenance"),
                      _buildGlassContainer(
                        child: Column(
                          children: [
                            _buildActionRow(
                              Icons.settings_ethernet_outlined,
                              "Manual Connection",
                              "Connect with host IP and pairing code",
                              kPrimaryColor,
                              () => _showManualConnectionDialog(context),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              child: Divider(height: 1, thickness: 0.5),
                            ),
                            _buildActionRow(
                              Icons.restore_page_outlined,
                              "Restore Data",
                              "Recover deleted stocktake from server",
                              Colors.blue,
                              () {
                                context.read<BackupRestoreBloc>().add(
                                  LoadBackupSessionsEvent(),
                                );
                                showDialog(
                                  context: context,
                                  builder: (_) => const RestoreBackupDialog(),
                                );
                              },
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              child: Divider(height: 1, thickness: 0.5),
                            ),
                            _buildActionRow(
                              Icons.delete_forever_outlined,
                              "Delete All Current Stocktake",
                              "Clear all currently counted stocktake list permanently on this device.",
                              kErrorColor,
                              () => _showDeleteConfirmation(context),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
                      Text(
                        "App Version 1.0.0 (AAAPOS Pty Ltd)",
                        style: TextStyle(
                          color: kSecondaryColor.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => context.navigateBack(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kSecondaryColor.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: kPrimaryColor,
              ),
            ),
          ),
          Text(
            "Settings",
            style: getSmartTitle(fontSize: 22, color: kSecondaryColor),
          ),
          const SizedBox(width: 40), // Spacer to balance back button
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: kSecondaryColor.withOpacity(0.7),
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
            color: kSecondaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kSecondaryColor.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(blurRadius: 20, color: kThirdColor.withOpacity(.1)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: kSecondaryColor),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: kSecondaryColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: getSmartTitle(fontSize: 16, color: kSecondaryColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            // Logout Logic
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: kErrorColor.withOpacity(0.2),
            side: BorderSide(color: kErrorColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text(
            "Sign Off",
            style: TextStyle(
              fontSize: 16,
              color: kSecondaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderRow() {
    return BlocConsumer<SettingsBloc, SettingsState>(
      listener: (context, state) {
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
              backgroundColor: kSecondaryColor,
              iconColor: kPrimaryColor,
              textColor: kThirdColor,
              padding: 70,
              position: MessagePosition.top,
            );
          }
        }
      },
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Keep Backup Days",
                    style: TextStyle(
                      color: kSecondaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
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
                      style: const TextStyle(
                        color: kSecondaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: kPrimaryColor,
                  inactiveTrackColor: kGreyColor.withOpacity(0.7),
                  thumbColor: kSecondaryColor,
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
                  color: kSecondaryColor.withOpacity(0.8),
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
                    color: kSecondaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  maxLines: 2, // Prevent overflow
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: kSecondaryColor.withOpacity(0.8),
                    fontSize: 12,
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
            inactiveTrackColor: kGreyColor,
            onChanged: onChanged,
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
    VoidCallback onTap,
  ) {
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
              child: Icon(icon, size: 20, color: kSecondaryColor),
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
                      fontSize: 16,
                      color: color,
                    ),
                    maxLines: 1, // Prevent overflow
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: kSecondaryColor.withOpacity(0.8),
                      fontSize: 12,
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
              color: kSecondaryColor.withOpacity(0.7),
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
          await Future.delayed(Duration(seconds: 2), () {
            LocalDbDAO.instance.deleteAllStocktake();
            context.read<FetchingStocktakeListBloc>().add(
              FetchStocktakeListEvent(),
            );
          });

          AlertInfo.show(
            context: context,
            text: "All your Stocktake data has been deleted!",
            typeInfo: TypeInfo.success,
            backgroundColor: kSecondaryColor,
            iconColor: kPrimaryColor,
            textColor: kThirdColor,
            position: MessagePosition.top,
            padding: 70,
          );
        },
      ),
    );
  }
}
