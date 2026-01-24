import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_bloc.dart'
    show StocktakeValidationBloc;
import 'package:rmstock_scanner/features/stocktake/presentation/BLoC/stocktake_states.dart';

import '../../../../constants/colors.dart';

class StocktakeValidationInfo extends StatelessWidget {
  const StocktakeValidationInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15.0, right: 15, bottom: 5),
      child: BlocBuilder<StocktakeValidationBloc, StocktakeValidationState>(
        builder: (context, state) {
          if (state is StocktakeValidationProgress) {
            return Container(
              margin: const EdgeInsets.only(top: 5, bottom: 2),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        state.message,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "${(state.percentage * 100).toStringAsFixed(0)}%",
                        style: TextStyle(
                          fontSize: 14,
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: state.percentage,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${state.current} / ${state.total} records",
                    style: TextStyle(fontSize: 12, color: kGreyColor),
                  ),
                ],
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
