import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_bloc.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_states.dart';

import '../../../../constants/colors.dart';

class StocktakeTrialLimitInfo extends StatelessWidget {
  const StocktakeTrialLimitInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
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
              margin: const EdgeInsets.only(top: 4, bottom: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kSecondaryColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: kThirdColor.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock, color: kPrimaryColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      summary,
                      style: const TextStyle(
                        fontSize: 13,
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
    );
  }
}
