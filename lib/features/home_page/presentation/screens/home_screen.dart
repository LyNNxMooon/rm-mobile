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
    if (ModalRoute.of(context)?.isCurrent != true) return;
    logger.d("State is noticed");
    context.read<FetchingNetworkPCBloc>().add(FetchNetworkPCEvent());
    showDialog(
      context: context,
      builder: (context) {
        return const NetworkPcDialog();
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
      child: Scaffold(
        extendBody: true,
        backgroundColor: kPrimaryColor,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: kGColor),
          child: SafeArea(
            bottom: false,
            top: true,
            child: Stack(
              children: [
                // 1. Wrap Column in SingleChildScrollView to prevent overflow on small screens
                SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      const AppBarSession(),

                      const SizedBox(height: 38),

                      logo(),

                      const SizedBox(height: 32),

                      headerTitle(),

                      const SizedBox(height: 15),

                      ActionCard(
                        onTap: () {
                          final currentState = context
                              .read<FetchStockBloc>()
                              .state;

                          if (currentState is! FetchStockProgress) {
                            context.read<ShopFrontConnectionBloc>().add(
                              ConnectToShopfrontEvent(
                                ip: AppGlobals.instance.currentHostIp ?? "",
                                shopName: AppGlobals.instance.shopfront ?? "",
                              ),
                            );
                          }

                          context.navigateToNext(const ScannerScreen());
                        },
                        title: "Start Stocktaking",
                        subtitle: "Begin Counting Inventory Items",
                      ),

                      syncWatcher(),

                      // Ensure enough space at bottom so drawer doesn't cover content completely
                      const SizedBox(height: 120),
                    ],
                  ),
                ),

                // 2. Drawer sits on top
                const GlassDrawer(),
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
        child: Image.asset("assets/images/trademark.png", fit: BoxFit.contain), // Changed to contain for safety
      ),
    );
  }

  Widget headerTitle() {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
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
      child: const Text(
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
            position: MessagePosition.top,
            padding: 70,
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