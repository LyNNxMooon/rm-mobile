import 'package:alert_info/alert_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/entities/vos/network_server_vo.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/modern_dialog_styles.dart';
import '../../../../utils/dialog_size_utils.dart';
import '../../../../utils/responsive_utils.dart';

import '../BLoC/home_screen_bloc.dart';
import '../BLoC/home_screen_events.dart';
import '../BLoC/home_screen_states.dart';
import 'shopfronts_dialog.dart';

class NetworkPcDialog extends StatefulWidget {
  const NetworkPcDialog({super.key});

  @override
  State<NetworkPcDialog> createState() => _NetworkPcDialogState();
}

class _NetworkPcDialogState extends State<NetworkPcDialog> {
  static const int _defaultAgentPort = 5000;
  NetworkServerVO? _selectedPc;
  int _selectedPort = _defaultAgentPort;
  bool _isPairFlowLoading = false;
  final TextEditingController _connectCodeController = TextEditingController();
  final TextEditingController _manualPortController = TextEditingController(
    text: _defaultAgentPort.toString(),
  );

  @override
  void dispose() {
    _connectCodeController.dispose();
    _manualPortController.dispose();
    super.dispose();
  }

  void _showError(BuildContext context, String message) {
    showTopSnackBar(Overlay.of(context), CustomSnackBar.error(message: message));
  }

  void _startPairingFlow(NetworkServerVO pc, BuildContext context) {
    setState(() {
      _selectedPc = pc;
      _selectedPort = _defaultAgentPort;
      _isPairFlowLoading = true;
    });

    context.read<DiscoverHostBloc>().add(
      DiscoverHostEvent(ip: pc.ipAddress, port: _defaultAgentPort),
    );
  }

  void _retryDiscoverWithPort(BuildContext context, int port) {
    if (_selectedPc == null) return;

    setState(() {
      _selectedPort = port;
      _isPairFlowLoading = true;
    });
    context.read<DiscoverHostBloc>().add(
      DiscoverHostEvent(ip: _selectedPc!.ipAddress, port: port),
    );
  }

