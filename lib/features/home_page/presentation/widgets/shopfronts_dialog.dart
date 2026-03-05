import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/entities/vos/network_server_vo.dart';
import 'package:rmstock_scanner/features/loading_splash/presentation/BLoC/loading_splash_bloc.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/global_widgets.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/dialog_size_utils.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../utils/log_utils.dart';
import '../../../loading_splash/presentation/BLoC/loading_splash_events.dart';
import '../BLoC/home_screen_bloc.dart';
import '../BLoC/home_screen_events.dart';
import '../BLoC/home_screen_states.dart';

class ShopfrontsDialog extends StatefulWidget {
  const ShopfrontsDialog({
    super.key,
    required this.pc,
    required this.previousPath,
    this.isPairedFlow = false,
    this.port,
    this.apiKey,
  });

  final NetworkServerVO pc;
  final String previousPath;
  final bool isPairedFlow;
  final int? port;
  final String? apiKey;

  @override
  State<ShopfrontsDialog> createState() => _ShopfrontsDialogState();
}

class _ShopfrontsDialogState extends State<ShopfrontsDialog> {
  final _userNameController = TextEditingController();
  final _pwdController = TextEditingController();
  final _staffNoController = TextEditingController();
  final _staffPwdController = TextEditingController();

  String? _expandedShop;

