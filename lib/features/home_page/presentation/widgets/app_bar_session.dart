import 'dart:ui'; // Required for blur effect
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/constants/colors.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../utils/responsive_utils.dart';
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
    final bool isDark = colors.isDark;
    final isTablet = context.isTablet;
    final isLargeTablet = context.isLargeTablet;

    // Responsive Sizing
    final double networkIconSize = isLargeTablet ? 42 : isTablet ? 32 : 22;
    final double settingsIconSize = isLargeTablet ? 32 : isTablet ? 30 : 22;
    final double glassPadding = isTablet ? 12.0 : 11.0;

    return Padding(
      padding: const EdgeInsets.only(right: 24, left: 26),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // --- LEFT SIDE: SERVER STATUS (Glass Container) ---
          Flexible(
            child: BlocBuilder<StaffAuthBloc, StaffAuthStates>(
              builder: (context, staffState) {
                return BlocBuilder<ShopFrontConnectionBloc, ShopfrontConnectionStates>(
                  builder: (context, state) {
                    return ValueListenableBuilder<String?>(
                      valueListenable: AppGlobals.instance.hostNameNotifier,
                      builder: (context, host, _) {
                        final bool isOffline = host == null || host.isEmpty;

                        if (isOffline) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber, width: 1.5),
                            ),
                            child: Text(
                              'Offline Mode',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                color: Colors.grey.shade900,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          );
                        }

                        // Frosted Glass Server Pill
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: glassPadding, vertical: glassPadding - 1.5),
                              decoration: BoxDecoration(
                                // Darker glass fill for dark mode to match drawer
                                color: isDark
                                    ? Colors.black.withOpacity(0.13)
                                    : colors.glassFill,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.15)
                                      : colors.glassBorder,
                                  width: isDark ? 1.5 : 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Icon(
                                  //   Icons.lan_outlined,
                                  //   size: 16,
                                  //   color: isDark ? Colors.white70 : colors.onHero.withOpacity(0.7),
                                  // ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      "Server: $host",
                                      style: getSmartTitle(
                                        fontSize: isTablet ? 17 : 15,
                                        color: isDark ? Colors.white : colors.onHero,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(width: 20),

          // --- RIGHT SIDE: ACTIONS (Frosted Action Group) ---
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                decoration: BoxDecoration(
                  // Darker glass fill for dark mode to match drawer
                  color: isDark
                      ? Colors.black.withOpacity(0.13)
                      : colors.glassFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.15)
                        : colors.glassBorder,
                    width: isDark ? 1.5 : 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Network/Wifi Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (_isSyncInProgress(context)) {
                            _showSyncBlockedMessage(context);
                            return;
                          }
                          context.read<FetchingNetworkServerBloc>().add(FetchNetworkServerEvent());
                          showDialog(
                            context: context,
                            builder: (context) => const NetworkPcDialog(),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.laptop_mac_sharp,
                            size: networkIconSize,
                            color: isDark ? Colors.white : colors.onHero,
                          ),
                        ),
                      ),
                    ),
                    
                    // Spacing for tablets
                    if (isTablet) const SizedBox(width: 8),
                    
                    // Vertical Divider
                    Container(
                      height: 24,
                      width: 1,
                      color: kSecondaryColor,
                    ),
                    
                    // Spacing for tablets
                    if (isTablet) const SizedBox(width: 8),

                    // Settings Button
                    IconButton(
                      iconSize: settingsIconSize,
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        context.navigateToNext(const SettingsScreen());
                      },
                      icon: Icon(
                        Icons.settings_outlined,
                        color: isDark ? Colors.white : colors.onHero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}