  void _showManualPortDialog(BuildContext context) {
    if (_selectedPc == null) return;
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = context.isTablet;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    final double fieldHeight = (isTablet ? 52 : 48) * uiScale;
    final double maxDialogHeight = (MediaQuery.of(context).size.height * 0.45)
        .clamp(260.0, 380.0);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: dialogInsetPadding(context),
        shape: ModernDialogStyles.dialogShape,
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: ModernDialogContainer(
          maxHeight: maxDialogHeight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ModernDialogHeader(
                title: "Enter Port",
                icon: Icons.settings_ethernet_rounded,
                subtitle: "Specify custom port number",
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: fieldHeight,
                      child: TextField(
                        controller: _manualPortController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: TextStyle(
                          color: isDark ? Colors.white : colors.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        onEditingComplete: () {
                          final trimmedValue = _manualPortController.text.trim();
                          if (_manualPortController.text != trimmedValue) {
                            _manualPortController.value = _manualPortController.value.copyWith(
                              text: trimmedValue,
                              selection: TextSelection.collapsed(offset: trimmedValue.length),
                            );
                          }
                        },
                        decoration: ModernDialogStyles.inputDecoration(
                          context,
                          hintText: "Port (e.g. 5000)",
                          prefixIcon: Icons.numbers_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: ModernDialogStyles.headerGradient,
                          borderRadius: BorderRadius.circular(ModernDialogStyles.buttonRadius),
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
                            onTap: () {
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
                            borderRadius: BorderRadius.circular(ModernDialogStyles.buttonRadius),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "Try Port",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
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
            ],
          ),
        ),
      ),
    );
  }

  void _showPairCodeDialog(BuildContext context, String pairCode) {
    _connectCodeController.clear();
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = context.isTablet;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    final double fieldHeight = (isTablet ? 52 : 48) * uiScale;
    final double maxDialogHeight = (MediaQuery.of(context).size.height * 0.56)
        .clamp(340.0, 520.0);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: dialogInsetPadding(context),
        shape: ModernDialogStyles.dialogShape,
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: ModernDialogContainer(
          maxHeight: maxDialogHeight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ModernDialogHeader(
                title: "Pair With Host",
                icon: Icons.link_rounded,
                subtitle: "Enter the code shown on the host",
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Display code section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            kPrimaryColor.withOpacity(isDark ? 0.15 : 0.08),
                            kPrimaryColor.withOpacity(isDark ? 0.08 : 0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: kPrimaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Your Code",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colors.onSurfaceMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: SelectableText(
                                  pairCode,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : colors.onSurface,
                                    letterSpacing: 4,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: kPrimaryColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: pairCode));
                                    AlertInfo.show(
                                      context: context,
                                      text: "Pair code copied",
                                      typeInfo: TypeInfo.success,
                                      backgroundColor: colors.surface,
                                      iconColor: kPrimaryColor,
                                      textColor: colors.onSurface,
                                      padding: 70,
                                      position: MessagePosition.top,
                                    );
                                  },
                                  icon: Icon(Icons.copy_rounded, size: 20),
                                  color: kPrimaryColor,
                                  tooltip: "Copy code",
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Input section
                    SizedBox(
                      height: fieldHeight,
                      child: TextField(
                        controller: _connectCodeController,
                        style: TextStyle(
                          color: isDark ? Colors.white : colors.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: ModernDialogStyles.inputDecoration(
                          context,
                          hintText: "Enter Host Code",
                          prefixIcon: Icons.keyboard_alt_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: BlocBuilder<PairDeviceBloc, PairDeviceStates>(
                        builder: (context, pairState) {
                          final isLoading = pairState is PairingDevice;
                          return Container(
                            decoration: BoxDecoration(
                              gradient: ModernDialogStyles.headerGradient,
                              borderRadius: BorderRadius.circular(ModernDialogStyles.buttonRadius),
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
                                onTap: isLoading
                                    ? null
                                    : () {
                                        if (_selectedPc == null) return;

                                        final pairingCode = _connectCodeController.text.trim();
                                        if (pairingCode.isEmpty) {
                                          _showError(context, "Please enter pairing code.");
                                          return;
                                        }

                                        context.read<PairDeviceBloc>().add(
                                          PairDeviceEvent(
                                            ip: _selectedPc!.ipAddress,
                                            hostName: _selectedPc!.hostName ?? "Unknown-Server",
                                            port: _selectedPort,
                                            pairingCode: pairingCode,
                                          ),
                                        );
                                      },
                                borderRadius: BorderRadius.circular(ModernDialogStyles.buttonRadius),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: isLoading
                                        ? [
                                            SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                              ),
                                            ),
                                          ]
                                        : [
                                            const Icon(
                                              Icons.link_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            const Text(
                                              "Connect",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
    final colors = context.appColors;
    // Calculate a safe max height (e.g., 70% of screen)
    final double safeMaxHeight = (MediaQuery.of(context).size.height * 0.72)
        .clamp(380.0, 760.0);
    //final double safeMaxWidth = MediaQuery.of(context).size.width * 0.7;

    return MultiBlocListener(
      listeners: [
        BlocListener<DiscoverHostBloc, DiscoverHostStates>(
          listener: (context, state) {
            if (state is DiscoverHostLoaded) {
              if (!state.response.isAgent) {
                setState(() => _isPairFlowLoading = false);
                _showError(context, "Selected host is not a valid RM agent.");
                return;
              }

              if (_selectedPc != null) {
                setState(() => _selectedPort = state.response.port);
                context.read<PairCodeBloc>().add(
                  GetPairCodesEvent(
                    ip: _selectedPc!.ipAddress,
                    port: state.response.port,
                  ),
                );
              }
            }

            if (state is DiscoverHostError) {
              setState(() => _isPairFlowLoading = false);
              _showError(context, state.message);
              _showManualPortDialog(context);
            }
          },
        ),
        BlocListener<PairCodeBloc, PairCodeStates>(
          listener: (context, state) {
            if (state is PairCodesLoaded) {
              setState(() => _isPairFlowLoading = false);
              if (state.response.success) {
                _showPairCodeDialog(context, state.response.pairingCode);
              } else {
                _showError(context, state.response.message);
              }
            }

            if (state is PairCodeError) {
              setState(() => _isPairFlowLoading = false);
              _showError(context, state.message);
            }
          },
        ),
        BlocListener<PairDeviceBloc, PairDeviceStates>(
          listener: (context, state) {
            if (state is PairDeviceSuccess) {
              final selectedPc = _selectedPc;
              if (selectedPc == null) return;

              final navigator = Navigator.of(context, rootNavigator: true);
              navigator.popUntil((route) => route.isFirst);

              // Old setup flow intentionally disabled for pairing-based setup.
              // context.read<ShopfrontBloc>().add(
              //   FetchShops(
              //     ipAddress: selectedPc.ipAddress,
              //     path: AppGlobals.instance.currentPath ?? "",
              //   ),
              // );

              navigator.context.read<ShopfrontBloc>().add(
                FetchShopsFromApi(
                  ipAddress: selectedPc.ipAddress,
                  port: _selectedPort,
                  apiKey: state.response.apiKey,
                ),
              );

              showDialog(
                //barrierDismissible: false,
                context: navigator.context,
                builder: (_) => ShopfrontsDialog(
                  pc: NetworkServerVO(
                    ipAddress: selectedPc.ipAddress,
                    hostName: selectedPc.hostName,
                  ),
                  previousPath: "",
                  isPairedFlow: true,
                  port: _selectedPort,
                  apiKey: state.response.apiKey,
                ),
              );

              AlertInfo.show(
                context: navigator.context,
                text: state.response.message,
                typeInfo: TypeInfo.success,
                backgroundColor: colors.surface,
                iconColor: kPrimaryColor,
                textColor: colors.onSurface,
                padding: 70,
                position: MessagePosition.top,
              );
            }

            if (state is PairDeviceError) {
              _showError(context, state.message);
            }
          },
        ),
      ],
      child: Dialog(
        insetPadding: dialogInsetPadding(context),
        shape: ModernDialogStyles.dialogShape,
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: ModernDialogContainer(
          maxHeight: safeMaxHeight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ModernDialogHeader(
                title: "Network Servers",
                icon: Icons.dns_rounded,
                subtitle: "Select a server to connect",
              ),
              Flexible(
                child: BlocBuilder<FetchingNetworkServerBloc, FetchingNetworkServerStates>(
                  builder: (context, state) {
                    if (state is FetchingNetworkServers) {
                      return const ModernLoadingState(
                        message: "Finding Network Servers",
                        subtitle: "This may take a few seconds...",
                      );
                    } else if (state is ErrorFetchingNetworkServers) {
                      return ModernErrorState(
                        message: state.message,
                        onRetry: () {
                          context.read<FetchingNetworkServerBloc>().add(
                            FetchNetworkServerEvent(),
                          );
                        },
                      );
                    } else if (state is NetworkServersLoaded) {
                      if (state.pcList.isEmpty) {
                        return const ModernEmptyState(
                          message: "No servers found on the network",
                          icon: Icons.dns_outlined,
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        itemCount: state.pcList.length,
                        itemBuilder: (context, index) {
                          return _buildServerTile(state.pcList[index], context);
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServerTile(NetworkServerVO pc, BuildContext ctx) {
    final bool isTablet = ctx.isTablet;
    final double textScale = MediaQuery.textScalerOf(ctx).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    final colors = ctx.appColors;
    final isDark = colors.isDark;
    final isLoading = _isPairFlowLoading && _selectedPc?.ipAddress == pc.ipAddress;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            _startPairingFlow(pc, ctx);
          },
          borderRadius: BorderRadius.circular(14),
          splashColor: kPrimaryColor.withOpacity(0.08),
          highlightColor: kPrimaryColor.withOpacity(0.04),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : colors.surfaceAlt.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : colors.divider.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: (isTablet ? 48 : 44) * uiScale,
                  height: (isTablet ? 48 : 44) * uiScale,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        kPrimaryColor.withOpacity(isDark ? 0.25 : 0.15),
                        kPrimaryColor.withOpacity(isDark ? 0.15 : 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset("assets/images/pc.png", fit: BoxFit.contain),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pc.hostName ?? "Unknown-Server",
                        style: TextStyle(
                          color: isDark ? Colors.white : colors.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pc.ipAddress,
                        style: TextStyle(
                          color: colors.onSurfaceMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isLoading)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: kPrimaryColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
