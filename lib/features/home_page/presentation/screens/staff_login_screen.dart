import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/global_widgets.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../utils/ios_done_bar.dart';
import '../../../../utils/responsive_utils.dart';
import '../BLoC/home_screen_bloc.dart';
import '../BLoC/home_screen_events.dart';
import '../BLoC/home_screen_states.dart';

class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final TextEditingController _staffNoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _staffNoFocusNode = FocusNode();

  int? _port;
  String _apiKey = "";
  String _shopfrontId = "";
  String _shopfrontName = "";

  @override
  void initState() {
    super.initState();
    context.read<StaffAuthBloc>().add(LoadConnectionInfoEvent());
  }

  @override
  void dispose() {
    _staffNoController.dispose();
    _passwordController.dispose();
    _staffNoFocusNode.dispose();
    super.dispose();
  }

  void _onSignIn() {
    final ip = (AppGlobals.instance.currentHostIp ?? "").trim();
    final staffNo = _staffNoController.text.trim();

    if (ip.isEmpty ||
        _port == null ||
        _apiKey.isEmpty ||
        _shopfrontId.isEmpty ||
        _shopfrontName.isEmpty) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.error(
          message: "Missing host/shopfront setup. Please reconnect shopfront.",
        ),
      );
      return;
    }

    if (staffNo.isEmpty) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.error(message: "Please enter staff ID."),
      );
      return;
    }
    context.read<StaffAuthBloc>().add(
      AuthenticateStaffEvent(
        ip: ip,
        port: _port!,
        apiKey: _apiKey,
        shopfrontId: _shopfrontId,
        shopfrontName: _shopfrontName,
        staffNo: staffNo,
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final media = MediaQuery.of(context);
    final bool isTablet = context.isTablet;
    final bool isLandscape = context.isLandscape;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    final double cardMaxWidth = isTablet
        ? (media.size.width * 0.58).clamp(420.0, 620.0)
        : media.size.width;
    final double logoHeight = isTablet ? 104 : 75;
    final double topGap = isTablet ? (isLandscape ? 26 : 42) : 55;
    final double inputHeight = (isTablet ? 44 : 40) * uiScale;
    final double buttonHeight = (isTablet ? 42 : 38) * uiScale;

    return BlocListener<StaffAuthBloc, StaffAuthStates>(
      listener: (context, state) {
        if (state is StaffAuthenticated) {
          Navigator.of(context).pop(true);
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
        if (state is StaffConnectionInfoLoaded) {
          setState(() {
            _port = state.port;
            _apiKey = state.apiKey;
            _shopfrontId = state.shopfrontId;
            _shopfrontName = state.shopfrontName;
          });
        }
        if (state is StaffConnectionInfoError) {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.error(message: state.message),
          );
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: colors.heroGradient),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: cardMaxWidth),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          width: double.infinity,
                          height: logoHeight,
                          child: Image.asset(
                            Theme.of(context).brightness == Brightness.dark
                                ? "assets/images/trademark_dark.png"
                                : "assets/images/trademark.png",
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: topGap),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: cardMaxWidth),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                            decoration: BoxDecoration(
                              color: colors.glassFill,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: colors.glassBorder,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.cardShadow,
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Sign-in to continue",
                                  style: getSmartTitle(
                                    color: isDark ? Colors.white : colors.onHero,
                                    fontSize: 21,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.08)
                                        : colors.surface.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white24
                                          : colors.divider,
                                    ),
                                  ),
                                  child: Text(
                                    (_shopfrontName.isEmpty
                                            ? AppGlobals.instance.shopfront
                                            : _shopfrontName) ??
                                        "Shopfront",
                                    style: TextStyle(
                                      color: isDark ? Colors.white : colors.onHero,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: inputHeight,
                                  child: CustomTextField(
                                    controller: _staffNoController,
                                    focusNode: _staffNoFocusNode,
                                    keyboardType: TextInputType.number,
                                    hintText: "Staff ID",
                                    leadingIcon: Icons.badge_outlined,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: inputHeight,
                                  child: CustomTextField(
                                    controller: _passwordController,
                                    hintText: "Password",
                                    leadingIcon: Icons.lock_outline,
                                    obscureText: true,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: buttonHeight,
                                  child: BlocBuilder<StaffAuthBloc, StaffAuthStates>(
                                    builder: (context, state) {
                                      final bool loading =
                                          state is StaffAuthenticating;
                                      return ElevatedButton(
                                        onPressed: loading ? null : _onSignIn,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: kPrimaryColor,
                                          foregroundColor: colors.onHero,
                                          disabledBackgroundColor:
                                              kPrimaryColor.withOpacity(0.7),
                                          disabledForegroundColor:
                                            (isDark ? Colors.white : colors.onHero)
                                              .withOpacity(0.8),
                                          minimumSize: Size(
                                            double.infinity,
                                            buttonHeight,
                                          ),
                                          padding: EdgeInsets.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          textStyle: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(9),
                                          ),
                                        ),
                                        child: loading
                                            ? CupertinoActivityIndicator(
                                                color: isDark ? Colors.white : colors.onHero,
                                              )
                                            : Center(
                                                child: Text(
                                                  "Sign In",
                                                  textScaler:
                                                      TextScaler.noScaling,
                                                  maxLines: 1,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? Colors.white
                                                        : colors.onHero,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      "App Version 1.0.0 (AAAPOS Pty Ltd)",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white70
                            : colors.onHero.withOpacity(0.68),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
                    ),
                  ),
                ),
                IosDoneBar(
                  focusNode: _staffNoFocusNode,
                  onDone: () {
                    _staffNoFocusNode.unfocus();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
