
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/global_var_utils.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../home_page/presentation/BLoC/home_screen_bloc.dart';
import '../../../home_page/presentation/BLoC/home_screen_events.dart';
import '../../../home_page/presentation/BLoC/home_screen_states.dart';

class StockLookupAppbar extends StatefulWidget {
  final bool showBackArrow;
  
  const StockLookupAppbar({super.key, this.showBackArrow = false});

  @override
  State<StockLookupAppbar> createState() => _StockLookupAppbarState();
}

class _StockLookupAppbarState extends State<StockLookupAppbar> {
  // Future<void> clearAllImageCache() async {
  //   final dir = await getTemporaryDirectory();

  //   final thumbRoot = Directory(p.join(dir.path, "thumb_cache"));
  //   final fullRoot = Directory(p.join(dir.path, "fullimg_cache"));

  //   if (await thumbRoot.exists()) {
  //     await thumbRoot.delete(recursive: true);
  //   }
  //   if (await fullRoot.exists()) {
  //     await fullRoot.delete(recursive: true);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = context.isTablet;
    final bool useDesktopNav = context.useDesktopNav;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
    
    // Desktop-specific smaller sizes
    final double iconBox = useDesktopNav ? 40 : ((isTablet ? 56 : 45) * uiScale);
    final double actionHeight = useDesktopNav ? 36 : ((isTablet ? 50 : 45) * uiScale);
    final double actionWidth = useDesktopNav ? 36 : ((isTablet ? 46 : 40) * uiScale);
    final double iconSize = useDesktopNav ? 18 : 24;
    final double titleFontSize = useDesktopNav ? 12 : 14;
    final double subtitleFontSize = useDesktopNav ? 14 : 16;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left Side: Icon + Texts
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
                      "assets/images/appicon.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Responsive Text Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Stock List",
                      style: TextStyle(
                        fontSize: titleFontSize,
                        color: isDark ? Colors.white70 : kThirdColor,
                      ),
                    ),
                    SizedBox(height: useDesktopNav ? 2 : 5),
                    Text(
                      (AppGlobals.instance.shopfront ?? "RM-Shopfront")
                          .split('\\')
                          .last,
                      style: getSmartTitle(color: kPrimaryColor, fontSize: subtitleFontSize),
                      maxLines: 1, // Prevent vertical overflow
                      overflow:
                          TextOverflow.ellipsis, // Handle long names gracefully
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Right Side: Buttons
        Row(
          children: [
            const SizedBox(width: 10), // Padding between text and buttons
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
                    widget.showBackArrow ? Icons.arrow_back_ios_new_rounded : Icons.home_filled,
                    color: kPrimaryColor,
                    size: iconSize,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            BlocBuilder<FetchStockBloc, FetchStockStates>(
              builder: (context, state) {
                if (state is FetchStockProgress) {
                  return Material(
                    color: isDark ? colors.surface : kSecondaryColor,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: actionHeight,
                      width: actionWidth,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white30
                              : Colors.grey[300]!,
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
                } else {
                  return Material(
                    color: isDark ? colors.surface : kSecondaryColor,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        context.read<FetchStockBloc>().add(
                          StartSyncEvent(ipAddress: ""),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: actionHeight,
                        width: actionWidth,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white30
                                : Colors.grey[300]!,
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
                }
              },
            ),
            const SizedBox(width: 15),
          ],
        ),
      ],
    );
  }
}
