import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_lookup_bloc.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_lookup_events.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_lookup_states.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/home_screen_bloc.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/home_screen_events.dart';
import 'package:rmmobile/features/home_page/presentation/BLoC/home_screen_states.dart';

Future<void> runSequentialStockThenCustomerSync(
  BuildContext context, {
  String ipAddress = "",
}) async {
  final stockBloc = context.read<FetchStockBloc>();
  final customerBloc = context.read<FetchCustomerBloc>();

  if (stockBloc.state is FetchStockProgress) {
    await stockBloc.stream.firstWhere(
      (state) => state is! FetchStockProgress,
    );
  } else {
    stockBloc.add(StartSyncEvent(ipAddress: ipAddress));
    await stockBloc.stream.firstWhere(
      (state) =>
          state is FetchStockProgress ||
          state is FetchStockSuccess ||
          state is FetchStockError,
    );
    await stockBloc.stream.firstWhere(
      (state) => state is! FetchStockProgress,
    );
  }

  if (customerBloc.state is FetchCustomerProgress) return;

  customerBloc.add(StartCustomerSyncEvent(ipAddress: ipAddress));
}
