import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/utils/navigation_extension.dart';
import '../../../../constants/theme_colors.dart';
//import '../../../../constants/txt_styles.dart';
//import '../../../../utils/global_var_utils.dart';
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
    final double networkIconSize = isLargeTablet ? 40 : isTablet ? 30 : 22;
    final double settingsIconSize = isLargeTablet ? 32 : isTablet ? 30 : 22;
    //final double glassPadding = isTablet ? 12.0 : 11.0;
    final double horizontalPadding = isTablet ? 22 : 16;

    return Padding(
      padding: EdgeInsets.only(right: horizontalPadding, left: horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // --- LEFT SIDE: LOGO ---
          Flexible(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(
                "assets/images/trademark.png",
                height: isTablet ? 38 : 30,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // --- RIGHT SIDE: ACTIONS (faint circular icon buttons) ---
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Network/Wifi Button
              _CircleIconButton(
                icon: Icons.laptop_mac_sharp,
                iconSize: networkIconSize,
                isDark: isDark,
                color: isDark ? Colors.white : colors.onHero,
                onTap: () {
                  if (_isSyncInProgress(context)) {
                    _showSyncBlockedMessage(context);
                    return;
                  }
                  context
                      .read<FetchingNetworkServerBloc>()
                      .add(FetchNetworkServerEvent());
                  showDialog(
                    context: context,
                    builder: (context) => const NetworkPcDialog(),
                  );
                },
              ),

              const SizedBox(width: 10),

              // Settings Button
              _CircleIconButton(
                icon: Icons.settings_outlined,
                iconSize: settingsIconSize,
                isDark: isDark,
                color: isDark ? Colors.white : colors.onHero,
                onTap: () {
                  context.navigateToNext(const SettingsScreen());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final bool isDark;
  final Color color;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.iconSize,
    required this.isDark,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark
          ? Colors.white.withOpacity(0.08)
          : Colors.white.withOpacity(0.18),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            icon,
            size: iconSize,
            color: color,
          ),
        ),
      ),
    );
  }
}