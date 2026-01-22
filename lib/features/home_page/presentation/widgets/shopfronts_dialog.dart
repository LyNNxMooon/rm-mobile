
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/entities/vos/network_computer_vo.dart';
import 'package:rmstock_scanner/features/loading_splash/presentation/BLoC/loading_splash_bloc.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/global_widgets.dart';
import '../../../../constants/txt_styles.dart';
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
  });

  final NetworkComputerVO pc;
  final String previousPath;

  @override
  State<ShopfrontsDialog> createState() => _ShopfrontsDialogState();
}

class _ShopfrontsDialogState extends State<ShopfrontsDialog> {
  final _userNameController = TextEditingController();
  final _pwdController = TextEditingController();

  @override
  void dispose() {
    if (!mounted) {
      _userNameController.dispose();
      _pwdController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 10,
      backgroundColor: kBgColor,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: kGColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront_rounded, color: kSecondaryColor),
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
                  } else if (state is ShopsError) {
                    logger.e(widget.previousPath);
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
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              height: 40,
                              child: CustomTextField(
                                hintText: 'UserName',
                                controller: _userNameController,
                                leadingIcon: Icons.people,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              height: 40,
                              child: CustomTextField(
                                hintText: 'Password',
                                controller: _pwdController,
                                leadingIcon: Icons.password,
                              ),
                            ),
                            const SizedBox(height: 25),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Row(
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
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 1,
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
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 1,
                                        ),
                                      ),
                                      child: Text(
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
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (state is ShopsLoaded) {
                    if (state.shops.shopfronts.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(30),
                        child: Text("No shopfronts found."),
                      );
                    }

                    if (state.shops.shopfronts.length == 1) {
                      context.read<ShopFrontConnectionBloc>().add(
                        ConnectToShopfrontEvent(
                          ip: widget.pc.ipAddress,
                          shopName: state.shops.shopfronts[0],
                        ),
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
            BlocListener<ShopFrontConnectionBloc, ShopfrontConnectionStates>(
              listenWhen: (previous, current) =>
                  previous is! ConnectedToShopfront &&
                  current is ConnectedToShopfront,
              listener: (context, state) {
                if (state is ConnectedToShopfront) {
                  context.read<NetworkSavedPathValidationBloc>().add(
                    ConnectionCheckingEvent(
                      AppGlobals.instance.currentPath ?? "",
                    ),
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
              child: const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopTile(String shopName, BuildContext ctx) {
    return InkWell(
      onTap: () {
        ctx.read<ShopFrontConnectionBloc>().add(
          ConnectToShopfrontEvent(ip: widget.pc.ipAddress, shopName: shopName),
        );
      },
      splashColor: kPrimaryColor.withOpacity(0.1),
      highlightColor: kPrimaryColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                shopName.split(r'\').last,
                style: const TextStyle(color: kThirdColor),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: kGreyColor),
          ],
        ),
      ),
    );
  }
}
