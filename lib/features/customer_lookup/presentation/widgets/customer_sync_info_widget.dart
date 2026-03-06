import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../constants/colors.dart';
import '../BLoC/customer_lookup_bloc.dart';
import '../BLoC/customer_lookup_events.dart';
import '../BLoC/customer_lookup_states.dart';

class CustomerSyncInfoWidget extends StatelessWidget {
  const CustomerSyncInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: BlocConsumer<FetchCustomerBloc, FetchCustomerStates>(
        listener: (context, state) {
          if (state is FetchCustomerSuccess) {
            final customerState = context.read<CustomerListBloc>().state;

            if (customerState is CustomerListLoaded) {
              context.read<CustomerListBloc>().add(
                FetchFirstCustomerPageEvent(
                  query: customerState.currentQuery,
                  filterColumn: customerState.currentFilterCol,
                  sortColumn: customerState.currentSortCol,
                  filters: customerState.activeFilters,
                  shouldToggleSort: false,
                ),
              );
            } else {
              context.read<CustomerListBloc>().add(
                FetchFirstCustomerPageEvent(shouldToggleSort: false),
              );
            }

            context
                .read<CustomerFilterOptionsBloc>()
                .add(LoadCustomerFilterOptionsEvent());
          }
        },
        builder: (context, state) {
          if (state is FetchCustomerProgress) {
            final int total = state.totalCount == 0 ? 1 : state.totalCount;
            final double percent = (state.currentCount / total).clamp(0.0, 1.0);
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
                        '${(percent * 100).toStringAsFixed(0)}%',
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
                    value: percent,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${state.currentCount} / ${state.totalCount} records',
                    style: const TextStyle(fontSize: 12, color: kGreyColor),
                  ),
                ],
              ),
            );
          } else if (state is FetchCustomerFailure) {
            return Container(
              margin: const EdgeInsets.only(top: 5, bottom: 2),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: kErrorColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.errorMessage,
                      style: const TextStyle(color: kErrorColor, fontSize: 14),
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
