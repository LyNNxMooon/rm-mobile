import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/global_widgets.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../home_page/presentation/BLoC/home_screen_bloc.dart';
import '../../../home_page/presentation/BLoC/home_screen_events.dart';

class StockRequestErrorDialog extends StatefulWidget {
  const StockRequestErrorDialog({super.key, required this.message});

  final String message;

  @override
  State<StockRequestErrorDialog> createState() =>
      _StockRequestErrorDialogState();
}

class _StockRequestErrorDialogState extends State<StockRequestErrorDialog> {
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      backgroundColor: kBgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: kErrorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: kErrorColor,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Oops!",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kThirdColor,
              ),
            ),
            const SizedBox(height: 12),

            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: kThirdColor.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              height: 40,
              child: CustomTextField(
                hintText: 'UserName',
                controller: _userNameController,
                leadingIcon: Icons.people,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              height: 40,
              child: CustomTextField(
                hintText: 'Password',
                controller: _pwdController,
                leadingIcon: Icons.password,
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context.read<ShopFrontConnectionBloc>().add(
                          ConnectToShopfrontEvent(
                            ip: AppGlobals.instance.currentHostIp ?? "",
                            shopName: AppGlobals.instance.shopfront ?? "",
                          ),
                        );

                        context.navigateBack();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: kPrimaryColor.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 1),
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
                        context.read<ShopFrontConnectionBloc>().add(
                          ConnectToShopfrontEvent(
                            ip: AppGlobals.instance.currentHostIp ?? "",
                            shopName: AppGlobals.instance.shopfront ?? "",
                            userName: _userNameController.text,
                            pwd: _pwdController.text,
                          ),
                        );
                        context.navigateBack();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: kSecondaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 1),
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
  }
}
