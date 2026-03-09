import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/global_var_utils.dart';
import '../BLoC/home_screen_bloc.dart';
import '../BLoC/home_screen_events.dart';
import '../BLoC/home_screen_states.dart';
import '../screens/settings_screen.dart';
import 'network_pc_dialog.dart';

class AppBarSession extends StatelessWidget {
  const AppBarSession({super.key});

  bool _isSyncInProgress(BuildContext context) {
    return context.read<FetchStockBloc>().state is FetchStockProgress;
  }

  void _showSyncBlockedMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Stock sync in progress. Please wait."),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 15, left: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Responsive Text Area
          Flexible(
            child: BlocBuilder<StaffAuthBloc, StaffAuthStates>(
              builder: (context, staffState) {
                return BlocBuilder<
                  ShopFrontConnectionBloc,
                  ShopfrontConnectionStates
                >(
                  builder: (context, state) {
                    return ValueListenableBuilder<String?>(
                      valueListenable: AppGlobals.instance.hostNameNotifier,
                      builder: (context, host, _) {
                        final bool isOffline = host == null || host.isEmpty;

                        if (isOffline) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: kErrorColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: kErrorColor),
                            ),
                            child: const Text(
                              'Offline Mode',
                              style: TextStyle(
                                fontSize: 14,
                                color: kErrorColor,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }

                        return Text(
                          "Server: $host",
                          style: getSmartTitle(
                            fontSize: 16,
                            color: kSecondaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(width: 10), // Safe gap

          Row(
            mainAxisSize: MainAxisSize.min, // Wrap content
            children: [
              InkWell(
                onTap: () {
                  if (_isSyncInProgress(context)) {
                    _showSyncBlockedMessage(context);
                    return;
                  }

                  context.read<FetchingNetworkServerBloc>().add(
                    FetchNetworkServerEvent(),
                  );

                  showDialog(
                    context: context,
                    builder: (context) {
                      return const NetworkPcDialog();
                    },
                  );
                },
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: Image.asset("assets/images/wifi.png"),
                ),
              ),
              const SizedBox(width: 10),

              IconButton(
                iconSize: 26,
                onPressed: () {
                  context.navigateToNext(const SettingsScreen());
                },
                icon: const Icon(Icons.settings, color: kSecondaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
