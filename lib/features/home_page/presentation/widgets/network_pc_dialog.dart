import 'package:alert_info/alert_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/entities/vos/network_server_vo.dart';
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
  /// Optional message to display at the top of the dialog (e.g., connection error info)
  final String? message;
  
  const NetworkPcDialog({super.key, this.message});

  @override
  State<NetworkPcDialog> createState() => _NetworkPcDialogState();
}

class _NetworkPcDialogState extends State<NetworkPcDialog> {
  static const int _defaultAgentPort = 5000;
  static const int _maxPairAttempts = 3;
  NetworkServerVO? _selectedPc;
  int _selectedPort = _defaultAgentPort;
  bool _isPairFlowLoading = false;
  final ValueNotifier<int> _pairAttempts = ValueNotifier(0);
  final ValueNotifier<String?> _pairError = ValueNotifier(null);
  final GlobalKey<_OtpCodeInputState> _otpKey = GlobalKey<_OtpCodeInputState>();
  bool _isPairCodeDialogOpen = false;
  bool _isManualConnectionFlow = false;
  final TextEditingController _connectCodeController = TextEditingController();
  final TextEditingController _manualPortController = TextEditingController(
    text: _defaultAgentPort.toString(),
  );

  @override
  void dispose() {
    _connectCodeController.dispose();
    _manualPortController.dispose();
    _pairAttempts.dispose();
    _pairError.dispose();
    super.dispose();
  }

  void _showError(BuildContext context, String message) {
    showTopSnackBar(Overlay.of(context), CustomSnackBar.error(message: message));
  }

