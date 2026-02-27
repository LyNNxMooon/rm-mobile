import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/global_widgets.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/global_var_utils.dart';
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

  int? _port;
  String _apiKey = "";
  String _shopfrontId = "";
  String _shopfrontName = "";

  @override
  void initState() {
    super.initState();
    _loadConnectionData();
  }

  Future<void> _loadConnectionData() async {
    final String? portRaw = await LocalDbDAO.instance.getHostPort();
    final String? apiKey = await LocalDbDAO.instance.getApiKey();
    final String? shopfrontId = await LocalDbDAO.instance.getShopfrontId();
    final String? shopfrontName = await LocalDbDAO.instance.getShopfrontName();

    if (!mounted) return;
    setState(() {
      _port = int.tryParse((portRaw ?? "").trim());
      _apiKey = (apiKey ?? "").trim();
      _shopfrontId = (shopfrontId ?? "").trim();
      _shopfrontName = (shopfrontName ?? "").trim();
    });
  }

  @override
  void dispose() {
    _staffNoController.dispose();
    _passwordController.dispose();
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
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: kGColor),
          child: SafeArea(
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        width: double.infinity,
                        // Slightly dynamic height for the logo container
                        height: 75,
                        child: Image.asset(
                          "assets/images/trademark.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 55),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                          decoration: BoxDecoration(
                            color: kSecondaryColor.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: kSecondaryColor.withOpacity(0.28),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: kThirdColor.withOpacity(0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Staff Sign In",
                                style: getSmartTitle(
                                  color: kSecondaryColor,
                                  fontSize: 21,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Authenticate to continue to stock operations",
                                style: TextStyle(
                                  color: kSecondaryColor.withOpacity(0.8),
                                  fontSize: 12,
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
                                  color: kSecondaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: kSecondaryColor.withOpacity(0.25),
                                  ),
                                ),
                                child: Text(
                                  (_shopfrontName.isEmpty
                                          ? AppGlobals.instance.shopfront
                                          : _shopfrontName) ??
                                      "Shopfront",
                                  style: const TextStyle(
                                    color: kSecondaryColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 40,
                                child: CustomTextField(
                                  controller: _staffNoController,
                                  keyboardType: TextInputType.number,
                                  hintText: "Staff ID",
                                  leadingIcon: Icons.badge_outlined,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 40,
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
                                height: 38,
                                child:
                                    BlocBuilder<StaffAuthBloc, StaffAuthStates>(
                                      builder: (context, state) {
                                        final bool loading =
                                            state is StaffAuthenticating;
                                        return ElevatedButton(
                                          onPressed: loading ? null : _onSignIn,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: kPrimaryColor,
                                            foregroundColor: kSecondaryColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(9),
                                            ),
                                          ),
                                          child: loading
                                              ? const CupertinoActivityIndicator(
                                                  color: kSecondaryColor,
                                                )
                                              : const Text(
                                                  "Sign In",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
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
                    const SizedBox(height: 26),
                    Text(
                      "App Version 1.0.0 (AAAPOS Pty Ltd)",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kSecondaryColor.withOpacity(0.68),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
