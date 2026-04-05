import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/entities/vos/network_server_vo.dart';
import 'package:rmstock_scanner/features/loading_splash/presentation/BLoC/loading_splash_bloc.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/modern_dialog_styles.dart';
import '../../../../utils/dialog_size_utils.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../utils/log_utils.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../customer_lookup/presentation/BLoC/customer_lookup_bloc.dart';
import '../../../customer_lookup/presentation/BLoC/customer_lookup_events.dart';
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
  int? _savedPort;
  String _savedApiKey = "";
  String _savedShopfrontId = "";
  
  // Pending connection info for Connect API call after auth
  String? _pendingShopfrontId;
  String? _pendingShopfrontName;
  String? _pendingApiKey;
  int? _pendingPort;

  @override
  void initState() {
    super.initState();
    context.read<StaffAuthBloc>().add(LoadConnectionInfoEvent());
  }

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
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final double maxDialogHeight = (MediaQuery.of(context).size.height * 0.78)
        .clamp(420.0, 780.0);
    final bool isTablet = context.isTablet;
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
              // Call Connect API to get salesCustom and taxCodes (for BOTH flows)
              // Use pending values stored during sign-in
              final apiKey = _pendingApiKey ?? widget.apiKey ?? _savedApiKey;
              final port = _pendingPort ?? widget.port ?? _savedPort;
              final shopfrontId = _pendingShopfrontId ?? _savedShopfrontId;
              final shopfrontName = _pendingShopfrontName ?? _expandedShop ?? '';
              
              logger.d('ShopfrontsDialog: StaffAuthenticated received');
              logger.d('  apiKey: ${apiKey.isNotEmpty ? "present" : "empty"}');
              logger.d('  port: $port');
              logger.d('  shopfrontId: $shopfrontId');
              logger.d('  shopfrontName: $shopfrontName');
              logger.d('  isPairedFlow: ${widget.isPairedFlow}');
              
              if (apiKey.isNotEmpty && port != null && shopfrontId.isNotEmpty) {
                logger.d('ShopfrontsDialog: Dispatching ConnectToShopfrontApiEvent');
                context.read<ShopFrontConnectionBloc>().add(
                  ConnectToShopfrontApiEvent(
                    ip: widget.pc.ipAddress,
                    port: port,
                    apiKey: apiKey,
                    shopfrontId: shopfrontId,
                    shopfrontName: shopfrontName,
                  ),
                );
              } else {
                logger.w('ShopfrontsDialog: Missing data for Connect API call');
              }
              
              if (widget.isPairedFlow) {
                context.read<FetchStockBloc>().add(
                  StartSyncEvent(ipAddress: ""),
                );
                context.read<FetchCustomerBloc>().add(
                  StartCustomerSyncEvent(ipAddress: ""),
                );

                showTopSnackBar(
                  Overlay.of(context),
                  CustomSnackBar.success(message: state.response.message),
                );

                context.navigateBack();
              }
              
              // Clear pending info
              _pendingShopfrontId = null;
              _pendingShopfrontName = null;
              _pendingApiKey = null;
              _pendingPort = null;
            }

            if (state is StaffConnectionInfoLoaded) {
              setState(() {
                _savedPort = state.port;
                _savedApiKey = state.apiKey;
                _savedShopfrontId = state.shopfrontId;
              });
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
        shape: ModernDialogStyles.dialogShape,
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: ModernDialogContainer(
          maxHeight: maxDialogHeight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ModernDialogHeader(
                title: "Choose Shopfront",
                icon: Icons.storefront_rounded,
                subtitle: "Select your store location",
              ),
              Flexible(
                child: BlocBuilder<ShopfrontBloc, ShopFrontStates>(
                  builder: (context, state) {
                    if (state is ShopsLoading) {
                      return const SingleChildScrollView(
                        child: ModernLoadingState(
                          message: "Loading Shopfronts",
                          subtitle: "Please wait...",
                        ),
                      );
                    }

                    if (state is ShopsError) {
                      logger.e(widget.previousPath);
                      if (widget.isPairedFlow) {
                        return SingleChildScrollView(
                          child: ModernErrorState(
                            message: state.message,
                            onRetry: () {
                              if (widget.port != null && widget.apiKey != null) {
                                context.read<ShopfrontBloc>().add(
                                  FetchShopsFromApi(
                                    ipAddress: widget.pc.ipAddress,
                                    port: widget.port!,
                                    apiKey: widget.apiKey!,
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      }

                      return _buildErrorWithCredentials(
                        context, state, colors, isDark, errorFieldHeight, errorButtonVerticalPadding);
                    }

                    if (state is ShopsLoaded) {
                      if (state.shops.shopfronts.isEmpty) {
                        return const SingleChildScrollView(
                          child: ModernEmptyState(
                            message: "No shopfronts found",
                            icon: Icons.storefront_outlined,
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        itemCount: state.shops.shopfronts.length,
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

  Widget _buildErrorWithCredentials(
    BuildContext context,
    ShopsError state,
    AppThemeColors colors,
    bool isDark,
    double errorFieldHeight,
    double errorButtonVerticalPadding,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kErrorColor.withOpacity(isDark ? 0.15 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: kErrorColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceMuted,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: errorFieldHeight,
              child: TextField(
                controller: _userNameController,
                style: TextStyle(
                  color: isDark ? Colors.white : colors.onSurface,
                  fontSize: 14,
                ),
                decoration: ModernDialogStyles.inputDecoration(
                  context,
                  hintText: 'Username',
                  prefixIcon: Icons.person_outline_rounded,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: errorFieldHeight,
              child: TextField(
                controller: _pwdController,
                obscureText: true,
                style: TextStyle(
                  color: isDark ? Colors.white : colors.onSurface,
                  fontSize: 14,
                ),
                decoration: ModernDialogStyles.inputDecoration(
                  context,
                  hintText: 'Password',
                  prefixIcon: Icons.lock_outline_rounded,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () {
                        // SMB LEGACY - FetchShops commented out
                        // context.read<ShopfrontBloc>().add(
                        //   FetchShops(
                        //     ipAddress: widget.pc.ipAddress,
                        //     path: widget.previousPath,
                        //   ),
                        // );
                        Navigator.of(context).pop();
                      },
                      style: ModernDialogStyles.outlinedButtonStyle(context),
                      child: const Text(
                        "Close",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        // SMB LEGACY - FetchShops commented out
                        // context.read<ShopfrontBloc>().add(
                        //   FetchShops(
                        //     ipAddress: widget.pc.ipAddress,
                        //     path: widget.previousPath,
                        //     userName: _userNameController.text,
                        //     pwd: _pwdController.text,
                        //   ),
                        // );
                        Navigator.of(context).pop();
                      },
                      style: ModernDialogStyles.primaryButtonStyle(context),
                      child: const Text(
                        "Close",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildShopTile(String shopName, BuildContext ctx) {
    final bool expanded = _expandedShop == shopName;
    final colors = ctx.appColors;
    final bool isDark = colors.isDark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            setState(() {
              _expandedShop = expanded ? null : shopName;
              _staffNoController.clear();
              _staffPwdController.clear();
            });
          },
          borderRadius: BorderRadius.circular(14),
          splashColor: kPrimaryColor.withOpacity(0.08),
          highlightColor: kPrimaryColor.withOpacity(0.04),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: expanded
                  ? kPrimaryColor.withOpacity(isDark ? 0.1 : 0.06)
                  : (isDark
                      ? Colors.white.withOpacity(0.04)
                      : colors.surfaceAlt.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: expanded
                    ? kPrimaryColor.withOpacity(0.3)
                    : (isDark
                        ? Colors.white.withOpacity(0.08)
                        : colors.divider.withOpacity(0.5)),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              kPrimaryColor.withOpacity(isDark ? 0.25 : 0.15),
                              kPrimaryColor.withOpacity(isDark ? 0.15 : 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.storefront_rounded,
                          color: kPrimaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          shopName.split(r'\\').last,
                          style: TextStyle(
                            color: isDark ? Colors.white : colors.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: kPrimaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (expanded)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: _buildStaffSignInSection(shopName, ctx),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaffSignInSection(String shopName, BuildContext ctx) {
    final bool loading = ctx.watch<StaffAuthBloc>().state is StaffAuthenticating;
    final colors = ctx.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = ctx.isTablet;
    final double textScale = MediaQuery.textScalerOf(ctx).scale(14) / 14;
    final double uiScale = (1.0 + ((textScale - 1.0) * 0.65)).clamp(1.0, 1.42);
    final double fieldHeight = isTablet ? (48 * uiScale).clamp(48.0, 58.0) : 46.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : colors.divider.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: fieldHeight,
            child: TextField(
              controller: _staffNoController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: isDark ? Colors.white : colors.onSurface,
                fontSize: 14,
              ),
              decoration: ModernDialogStyles.inputDecoration(
                ctx,
                hintText: 'Staff ID',
                prefixIcon: Icons.badge_outlined,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: fieldHeight,
            child: TextField(
              controller: _staffPwdController,
              obscureText: true,
              style: TextStyle(
                color: isDark ? Colors.white : colors.onSurface,
                fontSize: 14,
              ),
              decoration: ModernDialogStyles.inputDecoration(
                ctx,
                hintText: 'Password',
                prefixIcon: Icons.lock_outline_rounded,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: ModernDialogStyles.headerGradient,
                borderRadius: BorderRadius.circular(ModernDialogStyles.buttonRadius),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryColor.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: loading ? null : () => _onTapStaffSignIn(shopName, ctx),
                  borderRadius: BorderRadius.circular(ModernDialogStyles.buttonRadius),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: loading
                          ? [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ]
                          : [
                              Icon(
                                Icons.login_rounded,
                                color: Colors.white,
                                size: isTablet ? 22 : 20,
                              ),
                              SizedBox(width: isTablet ? 10 : 8),
                              Text(
                                'Sign In',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 16 : 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                    ),
                  ),
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

    final apiKey = widget.apiKey ?? _savedApiKey;
    final int? port = widget.port ?? _savedPort;
    final shopfrontId =
      AppGlobals.instance.pairedShopfrontIdsByName[shopName] ??
      _savedShopfrontId;

    if (apiKey.isEmpty || port == null || shopfrontId.isEmpty) {
      showTopSnackBar(
        Overlay.of(ctx),
        const CustomSnackBar.error(
          message: 'Unable to sign in. Missing required connection data.',
        ),
      );
      return;
    }

    // Store pending info for Connect API call after auth
    _pendingShopfrontId = shopfrontId;
    _pendingShopfrontName = shopName;
    _pendingApiKey = apiKey;
    _pendingPort = port;

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
