import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/global_var_utils.dart';
import '../BLoC/customer_lookup_bloc.dart';
import '../BLoC/customer_lookup_events.dart';
import '../BLoC/customer_lookup_states.dart';

import '../../../../utils/responsive_utils.dart';

class CustomerLookupAppbar extends StatelessWidget {
  final bool showBackArrow;
  
  const CustomerLookupAppbar({super.key, this.showBackArrow = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final bool useDesktopNav = context.useDesktopNav;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    final double iconBox = useDesktopNav ? 40 : (isTablet ? 56 : 45) * uiScale;
    final double actionHeight = useDesktopNav ? 36 : (isTablet ? 50 : 45) * uiScale;
    final double actionWidth = useDesktopNav ? 36 : (isTablet ? 46 : 40) * uiScale;
    final double titleFontSize = useDesktopNav ? 12 : 14;
    final double shopNameFontSize = useDesktopNav ? 14 : 16;
    final double iconSize = useDesktopNav ? 20 : 24;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              const SizedBox(width: 15),
              SizedBox(
                child: Container(
                  height: iconBox,
                  width: iconBox,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/appicon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer List',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        color: isDark ? Colors.white70 : kThirdColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      (AppGlobals.instance.shopfront ?? 'RM-Shopfront')
                          .split('\\')
                          .last,
                      style: getSmartTitle(color: kPrimaryColor, fontSize: shopNameFontSize),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            const SizedBox(width: 10),
            Material(
              color: isDark ? colors.surface : kSecondaryColor,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  context.navigateBack();
                },
                child: Container(
                  height: actionHeight,
                  width: actionWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kPrimaryColor.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    showBackArrow ? Icons.arrow_back_ios_new_rounded : Icons.home_filled,
                    color: kPrimaryColor,
                    size: iconSize,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            BlocBuilder<FetchCustomerBloc, FetchCustomerStates>(
              builder: (context, state) {
                if (state is FetchCustomerProgress) {
                  return Material(
                    color: isDark ? colors.surface : kSecondaryColor,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: actionHeight,
                      width: actionWidth,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white30 : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.sync,
                        color: isDark ? Colors.white70 : Colors.grey,
                        size: iconSize,
                      ),
                    ),
                  );
                }

                return Material(
                  color: isDark ? colors.surface : kSecondaryColor,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      context.read<FetchCustomerBloc>().add(
                          StartCustomerSyncEvent(ipAddress: ""),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: actionHeight,
                      width: actionWidth,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white30 : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.sync,
                        color: isDark ? Colors.white : Colors.blueGrey[800],
                        size: iconSize,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 15),
          ],
        ),
      ],
    );
  }
}
