import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../loading_splash/presentation/BLoC/loading_splash_bloc.dart';
import '../../../loading_splash/presentation/BLoC/loading_splash_states.dart';
import '../BLoC/home_screen_bloc.dart';
import '../BLoC/home_screen_events.dart';
import '../screens/settings_screen.dart';
import 'network_pc_dialog.dart';

class AppBarSession extends StatelessWidget {
  const AppBarSession({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 15, left: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Responsive Text Area
          Flexible(
            child: BlocBuilder<NetworkSavedPathValidationBloc, LoadingSplashStates>(
              builder: (context, state) {
                String displayText;

                if (state is ConnectionValid) {
                  displayText = "PC: ${AppGlobals.instance.hostName ?? "UnknownPC"}";
                } else {
                  displayText = 'Connect To Network...';
                }

                return Text(
                  displayText,
                  style: getSmartTitle(fontSize: 18, color: kSecondaryColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis, // Safe handling of long names
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
                  context.read<FetchingNetworkPCBloc>().add(
                    FetchNetworkPCEvent(),
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