  /// Shows manual connection dialog
  void _showManualConnectionDialog(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => _ManualConnectionDialogContent(
        onConnect: (ip, code, port) {
          // Close manual connection dialog
          Navigator.of(dialogContext).pop();

          // Set selected pc for manual connection
          _selectedPc = NetworkServerVO(ipAddress: ip, hostName: ip);
          _selectedPort = port;
          _isManualConnectionFlow = true;

          // Start pairing with the provided code
          parentContext.read<PairDeviceBloc>().add(
            PairDeviceEvent(
              ip: ip,
              hostName: ip,
              port: port,
              pairingCode: code,
              isTablet: parentContext.isTablet,
            ),
          );
        },
        onError: (message) => _showError(parentContext, message),
      ),
    );
  }

  void _startPairingFlow(NetworkServerVO pc, BuildContext context) {
    final discoveredPort = pc.port;
    setState(() {
      _selectedPc = pc;
      _selectedPort = discoveredPort ?? _defaultAgentPort;
      _isPairFlowLoading = true;
    });

    if (discoveredPort != null && discoveredPort > 0) {
      context.read<PairCodeBloc>().add(
        GetPairCodesEvent(ip: pc.ipAddress, port: discoveredPort),
      );
      return;
    }

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
    final bool useDesktopNav = context.useDesktopNav;
    final double inputFontSize = useDesktopNav ? 13.0 : 15.0;
    final double buttonFontSize = useDesktopNav ? 13.0 : 15.0;
    final double iconSize = useDesktopNav ? 18.0 : 20.0;
    final double maxDialogHeight =
        (MediaQuery.of(context).size.height * 0.50).clamp(320.0, 480.0);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: dialogInsetPadding(context),
        shape: ModernDialogStyles.dialogShape,
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: ModernDialogContainer(
          maxHeight: maxDialogHeight,
          maxWidth: context.useDesktopNav ? 520 : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ModernDialogHeader(
                title: "Enter Port",
                icon: Icons.settings_ethernet_rounded,
                subtitle: "Specify custom port number",
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _manualPortController,
                        keyboardType: TextInputType.number,
                        textAlignVertical: TextAlignVertical.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style: TextStyle(
                          color: isDark ? Colors.white : colors.onSurface,
                          fontSize: inputFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                        onEditingComplete: () {
                          final trimmedValue =
                              _manualPortController.text.trim();
                          if (_manualPortController.text != trimmedValue) {
                            _manualPortController.value =
                                _manualPortController.value.copyWith(
                              text: trimmedValue,
                              selection: TextSelection.collapsed(
                                  offset: trimmedValue.length),
                            );
                          }
                        },
                        decoration: ModernDialogStyles.inputDecoration(
                          context,
                          hintText: "Port (e.g. 5000)",
                          prefixIcon: Icons.numbers_rounded,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            borderRadius: BorderRadius.circular(
                                ModernDialogStyles.buttonRadius),
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
                                  _showError(
                                      context, "Please enter a valid port.");
                                  return;
                                }

                                Navigator.of(context).pop();
                                _retryDiscoverWithPort(context, manualPort);
                              },
                              borderRadius: BorderRadius.circular(
                                  ModernDialogStyles.buttonRadius),
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: useDesktopNav ? 12 : 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.send_rounded,
                                      color: Colors.white,
                                      size: iconSize,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Try Port",
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
      ),
    );
  }

  void _showPairCodeDialog(BuildContext context, String pairCode) {
    _connectCodeController.clear();
    _pairAttempts.value = 0;
    _pairError.value = null;
    _isPairCodeDialogOpen = true;
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool useDesktopNav = context.useDesktopNav;
    final double buttonFontSize = useDesktopNav ? 13.0 : 15.0;
    final double iconSize = useDesktopNav ? 18.0 : 20.0;
    final double hintFontSize = useDesktopNav ? 13.0 : 15.0;
    final double maxDialogHeight = (MediaQuery.of(context).size.height * 0.56)
        .clamp(340.0, 520.0);

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        insetPadding: dialogInsetPadding(context),
        shape: ModernDialogStyles.dialogShape,
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: ModernDialogContainer(
          maxHeight: maxDialogHeight,
          maxWidth: context.useDesktopNav ? 520 : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModernDialogHeader(
                title: "Pair With Host",
                icon: Icons.link_rounded,
                subtitle: "Enter the code shown on the host",
                trailing: IconButton(
                  onPressed: () {
                    _isPairCodeDialogOpen = false;
                    Navigator.of(dialogCtx).pop();
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white70 : kPrimaryColor,
                  ),
                  tooltip: "Close",
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Enter the 6-digit code displayed on the AAAPOS RMMobile Service Hub Server to continue.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: hintFontSize,
                          height: 1.4,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : colors.onSurfaceMuted,
                        ),
                      ),
                      const SizedBox(height: 36),
                      // OTP cube fields
                      _OtpCodeInput(
                        key: _otpKey,
                        length: 6,
                        onChanged: (code) {
                          _connectCodeController.text = code;
                          if (_pairError.value != null) {
                            _pairError.value = null;
                          }
                        },
                        onCompleted: (code) {
                          _connectCodeController.text = code;
                          if (_selectedPc == null) return;
                          context.read<PairDeviceBloc>().add(
                            PairDeviceEvent(
                              ip: _selectedPc!.ipAddress,
                              hostName:
                                  _selectedPc!.hostName ?? "Unknown-Server",
                              port: _selectedPort,
                              pairingCode: code,
                              isTablet: context.isTablet,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      // Attempts / error feedback below the fields
                      ValueListenableBuilder<int>(
                        valueListenable: _pairAttempts,
                        builder: (context, attempts, _) {
                          return ValueListenableBuilder<String?>(
                            valueListenable: _pairError,
                            builder: (context, error, _) {
                              final remaining = _maxPairAttempts - attempts;
                              if (error == null && attempts == 0) {
                                return const SizedBox(height: 4);
                              }
                              return Column(
                                children: [
                                  if (error != null)
                                    Text(
                                      error,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: hintFontSize - 1,
                                        fontWeight: FontWeight.w400,
                                        color: kErrorColor,
                                      ),
                                    ),
                                  if (attempts > 0) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      "$remaining attempt${remaining == 1 ? '' : 's'} remaining",
                                      style: TextStyle(
                                        fontSize: hintFontSize - 2,
                                        fontWeight: FontWeight.w400,
                                        color: remaining <= 1
                                            ? kErrorColor
                                            : colors.onSurfaceMuted,
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Loading indicator while pairing (auto-connects on code completion)
                      BlocBuilder<PairDeviceBloc, PairDeviceStates>(
                        builder: (context, pairState) {
                          if (pairState is! PairingDevice) {
                            return const SizedBox.shrink();
                          }
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: iconSize,
                                width: iconSize,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    kPrimaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Connecting...",
                                style: TextStyle(
                                  color: colors.onSurfaceMuted,
                                  fontSize: buttonFontSize,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),)
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
              _showManualPortDialog(context);
            }
          },
        ),
        BlocListener<PairDeviceBloc, PairDeviceStates>(
          listener: (context, state) {
            if (state is PairDeviceSuccess) {
              final selectedPc = _selectedPc;
              if (selectedPc == null) return;

              final wasPairCodeDialogOpen = _isPairCodeDialogOpen;
              _isPairCodeDialogOpen = false;
              final navigator = Navigator.of(context, rootNavigator: true);
              final rootContext = navigator.context;

              // Save cash drawer from API response if available
              if (state.response.cashDrawer != null &&
                  state.response.cashDrawer!.isNotEmpty) {
                rootContext.read<SettingsBloc>().add(
                  SaveCashDrawerIdentifierEvent(state.response.cashDrawer!),
                );
              }
              
              // Close the pair code dialog if it's open
              if (wasPairCodeDialogOpen) {
                navigator.pop();
              }
              // Close the network PC dialog, but stay on the current screen
              navigator.pop();

              rootContext.read<ShopfrontBloc>().add(
                FetchShopsFromApi(
                  ipAddress: selectedPc.ipAddress,
                  port: _selectedPort,
                  apiKey: state.response.apiKey,
                ),
              );

              showDialog(
                context: rootContext,
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

              // Show success message after dialog is opened
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                final overlay = Overlay.maybeOf(rootContext);
                if (overlay != null) {
                  AlertInfo.show(
                    context: rootContext,
                    text: state.response.message,
                    typeInfo: TypeInfo.success,
                    backgroundColor: colors.surface,
                    iconColor: kPrimaryColor,
                    textColor: colors.onSurface,
                    padding: 70,
                    position: MessagePosition.top,
                  );
                }
              });
            }

            if (state is PairDeviceError) {
              _pairAttempts.value++;

              if (_pairAttempts.value >= _maxPairAttempts) {
                // Close the pair code dialog after max attempts
                if (_isPairCodeDialogOpen) {
                  _isPairCodeDialogOpen = false;
                  Navigator.of(context, rootNavigator: true).pop();
                  _showError(context, "Maximum attempts reached. Please tap the server again to get a new code.");
                }
              } else {
                // Show feedback inside the dialog (below the code fields)
                _pairError.value = state.message;
                _otpKey.currentState?.clear();
              }
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
          maxWidth: context.useDesktopNav ? 520 : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModernDialogHeader(
                title: "Network Servers",
                icon: Icons.dns_rounded,
                subtitle: "Select a server to connect",
                trailing: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: colors.isDark ? Colors.white70 : kPrimaryColor,
                  ),
                  tooltip: "Close",
                ),
              ),
              // Display warning message if provided
              if (widget.message != null && widget.message!.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(colors.isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.message!,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.isDark ? Colors.orange.shade200 : Colors.orange.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Flexible(
                child: BlocBuilder<FetchingNetworkServerBloc, FetchingNetworkServerStates>(
                  builder: (context, state) {
                    if (state is FetchingNetworkServers) {
                      return const SingleChildScrollView(
                        child: ModernLoadingState(
                          message: "Finding Network Servers",
                          subtitle: "This may take a few seconds...",
                        ),
                      );
                    } else if (state is ErrorFetchingNetworkServers) {
                      return SingleChildScrollView(
                        child: ModernErrorState(
                          message: state.message,
                          onRetry: () {
                            context.read<FetchingNetworkServerBloc>().add(
                              FetchNetworkServerEvent(),
                            );
                          },
                        ),
                      );
                    } else if (state is NetworkServersLoaded) {
                      if (state.pcList.isEmpty) {
                        return SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const ModernEmptyState(
                                message: "No servers found on the network",
                                icon: Icons.dns_outlined,
                              ),
                              const SizedBox(height: 16),
                              TextButton.icon(
                                onPressed: () => _showManualConnectionDialog(context),
                                icon: const Icon(Icons.link_rounded, size: 18),
                                label: const Text("Connect Manually"),
                                style: TextButton.styleFrom(
                                  foregroundColor: kPrimaryColor,
                                ),
                              ),
                            ],
                          ),
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
    final bool useDesktopNav = ctx.useDesktopNav;
    final double titleFontSize = useDesktopNav ? 13.0 : 15.0;
    final double subtitleFontSize = useDesktopNav ? 11.0 : 12.0;
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
                          fontSize: titleFontSize,
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
                          fontSize: subtitleFontSize,
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

/// Separate StatefulWidget for manual connection dialog to properly manage TextEditingControllers
class _ManualConnectionDialogContent extends StatefulWidget {
  final void Function(String ip, String code, int port) onConnect;
  final void Function(String message) onError;

  const _ManualConnectionDialogContent({
    required this.onConnect,
    required this.onError,
  });

  @override
  State<_ManualConnectionDialogContent> createState() => _ManualConnectionDialogContentState();
}

class _ManualConnectionDialogContentState extends State<_ManualConnectionDialogContent> {
  static const int _defaultAgentPort = 5000;
  
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: _defaultAgentPort.toString());

  @override
  void dispose() {
    _ipController.dispose();
    _codeController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _handleConnect() {
    final ip = _ipController.text.trim();
    final code = _codeController.text.trim();
    final portText = _portController.text.trim();

    if (ip.isEmpty) {
      widget.onError("Please enter host IP.");
      return;
    }
    if (code.isEmpty) {
      widget.onError("Please enter pairing code.");
      return;
    }

    int port = _defaultAgentPort;
    if (portText.isNotEmpty) {
      final parsedPort = int.tryParse(portText);
      if (parsedPort == null || parsedPort <= 0 || parsedPort > 65535) {
        widget.onError("Please enter a valid port (1-65535).");
        return;
      }
      port = parsedPort;
    }

    widget.onConnect(ip, code, port);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool useDesktopNav = context.useDesktopNav;
    final double labelFontSize = useDesktopNav ? 11.0 : 13.0;
    final double inputFontSize = useDesktopNav ? 13.0 : 15.0;
    final double buttonFontSize = useDesktopNav ? 13.0 : 15.0;
    final double iconSize = useDesktopNav ? 18.0 : 20.0;

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = screenHeight - keyboardHeight - 48;
    final double maxDialogHeight = (availableHeight * 0.85).clamp(380.0, 620.0);

    return Dialog(
      insetPadding: dialogInsetPadding(context),
      shape: ModernDialogStyles.dialogShape,
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ModernDialogContainer(
        maxHeight: maxDialogHeight,
        maxWidth: useDesktopNav ? 520 : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModernDialogHeader(
              title: "Manual Connection",
              icon: Icons.link_rounded,
              subtitle: "Enter server details to connect",
              trailing: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close,
                  color: isDark ? Colors.white70 : kPrimaryColor,
                ),
                tooltip: "Close",
              ),
            ),
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
                      controller: _ipController,
                      textAlignVertical: TextAlignVertical.center,
                      style: TextStyle(
                        color: isDark ? Colors.white : colors.onSurface,
                        fontSize: inputFontSize,
                        fontWeight: FontWeight.w500,
                      ),
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
                      controller: _codeController,
                      textAlignVertical: TextAlignVertical.center,
                      style: TextStyle(
                        color: isDark ? Colors.white : colors.onSurface,
                        fontSize: inputFontSize,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: ModernDialogStyles.inputDecoration(
                        context,
                        hintText: "Enter pairing code",
                        prefixIcon: Icons.key_outlined,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Port input
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Port (Optional)",
                        style: TextStyle(
                          color: isDark ? Colors.white70 : colors.onSurface,
                          fontSize: labelFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _portController,
                      textAlignVertical: TextAlignVertical.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        color: isDark ? Colors.white : colors.onSurface,
                        fontSize: inputFontSize,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: ModernDialogStyles.inputDecoration(
                        context,
                        hintText: "Default: $_defaultAgentPort",
                        prefixIcon: Icons.numbers_outlined,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Connect button
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                          borderRadius: BorderRadius.circular(ModernDialogStyles.buttonRadius),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _handleConnect,
                            borderRadius: BorderRadius.circular(ModernDialogStyles.buttonRadius),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: useDesktopNav ? 12 : 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.link_rounded,
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
  }
}

/// Professional segmented verification-code input (6 cube fields).
class _OtpCodeInput extends StatefulWidget {
  const _OtpCodeInput({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
  });

  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  @override
  State<_OtpCodeInput> createState() => _OtpCodeInputState();
}

class _OtpCodeInputState extends State<_OtpCodeInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers =
        List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  /// Clears all fields and refocuses the first one.
  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    if (mounted) {
      FocusScope.of(context).requestFocus(_focusNodes.first);
      setState(() {});
    }
    widget.onChanged?.call("");
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _notify() {
    final code = _code;
    widget.onChanged?.call(code);
    if (code.length == widget.length && !code.contains(' ')) {
      widget.onCompleted?.call(code);
    }
  }

  void _onChanged(int index, String value) {
    // Handle paste of full code into a single field
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (int i = 0; i < widget.length; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final next = digits.length >= widget.length
          ? widget.length - 1
          : digits.length;
      FocusScope.of(context).requestFocus(_focusNodes[next]);
      setState(() {});
      _notify();
      return;
    }

    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        _focusNodes[index].unfocus();
      }
    }
    setState(() {});
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool useDesktopNav = context.useDesktopNav;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Horizontal gap between each cube.
        final double gap = useDesktopNav ? 8 : 8;
        final double maxBoxWidth = useDesktopNav ? 44 : 50;
        // Fit all boxes within the available width to avoid overflow.
        final double available = constraints.maxWidth;
        final double rawWidth =
            (available - gap * (widget.length - 1)) / widget.length;
        final double boxWidth = rawWidth.clamp(34.0, maxBoxWidth);
        final double boxHeight = boxWidth * 1.18;
        final double fontSize = (boxWidth * 0.42).clamp(16.0, 22.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (index) {
            final bool hasValue = _controllers[index].text.isNotEmpty;
            return Padding(
              padding: EdgeInsets.only(
                right: index == widget.length - 1 ? 0 : gap,
              ),
              child: SizedBox(
                width: boxWidth,
                height: boxHeight,
                child: KeyboardListener(
                  focusNode: FocusNode(skipTraversal: true),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.backspace &&
                        _controllers[index].text.isEmpty &&
                        index > 0) {
                      _controllers[index - 1].clear();
                      FocusScope.of(context)
                          .requestFocus(_focusNodes[index - 1]);
                      setState(() {});
                      _notify();
                    }
                  },
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    onChanged: (value) => _onChanged(index, value),
                    onTap: () {
                      _controllers[index].selection =
                          TextSelection.collapsed(
                        offset: _controllers[index].text.length,
                      );
                      setState(() {});
                    },
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: widget.length,
                    showCursor: true,
                    cursorColor: kPrimaryColor,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: TextStyle(
                      color: isDark ? Colors.white : colors.onSurface,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      counterText: "",
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.06)
                          : const Color(0xFFF5F7FA),
                      contentPadding: EdgeInsets.zero,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: hasValue
                              ? kPrimaryColor.withOpacity(0.6)
                              : (isDark
                                  ? Colors.white.withOpacity(0.12)
                                  : Colors.black.withOpacity(0.08)),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: kPrimaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
