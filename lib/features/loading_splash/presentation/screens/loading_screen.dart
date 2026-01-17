import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/features/loading_splash/presentation/BLoC/loading_splash_bloc.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/global_widgets.dart';
import '../../../../constants/images.dart';
import '../../../../constants/txt_styles.dart';
import '../BLoC/loading_splash_states.dart';
import '../widgets/network_path_dialog.dart';


class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<NetworkSavedPathValidationBloc, LoadingSplashStates>(
      listener: (context, state) {
        if (state is SavedPathFetchingCompleted) {
          showDialog(

            barrierDismissible: false,
            context: context,
            builder: (context) {
              return NetworkPathDialog(paths: state.paths,);
            },
          );
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: kGColor),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 120,
                  child: Image.asset(appLogo, fit: BoxFit.fill),
                ),
                const SizedBox(height: 20),
                Text(
                  "RetailManager Mobile",
                  style: getSmartTitle(color: kSecondaryColor, fontSize: 24),
                ),
                const SizedBox(height: 5),
                Text(
                  "AAAPOS Pty Ltd",
                  style: TextStyle(
                    color: kSecondaryColor.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 25),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 90),
                  child: ModernLoadingBar(),
                ),
                const SizedBox(height: 10),
                Text(
                  "Checking Connection...",
                  style: TextStyle(
                    color: kSecondaryColor.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
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
