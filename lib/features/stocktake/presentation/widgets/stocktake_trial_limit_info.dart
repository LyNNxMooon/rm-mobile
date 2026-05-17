import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_bloc.dart';
import 'package:rmmobile/features/stocktake/presentation/BLoC/stocktake_states.dart';
import 'package:rmmobile/utils/responsive_utils.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';

class StocktakeTrialLimitInfo extends StatelessWidget {
  const StocktakeTrialLimitInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool useDesktopNav = context.useDesktopNav;
    final double horizontalPadding = useDesktopNav ? 12.0 : 15.0;
    final double borderRadius = useDesktopNav ? 8.0 : 12.0;
    final double iconSize = useDesktopNav ? 16.0 : 18.0;
    final double fontSize = useDesktopNav ? 12.0 : 13.0;
    final double padding = useDesktopNav ? 10.0 : 12.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: useDesktopNav ? 800 : double.infinity),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: BlocBuilder<StocktakeLimitBloc, StocktakeLimitStates>(
        builder: (context, state) {
          if (state is StocktakeLimitLoading) {
            return const SizedBox.shrink();
          }

          if (state is StocktakeLimitLoaded) {
            if (state.isUnlimited) {
              return const SizedBox.shrink();
            }

            final String summary =
                "Trial Limit: ${state.limit}   Used: ${state.used}   Remaining: ${state.remaining}";

            return Container(
              margin: EdgeInsets.only(top: useDesktopNav ? 3 : 4, bottom: useDesktopNav ? 3 : 4),
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: isDark
                  ? colors.surfaceAlt.withOpacity(0.85)
                  : kSecondaryColor,
                borderRadius: BorderRadius.circular(borderRadius),
                border: isDark
                  ? Border.all(color: Colors.white30, width: 1)
                  : null,
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? colors.cardShadow
                        : kThirdColor.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_clock, color: kPrimaryColor, size: iconSize),
                  SizedBox(width: useDesktopNav ? 6 : 8),
                  Expanded(
                    child: Text(
                      summary,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
        ),
      ),
    );
  }
}
