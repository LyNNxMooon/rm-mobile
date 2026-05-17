import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_bloc.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_events.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_states.dart';

import 'package:rmmobile/utils/navigation_extension.dart';
import 'package:rmmobile/utils/responsive_utils.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../constants/txt_styles.dart';

import '../../../../utils/global_var_utils.dart';

class StocktakeListAppBar extends StatefulWidget {
  const StocktakeListAppBar({super.key});

  @override
  State<StocktakeListAppBar> createState() => _StocktakeListAppBarState();
}

class _StocktakeListAppBarState extends State<StocktakeListAppBar> {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool useDesktopNav = context.useDesktopNav;

    // Desktop sizing
    final double topPadding = useDesktopNav ? 10.0 : 15.0;
    final double backIconSize = useDesktopNav ? 16.0 : 18.0;
    final double titleFontSize = useDesktopNav ? 14.0 : 16.0;
    final double subtitleFontSize = useDesktopNav ? 12.0 : 14.0;
    final double paginationFontSize = useDesktopNav ? 12.0 : 14.0;
    final double arrowSize = useDesktopNav ? 12.0 : 14.0;

    return Column(
      children: [
        SizedBox(height: topPadding),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: useDesktopNav ? 3 : 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side (Back + Titles)
              Expanded(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.navigateBack(),
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: isDark ? Colors.white : kPrimaryColor,
                        size: backIconSize,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Responsive Shop Name
                          Text(
                            (AppGlobals.instance.shopfront ?? "RM-Shopfront")
                                .split('\\')
                                .last,
                            style: getSmartTitle(
                              color: isDark ? Colors.white : kThirdColor,
                              fontSize: titleFontSize,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "Stocktake List",
                            style: TextStyle(
                              fontSize: subtitleFontSize,
                              color: isDark ? Colors.white70 : kGreyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Right side (Controls)
              // Right side (Controls)
              BlocBuilder<FetchingStocktakeListBloc, StocktakeListStates>(
                builder: (context, state) {
                  int start = 0, end = 0, total = 0;
                  bool hasPrev = false, hasNext = false;

                  if (state is StocktakeListLoaded) {
                    start = state.start;
                    end = state.end;
                    total = state.totalCount;
                    hasPrev = state.hasPrev;
                    hasNext = state.hasNext;
                  }

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "$start-$end of ${total.toString()}",
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontSize: paginationFontSize,
                        ),
                      ),
                      SizedBox(width: useDesktopNav ? 8 : 10),

                      InkWell(
                        onTap: hasPrev
                            ? () => context
                                  .read<FetchingStocktakeListBloc>()
                                  .add(PrevStocktakePageEvent())
                            : null,
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          size: arrowSize,
                          color: hasPrev
                              ? kPrimaryColor
                              : (isDark ? colors.onSurfaceMuted : kGreyColor),
                        ),
                      ),

                      SizedBox(width: useDesktopNav ? 12 : 15),

                      InkWell(
                        onTap: hasNext
                            ? () => context
                                  .read<FetchingStocktakeListBloc>()
                                  .add(NextStocktakePageEvent())
                            : null,
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: arrowSize,
                          color: hasNext
                              ? kPrimaryColor
                              : (isDark ? colors.onSurfaceMuted : kGreyColor),
                        ),
                      ),

                      SizedBox(width: useDesktopNav ? 8 : 10),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(height: useDesktopNav ? 3 : 5),
        Divider(
          indent: useDesktopNav ? 12 : 15,
          endIndent: useDesktopNav ? 12 : 15,
          thickness: 0.5,
          color: isDark ? Colors.white : kGreyColor,
        ),
      ],
    );
  }
}
