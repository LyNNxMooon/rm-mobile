import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../entities/response/stock_activity_response.dart';
import '../../domain/use_cases/fetch_stock_activity.dart';

abstract class StockActivityEvent {}

class FetchStockActivityEvent extends StockActivityEvent {
  final int stockId;

  FetchStockActivityEvent({required this.stockId});
}

abstract class StockActivityState {}

class StockActivityInitial extends StockActivityState {}

class StockActivityLoading extends StockActivityState {}

class StockActivityLoaded extends StockActivityState {
  final List<StockActivityItem> activities;
  StockActivityLoaded(this.activities);
}

class StockActivityError extends StockActivityState {
  final String message;
  StockActivityError(this.message);
}

class StockActivityBloc extends Bloc<StockActivityEvent, StockActivityState> {
  final FetchStockActivity fetchStockActivity;

  StockActivityBloc({required this.fetchStockActivity})
      : super(StockActivityInitial()) {
    on<FetchStockActivityEvent>(_onFetch);
  }

  Future<void> _onFetch(
    FetchStockActivityEvent event,
    Emitter<StockActivityState> emit,
  ) async {
    emit(StockActivityLoading());
    try {
      final response = await fetchStockActivity(stockId: event.stockId);
      emit(StockActivityLoaded(response.activities ?? const []));
    } catch (e) {
      emit(StockActivityError(e.toString()));
    }
  }
}
