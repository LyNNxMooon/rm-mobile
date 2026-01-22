import 'package:alert_info/alert_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/entities/vos/network_computer_vo.dart';
import 'package:rmstock_scanner/features/home_page/presentation/widgets/shopfronts_dialog.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/global_widgets.dart';
import '../../../../constants/txt_styles.dart';

import '../../../../utils/global_var_utils.dart';
import '../BLoC/home_screen_bloc.dart';
import '../BLoC/home_screen_events.dart';
import '../BLoC/home_screen_states.dart';
import 'folders_dialog.dart';

class NetworkPcDialog extends StatefulWidget {
  const NetworkPcDialog({super.key});

  @override
  State<NetworkPcDialog> createState() => _NetworkPcDialogState();
}

class _NetworkPcDialogState extends State<NetworkPcDialog> {
  @override
  Widget build(BuildContext context) {
    // Calculate a safe max height (e.g., 70% of screen)
    final double safeMaxHeight = MediaQuery.of(context).size.height * 0.7;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 10,
      backgroundColor: kBgColor,
      child: Container(
        // Responsive constraint
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
                      child: SingleChildScrollView( // Prevent overflow if screen is very short
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Finding Network PCs...",
                              style: getSmartTitle(
                                color: kThirdColor,
                                fontSize: 16,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 25,
                                left: 60,
                                right: 60,
                                bottom: 5,
                              ),
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
    );
  }

  Widget _buildPCTile(NetworkComputerVO pc, BuildContext ctx) {
    return InkWell(
      onTap: () {
        ctx.read<AutoConnectionBloc>().add(
          AutoConnectToDefaultFolderEvent(
            ipAddress: pc.ipAddress,
            hostName: pc.hostName,
          ),
        );
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
            BlocConsumer<AutoConnectionBloc, AutoConnectionStates>(
              listenWhen: (previous, current) => previous != current,
              listener: (context, state) {
                if (state is AutoConnectedToPublicFolder) {
                  AlertInfo.show(
                    context: ctx,
                    text: state.message,
                    typeInfo: TypeInfo.success,
                    backgroundColor: kSecondaryColor,
                    iconColor: kPrimaryColor,
                    textColor: kThirdColor,
                    padding: 70,
                    position: MessagePosition.top
                  );

                  ctx.navigateUntilFirst();

                  ctx.read<ShopfrontBloc>().add(
                    FetchShops(
                      path: AppGlobals.instance.currentPath ??
                          "//${AppGlobals.instance.currentHostIp ?? ""}/Users/Public/AAAPOS RM-Mobile",
                      ipAddress: AppGlobals.instance.currentHostIp ?? "",
                    ),
                  );

                  showDialog(
                    context: ctx,
                    builder: (_) => ShopfrontsDialog(
                      pc: NetworkComputerVO(
                        ipAddress: AppGlobals.instance.currentHostIp ?? "",
                        hostName: AppGlobals.instance.hostName ?? "",
                      ),
                      previousPath: AppGlobals.instance.currentPath ??
                          "//${AppGlobals.instance.currentHostIp ?? ""}/Users/Public/AAAPOS RM-Mobile",
                    ),
                  );
                }

                if (state is ErrorAutoConnection) {
                  Navigator.of(ctx, rootNavigator: true).pop();

                  ctx.read<GettingDirectoryBloc>().add(
                    GetDirectoryEvent(
                      ipAddress: state.pcHolder.ipAddress,
                      path: "",
                    ),
                  );

                  showDialog(
                    context: ctx,
                    builder: (context) => FoldersDialog(pc: state.pcHolder),
                  );
                }
              },
              builder: (_, state) {
                if (state is LoadingAutoConnection &&
                    state.ipAddress == pc.ipAddress) {
                  return const CupertinoActivityIndicator();
                } else {
                  return const Icon(
                    Icons.arrow_forward_ios,
                    color: kGreyColor,
                    size: 14,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}