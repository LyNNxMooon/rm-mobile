import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/entities/vos/customer_vo.dart';
import 'package:rmstock_scanner/local_db/local_db_dao.dart';

import '../../../../constants/colors.dart';
import '../../../../utils/dialog_size_utils.dart';
import '../BLoC/customer_lookup_bloc.dart';
import '../BLoC/customer_lookup_events.dart';
import '../BLoC/customer_lookup_states.dart';

class CustomerSyncInfoWidget extends StatelessWidget {
  const CustomerSyncInfoWidget({super.key});

  Future<void> _promptSendPendingCustomerUpdates(BuildContext context) async {
    final shopfront =
        (await LocalDbDAO.instance.getShopfrontName() ?? '').trim();
    if (shopfront.isEmpty) return;

    final pendingCount =
        await LocalDbDAO.instance.getPendingCustomerUpdatesCount(shopfront);
    if (pendingCount <= 0) return;

    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: dialogInsetPadding(dialogContext),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: kBgColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sync_problem,
                        color: kPrimaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Send pending customer updates?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: kThirdColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '$pendingCount customer updates are saved locally and not sent to RetailManager yet.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: kThirdColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: kPrimaryColor.withOpacity(0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Not now', style: TextStyle(color: kPrimaryColor)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: kSecondaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Send'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldSend != true) return;

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

    if (result is PendingCustomerUpdatesSent && result.hasConflicts) {
      await _showConflictDialog(context, shopfront);
    } else if (result is PendingCustomerUpdatesSent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      context.read<FetchCustomerBloc>().add(
        StartCustomerSyncEvent(ipAddress: ""),
      );
    } else if (result is PendingCustomerUpdatesError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }

    context.read<PendingCustomerUpdatesBloc>().add(
      LoadPendingCustomerUpdatesCountEvent(),
    );
  }

  Future<void> _showConflictDialog(
    BuildContext context,
    String shopfront,
  ) async {
    final conflicts = await LocalDbDAO.instance.getPendingCustomerUpdates(
      shopfront,
      action: 'create',
      conflictOnly: true,
    );

    if (conflicts.isEmpty || !context.mounted) return;

    final customers = <CustomerVO>[];
    for (final entry in conflicts) {
      final customer =
          await LocalDbDAO.instance.getCustomerById(entry.customerId, shopfront);
      if (customer != null) customers.add(customer);
    }

    final duplicate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: dialogInsetPadding(dialogContext),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: kBgColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: kErrorColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.report_gmailerrorred,
                        color: kErrorColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Customer ID already exists',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: kThirdColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Some customer IDs already exist in RetailManager. Do you want to duplicate them with new IDs?',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: kThirdColor.withOpacity(0.7),
                  ),
                ),
                if (customers.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kSecondaryColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kGreyColor.withOpacity(0.2)),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: customers.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        return Text(
                          '${customer.customerId} - ${customer.displayName}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: kThirdColor,
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: kErrorColor.withOpacity(0.35),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Do not duplicate'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kErrorColor,
                          foregroundColor: kSecondaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Duplicate'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted) return;

    context.read<PendingCustomerUpdatesBloc>().add(
      ResolveCustomerCreateConflictsEvent(duplicate: duplicate == true),
    );

    if (duplicate == true) {
      context.read<PendingCustomerUpdatesBloc>().add(
        SendPendingCustomerUpdatesEvent(),
      );
      await context
          .read<PendingCustomerUpdatesBloc>()
          .stream
          .firstWhere(
            (state) =>
                state is PendingCustomerUpdatesSent ||
                state is PendingCustomerUpdatesError,
          );
      if (!context.mounted) return;
      context.read<FetchCustomerBloc>().add(
        StartCustomerSyncEvent(ipAddress: ""),
      );
    }
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
