import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../loading_splash/presentation/BLoC/loading_splash_bloc.dart';
import '../../../loading_splash/presentation/BLoC/loading_splash_states.dart';
import '../BLoC/home_screen_bloc.dart';
import '../BLoC/home_screen_events.dart';
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
          BlocBuilder<NetworkSavedPathValidationBloc, LoadingSplashStates>(
            builder: (context, state) {
              if (state is ConnectionValid) {
                String pcName =
                    "PC: ${AppGlobals.instance.hostName ?? "UnknownPC"}";

                if (pcName.length > 21) {
                  pcName = "${pcName.substring(0, 21)}...";
                }
                return Text(
                  pcName,
                  style: getSmartTitle(fontSize: 18, color: kSecondaryColor),
                );
              } else {
                return Text(
                  'Connect To Network...',
                  style: getSmartTitle(fontSize: 18, color: kSecondaryColor),
                );
              }
            },
          ),

          Row(
            children: [
              InkWell(
                onTap: () {
                  context.read<FetchingNetworkPCBloc>().add(
                    FetchNetworkPCEvent(),
                  );

                  showDialog(

                    context: context,
                    builder: (context) {
                      return NetworkPcDialog();
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
                onPressed: () {},
                icon: Icon(
                  Icons.notifications_active_outlined,
                  color: kSecondaryColor,
                ),
              ),

              IconButton(
                iconSize: 26,
                onPressed: () {},
                icon: Icon(Icons.settings, color: kSecondaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
