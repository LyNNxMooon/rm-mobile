import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_bloc.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_events.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_states.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/widgets/stocktake_validation_info.dart';

import 'package:rmstock_scanner/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';
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
    return Column(
      children: [
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5), // Added padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side (Back + Titles)
              Expanded(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.navigateBack(),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: kPrimaryColor,
                        size: 18,
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
                              color: kThirdColor,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            "Stocktake List",
                            style: TextStyle(fontSize: 14, color: kGreyColor),
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
                        style: const TextStyle(
                          color: kPrimaryColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 10),

                      InkWell(
                        onTap: hasPrev
                            ? () => context
                                  .read<FetchingStocktakeListBloc>()
                                  .add(PrevStocktakePageEvent())
                            : null,
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          size: 14,
                          color: hasPrev ? kPrimaryColor : kGreyColor,
                        ),
                      ),

                      const SizedBox(width: 15),

                      InkWell(
                        onTap: hasNext
                            ? () => context
                                  .read<FetchingStocktakeListBloc>()
                                  .add(NextStocktakePageEvent())
                            : null,
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: hasNext ? kPrimaryColor : kGreyColor,
                        ),
                      ),

                      const SizedBox(width: 10),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        const Divider(
          indent: 15,
          endIndent: 15,
          thickness: 0.5,
          color: kGreyColor,
        ),
        StocktakeValidationInfo(),
      ],
    );
  }
}
