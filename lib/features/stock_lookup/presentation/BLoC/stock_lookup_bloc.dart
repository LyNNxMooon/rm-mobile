import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_events.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_states.dart';

import '../../../../utils/global_var_utils.dart';
import '../../domain/use_cases/get_filter_options.dart';
import '../../domain/use_cases/get_paginated_stock.dart';

class StockListBloc extends Bloc<StockListEvent, StockListState> {
  final GetPaginatedStock getPaginatedStock;

  StockListBloc({required this.getPaginatedStock}) : super(StockListInitial()) {
    //Initial Load / Filter Change / Search
    on<FetchFirstPageEvent>((event, emit) async {
      final prevState = state is StockListLoaded
          ? state as StockListLoaded
          : null;

      bool isAscending = true;

      //Toggle only if same column tapped again
      if (prevState != null && prevState.currentSortCol == event.sortColumn) {
        isAscending = !prevState.isAscending;
      }

      final criteria = event.filters ?? prevState?.activeFilters;

      emit(StockListLoading());

      try {
        final result = await getPaginatedStock.call(
          shopfront: AppGlobals.instance.shopfront ?? "",
          query: event.query,
          filterCol: event.filterColumn,
          sortCol: event.sortColumn,
          ascending: isAscending,
          page: 1,
          filters: criteria,
        );

        emit(
          StockListLoaded(
            stocks: result.items,
            totalCount: result.totalCount,
            hasReachedMax: result.items.length < 100,
            currentPage: 1,
            currentQuery: event.query,
            currentSortCol: event.sortColumn,
            currentFilterCol: event.filterColumn,
            isAscending: isAscending,
            activeFilters: criteria,
          ),
        );
      } catch (e) {
        emit(StockListError(e.toString()));
      }
    });

    // Load More (Infinite Scroll)
    on<LoadMoreEvent>((event, emit) async {
      if (state is StockListLoaded) {
        final curr = state as StockListLoaded;
        if (curr.hasReachedMax) return;

        try {
          final nextPage = curr.currentPage + 1;
          final result = await getPaginatedStock.call(
            shopfront: AppGlobals.instance.shopfront ?? "",
            query: curr.currentQuery,
            filterCol: curr.currentFilterCol,
            sortCol: curr.currentSortCol,
            ascending: curr.isAscending,
            page: nextPage,
            filters: curr.activeFilters,
          );

          emit(
            result.items.isEmpty
                ? curr.copyWith(hasReachedMax: true)
                : curr.copyWith(
                    stocks: List.of(curr.stocks)..addAll(result.items),
                    currentPage: nextPage,
                    hasReachedMax: result.items.length < 100,
                  ),
          );
        } catch (e) {
          emit(StockListError(e.toString()));
        }
      }
    });
  }
}

class FilterOptionsBloc extends Bloc<StockListEvent, FilterOptionsState> {
  final GetFilterOptions getFilterOptions;

  FilterOptionsBloc({required this.getFilterOptions})
    : super(FiltersInitial()) {
    on<LoadFilterOptionsEvent>(_onLoadFilterOptions);
  }

  Future<void> _onLoadFilterOptions(
    LoadFilterOptionsEvent event,
    Emitter<FilterOptionsState> emit,
  ) async {
    emit(FiltersLoading());
    try {
      final options = await getFilterOptions.call();

      emit(
        FiltersLoaded(
          departments: options['Departments'] ?? [],
          cat1: options['Cat1'] ?? [],
          cat2: options['Cat2'] ?? [],
          cat3: options['Cat3'] ?? [],
        ),
      );
    } catch (error) {
      emit(FiltersError(error.toString()));
    }
  }
}