  @override
  void dispose() {
    _userNameController.dispose();
    _pwdController.dispose();
    _staffNoController.dispose();
    _staffPwdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double maxDialogHeight = (MediaQuery.of(context).size.height * 0.78)
        .clamp(420.0, 780.0);
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    final double errorFieldHeight = (isTablet ? 44 : 40) * uiScale;
    final double errorButtonVerticalPadding = (isTablet ? 12 : 1) * uiScale;

    return MultiBlocListener(
      listeners: [
        BlocListener<ShopFrontConnectionBloc, ShopfrontConnectionStates>(
          listenWhen: (previous, current) =>
              previous is! ConnectedToShopfront &&
              current is ConnectedToShopfront,
          listener: (context, state) {
            if (state is ConnectedToShopfront && !widget.isPairedFlow) {
              context.read<NetworkSavedPathValidationBloc>().add(
                ConnectionCheckingEvent(AppGlobals.instance.currentPath ?? ""),
              );

              context.navigateBack();
            }

            if (state is ShopfrontConnectionError) {
              showTopSnackBar(
                Overlay.of(context),
                CustomSnackBar.error(message: state.message),
              );
            }
          },
        ),
        BlocListener<StaffAuthBloc, StaffAuthStates>(
          listener: (context, state) {
            if (state is StaffAuthenticated) {
              if (widget.isPairedFlow) {
                context.read<FetchStockBloc>().add(
                  StartSyncEvent(
                    ipAddress: AppGlobals.instance.currentHostIp ?? "",
                  ),
                );

                showTopSnackBar(
                  Overlay.of(context),
                  CustomSnackBar.success(message: state.response.message),
                );

                context.navigateBack();
              } else {
                final selectedShop = _expandedShop;
                if (selectedShop != null) {
                  context.read<ShopFrontConnectionBloc>().add(
                    ConnectToShopfrontEvent(
                      ip: widget.pc.ipAddress,
                      shopName: selectedShop,
                    ),
                  );
                }
              }
            }

            if (state is StaffUnauthenticated) {
              showTopSnackBar(
                Overlay.of(context),
                CustomSnackBar.error(message: state.message),
              );
            }

            if (state is StaffAuthError) {
              showTopSnackBar(
                Overlay.of(context),
                CustomSnackBar.error(message: state.message),
              );
            }
          },
        ),
      ],
      child: Dialog(
        insetPadding: dialogInsetPadding(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 10,
        backgroundColor: kBgColor,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxDialogHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  gradient: kGColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.storefront_rounded,
                      color: kSecondaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Choose Shopfront",
                        style: getSmartTitle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: BlocBuilder<ShopfrontBloc, ShopFrontStates>(
                  builder: (context, state) {
                    if (state is ShopsLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(child: CupertinoActivityIndicator()),
                      );
                    }

                    if (state is ShopsError) {
                      logger.e(widget.previousPath);
                      if (widget.isPairedFlow) {
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
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () {
                                    if (widget.port != null &&
                                        widget.apiKey != null) {
                                      context.read<ShopfrontBloc>().add(
                                        FetchShopsFromApi(
                                          ipAddress: widget.pc.ipAddress,
                                          port: widget.port!,
                                          apiKey: widget.apiKey!,
                                        ),
                                      );
                                    }
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
                      }

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
                              const SizedBox(height: 20),
                              SizedBox(
                                height: errorFieldHeight,
                                child: CustomTextField(
                                  hintText: 'UserName',
                                  controller: _userNameController,
                                  leadingIcon: Icons.people,
                                ),
                              ),
                              const SizedBox(height: 5),
                              SizedBox(
                                height: errorFieldHeight,
                                child: CustomTextField(
                                  hintText: 'Password',
                                  controller: _pwdController,
                                  leadingIcon: Icons.password,
                                ),
                              ),
                              const SizedBox(height: 25),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        context.read<ShopfrontBloc>().add(
                                          FetchShops(
                                            ipAddress: widget.pc.ipAddress,
                                            path: widget.previousPath,
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: kPrimaryColor.withOpacity(0.5),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: errorButtonVerticalPadding,
                                        ),
                                      ),
                                      child: Text(
                                        "Retry as Guest",
                                        style: TextStyle(
                                          color: kPrimaryColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        context.read<ShopfrontBloc>().add(
                                          FetchShops(
                                            ipAddress: widget.pc.ipAddress,
                                            path: widget.previousPath,
                                            userName: _userNameController.text,
                                            pwd: _pwdController.text,
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kPrimaryColor,
                                        foregroundColor: kSecondaryColor,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: errorButtonVerticalPadding,
                                        ),
                                      ),
                                      child: const Text(
                                        "Try Logging in",
                                        style: TextStyle(
                                          color: kSecondaryColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (state is ShopsLoaded) {
                    if (state.shops.shopfronts.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(30),
                        child: Text("No shopfronts found."),
                      );
                    }

                      return ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: state.shops.shopfronts.length,
                        separatorBuilder: (ctx, i) => Divider(
                          color: kGreyColor.withOpacity(0.2),
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          final shopName = state.shops.shopfronts[index];
                          return _buildShopTile(shopName, context);
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
      ),
    );
  }

  Widget _buildShopTile(String shopName, BuildContext ctx) {
    final bool expanded = _expandedShop == shopName;

    return InkWell(
      onTap: () {
        setState(() {
          _expandedShop = expanded ? null : shopName;
          _staffNoController.clear();
          _staffPwdController.clear();
        });
      },
      splashColor: kPrimaryColor.withOpacity(0.1),
      highlightColor: kPrimaryColor.withOpacity(0.05),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    shopName.split(r'\\').last,
                    style: const TextStyle(color: kThirdColor),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: kGreyColor,
                ),
              ],
            ),
          ),
          if (expanded) _buildStaffSignInSection(shopName, ctx),
        ],
      ),
    );
  }

  Widget _buildStaffSignInSection(String shopName, BuildContext ctx) {
    final bool loading =
        ctx.watch<StaffAuthBloc>().state is StaffAuthenticating;
    final media = MediaQuery.of(ctx);
    final bool isTablet = media.size.shortestSide >= 600;
    final double textScale = MediaQuery.textScalerOf(ctx).scale(14) / 14;
    final double uiScale = (1.0 + ((textScale - 1.0) * 0.65)).clamp(1.0, 1.42);
    final double fieldHeight = isTablet
        ? (44 * uiScale).clamp(44.0, 58.0)
        : 36.0;
    final double buttonHeight = isTablet
        ? (42 * uiScale).clamp(42.0, 56.0)
        : 34.0;
    final double sectionPadding = isTablet ? 12.0 : 10.0;
    final double verticalGap1 = isTablet ? 8.0 : 6.0;
    final double verticalGap2 = isTablet ? 10.0 : 8.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      padding: EdgeInsets.fromLTRB(
        sectionPadding,
        sectionPadding,
        sectionPadding,
        isTablet ? 10 : 8,
      ),
      decoration: BoxDecoration(
        color: kSecondaryColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kGreyColor.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: fieldHeight,
            child: CustomTextField(
              controller: _staffNoController,
              keyboardType: TextInputType.number,
              hintText: 'Staff ID',
              leadingIcon: Icons.badge_outlined,
            ),
          ),
          SizedBox(height: verticalGap1),
          SizedBox(
            height: fieldHeight,
            child: CustomTextField(
              controller: _staffPwdController,
              hintText: 'Password',
              leadingIcon: Icons.lock_outline,
              obscureText: true,
            ),
          ),
          SizedBox(height: verticalGap2),
          SizedBox(
            width: double.infinity,
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: loading
                  ? null
                  : () => _onTapStaffSignIn(shopName, ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: kSecondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isTablet ? 9 : 7),
                ),
                padding: EdgeInsets.zero,
              ),
              child: loading
                  ? SizedBox(
                      height: isTablet ? 22 : 18,
                      width: isTablet ? 22 : 18,
                      child: CupertinoActivityIndicator(color: kSecondaryColor),
                    )
                  : const Text(
                      'Sign In',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onTapStaffSignIn(String shopName, BuildContext ctx) async {
    final staffNo = _staffNoController.text.trim();
    final password = _staffPwdController.text;

    if (staffNo.isEmpty) {
      showTopSnackBar(
        Overlay.of(ctx),
        const CustomSnackBar.error(message: 'Please enter staff ID.'),
      );
      return;
    }

    final apiKey =
        widget.apiKey ?? (await LocalDbDAO.instance.getApiKey() ?? "").trim();
    final int? port =
        widget.port ??
        int.tryParse((await LocalDbDAO.instance.getHostPort() ?? "").trim());
    final shopfrontId =
        AppGlobals.instance.pairedShopfrontIdsByName[shopName] ??
        (await LocalDbDAO.instance.getShopfrontId() ?? "").trim();

    if (apiKey.isEmpty || port == null || shopfrontId.isEmpty) {
      showTopSnackBar(
        Overlay.of(ctx),
        const CustomSnackBar.error(
          message: 'Unable to sign in. Missing required connection data.',
        ),
      );
      return;
    }

    ctx.read<StaffAuthBloc>().add(
      AuthenticateStaffEvent(
        ip: widget.pc.ipAddress,
        port: port,
        apiKey: apiKey,
        shopfrontId: shopfrontId,
        shopfrontName: shopName,
        staffNo: staffNo,
        password: password,
      ),
    );
  }
}
