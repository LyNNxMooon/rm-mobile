import 'package:alert_info/alert_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/entities/vos/network_computer_vo.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/global_widgets.dart';
import '../../../../constants/txt_styles.dart';

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
  NetworkComputerVO? _selectedPc;
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

  void _startPairingFlow(NetworkComputerVO pc, BuildContext context) {
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  void _showPairCodeDialog(BuildContext context, String pairCode) {
    _connectCodeController.clear();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 10,
        backgroundColor: kBgColor,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 340),
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
                    const Icon(Icons.key_rounded, color: kSecondaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Pair With Host",
                        style: getSmartTitle(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kGreyColor.withOpacity(0.3)),
                        color: kSecondaryColor.withOpacity(0.2),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              pairCode,
                              style: TextStyle(fontSize: 20, color: kThirdColor),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: pairCode));
                              AlertInfo.show(
                                context: context,
                                text: "Pair code copied",
                                typeInfo: TypeInfo.success,
                                backgroundColor: kSecondaryColor,
                                iconColor: kPrimaryColor,
                                textColor: kThirdColor,
                                padding: 70,
                                position: MessagePosition.top,
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 20),
                            color: kPrimaryColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 45,
                      child: CustomTextField(
                        hintText: "Enter Code",
                        controller: _connectCodeController,
                        leadingIcon: Icons.keyboard_alt_outlined,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: BlocBuilder<PairDeviceBloc, PairDeviceStates>(
                        builder: (context, pairState) {
                          return ElevatedButton(
                            onPressed: pairState is PairingDevice
                                ? null
                                : () {
                                    if (_selectedPc == null) return;

                                    final pairingCode = _connectCodeController.text
                                        .trim();
                                    if (pairingCode.isEmpty) {
                                      _showError(
                                        context,
                                        "Please enter pairing code.",
                                      );
                                      return;
                                    }

                                    context.read<PairDeviceBloc>().add(
                                      PairDeviceEvent(
                                        ip: _selectedPc!.ipAddress,
                                        hostName:
                                            _selectedPc!.hostName ?? "Unknown-PC",
                                        port: _selectedPort,
                                        pairingCode: pairingCode,
                                      ),
                                    );
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
                            child: pairState is PairingDevice
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        kSecondaryColor,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    "Connect",
                                    style: TextStyle(
                                      color: kSecondaryColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
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
    // Calculate a safe max height (e.g., 70% of screen)
    final double safeMaxHeight = MediaQuery.of(context).size.height * 0.7;
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
                barrierDismissible: false,
                context: navigator.context,
                builder: (_) => ShopfrontsDialog(
                  pc: NetworkComputerVO(
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
                backgroundColor: kSecondaryColor,
                iconColor: kPrimaryColor,
                textColor: kThirdColor,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 10,
        backgroundColor: kBgColor,
        child: Container(
          constraints: BoxConstraints(maxHeight: safeMaxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 26),
                decoration: const BoxDecoration(
                  gradient: kGColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.computer, color: kSecondaryColor),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        "Network PCs",
                        style: getSmartTitle(fontSize: 18),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: BlocBuilder<FetchingNetworkPCBloc, FetchingNetworkPCStates>(
                  builder: (context, state) {
                    if (state is FetchingNetworkPCs) {
                      return Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Finding Network PCs...",
                                style: getSmartTitle(color: kThirdColor, fontSize: 16),
                              ),
                              Container(
                                width: 200,
                                padding: const EdgeInsets.only(top: 25, bottom: 5),
                                child: ModernLoadingBar(),
                              ),
                              const Text(
                                "This may take a few seconds.",
                                style: TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (state is ErrorFetchingNetworkPCs) {
                      return Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: kErrorColor,
                                size: 40,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: kGreyColor),
                              ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: () {
                                  context.read<FetchingNetworkPCBloc>().add(
                                    FetchNetworkPCEvent(),
                                  );
                                },
                                child: const Text(
                                  "Retry",
                                  style: TextStyle(color: kPrimaryColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (state is NetworkPCsLoaded) {
                      if (state.pcList.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(30),
                          child: Text("No computers found on the network."),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: state.pcList.length,
                        separatorBuilder: (ctx, i) => Divider(
                          color: kGreyColor.withOpacity(0.2),
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          return _buildPCTile(state.pcList[index], context);
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

  Widget _buildPCTile(NetworkComputerVO pc, BuildContext ctx) {
    return InkWell(
      onTap: () {
        _startPairingFlow(pc, ctx);

        // Auto-connection flow intentionally disabled for now.
        // ctx.read<AutoConnectionBloc>().add(
        //   AutoConnectToDefaultFolderEvent(
        //     ipAddress: pc.ipAddress,
        //     hostName: pc.hostName,
        //   ),
        // );
      },
      splashColor: kPrimaryColor.withOpacity(0.1),
      highlightColor: kPrimaryColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            SizedBox(
              height: 35,
              width: 35,
              child: Image.asset("assets/images/pc.png", fit: BoxFit.fill),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                pc.hostName ?? "Unknown-PC",
                style: const TextStyle(color: kThirdColor),
                maxLines: 1, // Fix overflow
                overflow: TextOverflow.ellipsis, // Fix overflow
              ),
            ),
            if (_isPairFlowLoading && _selectedPc?.ipAddress == pc.ipAddress)
              const CupertinoActivityIndicator()
            else
              const Icon(
                Icons.arrow_forward_ios,
                color: kGreyColor,
                size: 14,
              ),

            // Auto-connection flow intentionally disabled for now.
            // BlocConsumer<AutoConnectionBloc, AutoConnectionStates>(
            //   listenWhen: (previous, current) => previous != current,
            //   listener: (context, state) {
            //     if (state is AutoConnectedToPublicFolder) {
            //       AlertInfo.show(
            //         context: ctx,
            //         text: state.message,
            //         typeInfo: TypeInfo.success,
            //         backgroundColor: kSecondaryColor,
            //         iconColor: kPrimaryColor,
            //         textColor: kThirdColor,
            //         padding: 70,
            //         position: MessagePosition.top,
            //       );
            //
            //       ctx.navigateUntilFirst();
            //
            //       ctx.read<ShopfrontBloc>().add(
            //         FetchShops(
            //           path:
            //               AppGlobals.instance.currentPath ??
            //               "//${AppGlobals.instance.currentHostIp ?? ""}/C/AAAPOS RM-Mobile",
            //           ipAddress: AppGlobals.instance.currentHostIp ?? "",
            //         ),
            //       );
            //
            //       showDialog(
            //         context: ctx,
            //         builder: (_) => ShopfrontsDialog(
            //           pc: NetworkComputerVO(
            //             ipAddress: AppGlobals.instance.currentHostIp ?? "",
            //             hostName: AppGlobals.instance.hostName ?? "",
            //           ),
            //           previousPath:
            //               AppGlobals.instance.currentPath ??
            //               "//${AppGlobals.instance.currentHostIp ?? ""}/C/AAAPOS RM-Mobile",
            //         ),
            //       );
            //     }
            //
            //     if (state is ErrorAutoConnection) {
            //       Navigator.of(ctx, rootNavigator: true).pop();
            //
            //       ctx.read<GettingDirectoryBloc>().add(
            //         GetDirectoryEvent(
            //           ipAddress: state.pcHolder.ipAddress,
            //           path: "",
            //         ),
            //       );
            //
            //       showDialog(
            //         context: ctx,
            //         builder: (context) => FoldersDialog(pc: state.pcHolder),
            //       );
            //     }
            //   },
            //   builder: (_, state) {
            //     if (state is LoadingAutoConnection &&
            //         state.ipAddress == pc.ipAddress) {
            //       return const CupertinoActivityIndicator();
            //     } else {
            //       return const Icon(
            //         Icons.arrow_forward_ios,
            //         color: kGreyColor,
            //         size: 14,
            //       );
            //     }
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}
