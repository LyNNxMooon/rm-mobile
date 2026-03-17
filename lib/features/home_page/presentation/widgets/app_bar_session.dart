import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import '../../../../constants/theme_colors.dart';
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
    final colors = context.appColors;
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final isTablet = shortestSide >= 600;
    final isLargeTablet = shortestSide >= 900;
    final double networkIconSize = isLargeTablet ? 52 : isTablet ? 44 : 30;
    final double settingsIconSize = isLargeTablet ? 40 : isTablet ? 34 : 26;

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
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.amber,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              'Offline Mode',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade900,
                                fontWeight: FontWeight.w800,
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
                            color: colors.onHero,
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
                  width: networkIconSize,
                  height: networkIconSize,
                  child: Image.asset("assets/images/wifi.png"),
                ),
              ),
              const SizedBox(width: 10),

              IconButton(
                iconSize: settingsIconSize,
                onPressed: () {
                  context.navigateToNext(const SettingsScreen());
                },
                icon: Icon(Icons.settings, color: colors.onHero),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
