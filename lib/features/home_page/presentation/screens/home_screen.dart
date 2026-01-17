import 'package:alert_info/alert_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import '../../../../constants/colors.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../utils/log_utils.dart';
import '../../../loading_splash/presentation/BLoC/loading_splash_bloc.dart';
import '../../../loading_splash/presentation/BLoC/loading_splash_states.dart';
import '../../../stock_lookup/presentation/widgets/stock_request_error_dialog.dart';
import '../../../stocktake/presentation/screens/scanner_screen.dart';
import '../BLoC/home_screen_bloc.dart';
import '../BLoC/home_screen_events.dart';
import '../BLoC/home_screen_states.dart';
import '../widgets/action_card.dart';
import '../widgets/app_bar_session.dart';
import '../widgets/glass_drawer.dart';
import '../widgets/network_pc_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    final currentParamState = context
        .read<NetworkSavedPathValidationBloc>()
        .state;

    if (currentParamState is ErrorFetchingSavedPaths ||
        currentParamState is ErrorCheckingConnection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNetworkDialog();
      });
    }

    if (currentParamState is ConnectionValid &&
        context.read<ShopFrontConnectionBloc>().state
            is! ConnectedToShopfront) {
      context.read<ShopFrontConnectionBloc>().add(
        ConnectToShopfrontEvent(
          ip: AppGlobals.instance.currentHostIp ?? "",
          shopName: AppGlobals.instance.shopfront ?? "",
        ),
      );
    }
  }

  void _showNetworkDialog() {
    // Check if a dialog is already showing to prevent duplicates
    if (ModalRoute.of(context)?.isCurrent != true) return;
    logger.d("State is noticed");
    context.read<FetchingNetworkPCBloc>().add(FetchNetworkPCEvent());
    showDialog(
      context: context,
      builder: (context) {
        return NetworkPcDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NetworkSavedPathValidationBloc, LoadingSplashStates>(
      listener: (context, state) {
        if (state is ErrorFetchingSavedPaths ||
            state is ErrorCheckingConnection) {
          _showNetworkDialog();
        }
      },
      child: SafeArea(
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(gradient: kGColor),
            child: Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 10),

                    const AppBarSession(),

                    const SizedBox(height: 38),

                    logo(),

                    const SizedBox(height: 40),

                    headerTitle(),

                    const SizedBox(height: 15),

                    ActionCard(
                      onTap: () => context.navigateToNext(ScannerScreen()),
                      title: "Start Stocktaking",
                      subtitle: "Begin Counting Inventory Items",
                    ),

                    syncWatcher(),

                    const SizedBox(height: 100),
                  ],
                ),
                GlassDrawer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget logo() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        width: double.infinity,
        height: 75,
        child: Image.asset("assets/images/trademark.png", fit: BoxFit.fill),
      ),
    );
  }

  Widget headerTitle() {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xC786D0EF),
            Color(0xFFFFFFFF),
            Color(0xFFCCC8C8),
            Color(0xC760C3EE),
            Color(0xFFFFFFFF),
            Color(0xC760C3EE),
          ],
        ).createShader(bounds);
      },

      blendMode: BlendMode.srcIn,
      child: Text(
        "Welcome to RM - Mobile",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget syncWatcher() {
    return BlocListener<ShopFrontConnectionBloc, ShopfrontConnectionStates>(
      listenWhen: (previous, current) =>
          previous is! ConnectedToShopfront && current is ConnectedToShopfront,
      listener: (context, state) {
        if (state is ConnectedToShopfront) {
          context.read<FetchStockBloc>().add(
            StartSyncEvent(ipAddress: AppGlobals.instance.currentHostIp ?? ""),
          );

          AlertInfo.show(
            context: context,
            text: "Stock requested!",
            typeInfo: TypeInfo.success,
            backgroundColor: kSecondaryColor,
            iconColor: kPrimaryColor,
            textColor: kThirdColor,
          );
        }

        if (state is ShopfrontConnectionError) {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.error(message: state.message),
          );

          showDialog(
            context: context,
            builder: (context) {
              return StockRequestErrorDialog(message: state.message);
            },
          );
        }
      },
      child: const SizedBox(),
    );
  }
}
