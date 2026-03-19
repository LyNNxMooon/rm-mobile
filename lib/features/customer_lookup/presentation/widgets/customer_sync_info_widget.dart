import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../constants/colors.dart';
import 'pending_customer_updates_tile.dart';
import '../BLoC/customer_lookup_bloc.dart';
import '../BLoC/customer_lookup_events.dart';
import '../BLoC/customer_lookup_states.dart';

class CustomerSyncInfoWidget extends StatelessWidget {
  const CustomerSyncInfoWidget({super.key});

  static bool _skipNextPrompt = false;

  Future<void> _promptSendPendingCustomerUpdates(BuildContext context) async {
    context.read<PendingCustomerUpdatesBloc>().add(
      LoadPendingCustomerUpdatesEvent(showDialog: false),
    );
    final state = await context
        .read<PendingCustomerUpdatesBloc>()
        .stream
        .firstWhere((state) => state is PendingCustomerUpdatesLoaded);
    if (state is! PendingCustomerUpdatesLoaded || !context.mounted) return;
    if (state.updates.isEmpty && state.creations.isEmpty) return;

    await showPendingCustomerQueueDialog(
      context: context,
      updates: state.updates,
      creations: state.creations,
      showSendButton: true,
      onSend: () async {
        _skipNextPrompt = true;
        await _sendPendingAll(context);
      },
    );
  }

  Future<void> _sendPendingUpdates(
    BuildContext context, {
    bool triggerSync = true,
  }) async {
    context.read<PendingCustomerUpdatesBloc>().add(
      SendPendingCustomerUpdatesEvent(),
    );

    final result = await context
        .read<PendingCustomerUpdatesBloc>()
        .stream
        .firstWhere(
          (state) =>
              state is PendingCustomerUpdatesSent ||
              state is PendingCustomerUpdatesError,
        );

    if (!context.mounted) return;

    if (result is PendingCustomerUpdatesSent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      if (triggerSync) {
        context.read<FetchCustomerBloc>().add(
          StartCustomerSyncEvent(ipAddress: ""),
        );
      }
    } else if (result is PendingCustomerUpdatesError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }

    context.read<PendingCustomerUpdatesBloc>().add(
      LoadPendingCustomerUpdatesCountEvent(),
    );
  }

  Future<void> _sendPendingCreations(
    BuildContext context, {
    bool triggerSync = true,
  }) async {
    context.read<PendingCustomerUpdatesBloc>().add(
      SendPendingCustomerCreationsEvent(),
    );

    final result = await context
        .read<PendingCustomerUpdatesBloc>()
        .stream
        .firstWhere(
          (state) =>
              state is PendingCustomerCreationsSent ||
              state is PendingCustomerCreationsError,
        );

    if (!context.mounted) return;

    if (result is PendingCustomerCreationsSent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      if (triggerSync) {
        context.read<FetchCustomerBloc>().add(
          StartCustomerSyncEvent(ipAddress: ""),
        );
      }
    } else if (result is PendingCustomerCreationsError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }

    context.read<PendingCustomerUpdatesBloc>().add(
      LoadPendingCustomerUpdatesCountEvent(),
    );
  }

  Future<void> _sendPendingAll(
    BuildContext context,
  ) async {
    await _sendPendingUpdates(
      context,
      triggerSync: false,
    );
    await _sendPendingCreations(
      context,
      triggerSync: false,
    );
    if (!context.mounted) return;
    context.read<FetchCustomerBloc>().add(
      StartCustomerSyncEvent(ipAddress: ""),
    );
  }

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
            context.read<PendingCustomerUpdatesBloc>().add(
              LoadPendingCustomerUpdatesCountEvent(),
            );
            if (_skipNextPrompt) {
              _skipNextPrompt = false;
              return;
            }
            _promptSendPendingCustomerUpdates(context);
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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: kThirdColor,
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
                    valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${state.currentCount} / ${state.totalCount} records',
                    style: TextStyle(
                      fontSize: 12,
                      color: kGreyColor,
                    ),
                  ),
                ],
              ),
            );
          } else if (state is FetchCustomerFailure) {
            return Container(
              margin: const EdgeInsets.only(top: 5, bottom: 2),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kErrorColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: kErrorColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.errorMessage,
                      style: TextStyle(
                        color: kErrorColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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