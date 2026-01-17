import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/global_var_utils.dart';

class StockLookupAppbar extends StatefulWidget {
  const StockLookupAppbar({super.key});

  @override
  State<StockLookupAppbar> createState() => _StockLookupAppbarState();
}

class _StockLookupAppbarState extends State<StockLookupAppbar> {
  @override
  Widget build(BuildContext context) {
    return  Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const SizedBox(width: 15),
            SizedBox(
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                  child: Image.asset(
                    "assets/images/appicon.png",
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Stock List", style: TextStyle(fontSize: 13)),
                const SizedBox(height: 5),
                Text(
                  (AppGlobals.instance.shopfront ?? "RM-Shopfront")
                      .split('\\')
                      .last
                      .length >
                      22
                      ? "${(AppGlobals.instance.shopfront ?? "RM-Shopfront").split('\\').last.substring(0, 22)}..."
                      : (AppGlobals.instance.shopfront ??
                      "RM-Shopfront")
                      .split('\\')
                      .last,
                  style: getSmartTitle(color: kPrimaryColor, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                context.navigateBack();
              },
              child: Icon(
                Icons.home_filled,
                color: kPrimaryColor,
                size: 23,
              ),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () {},
              child: Icon(
                CupertinoIcons.qrcode_viewfinder,
                color: kPrimaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 15),
          ],
        ),
      ],
    );
  }
}
