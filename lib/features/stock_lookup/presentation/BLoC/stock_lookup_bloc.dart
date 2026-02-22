import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/features/stock_lookup/domain/use_cases/fetch_full_image.dart';
import 'package:rmstock_scanner/features/stock_lookup/domain/use_cases/fetch_thumbnail.dart';
import 'package:rmstock_scanner/features/stock_lookup/domain/use_cases/upload_stock_image.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_events.dart';
import 'package:rmstock_scanner/features/stock_lookup/presentation/BLoC/stock_lookup_states.dart';

import '../../../../utils/global_var_utils.dart';
import '../../domain/use_cases/get_filter_options.dart';
import '../../domain/use_cases/get_paginated_stock.dart';
import '../../domain/use_cases/update_single_stock.dart';

class StockListBloc extends Bloc<StockListEvent, StockListState> {
  final GetPaginatedStock getPaginatedStock;

  StockListBloc({required this.getPaginatedStock}) : super(StockListInitial()) {
    //Initial Load / Filter Change / Search
    on<FetchFirstPageEvent>((event, emit) async {
      final prevState = state is StockListLoaded
          ? state as StockListLoaded
          : null;

      bool isAscending = prevState?.isAscending ?? true;

      // Toggle sort direction only on explicit chip tap of the same column.
      if (event.shouldToggleSort &&
          prevState != null &&
          prevState.currentSortCol == event.sortColumn) {
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

//For thumbnail
class ThumbnailBloc extends Bloc<StockListEvent, ThumbnailState> {
  final FetchThumbnail fetchThumbnail;

  final Map<dynamic, int> _reqVer = {};

  ThumbnailBloc({required this.fetchThumbnail})
    : super(ThumbnailLoaded(thumbPaths: {}, loading: {}, rev: {})) {
    on<RequestThumbnailEvent>(_onRequest);
  }

  Future<void> _onRequest(
    RequestThumbnailEvent event,
    Emitter<ThumbnailState> emit,
  ) async {
    final current = state is ThumbnailLoaded
        ? state as ThumbnailLoaded
        : ThumbnailLoaded(thumbPaths: {}, loading: {}, rev: {});

    if (event.pictureFileName.isEmpty) return;

    // bump request version for this stockId
    final ver = (_reqVer[event.stockId] ?? 0) + 1;
    _reqVer[event.stockId] = ver;

    final newLoading = {...current.loading, event.stockId};
    final clearedPaths = {...current.thumbPaths};

    if (event.forceRefresh) {
      clearedPaths.remove(event.stockId);
    } else {
      if (clearedPaths.containsKey(event.stockId)) {
        return;
      }
    }

    emit(current.copyWith(thumbPaths: clearedPaths, loading: newLoading));

    try {
      final path = await fetchThumbnail(
        pictureFileName: event.pictureFileName,
        forceRefresh: event.forceRefresh,
      );

      // if a newer request started, ignore this stale result
      if (_reqVer[event.stockId] != ver) return;

      final updatedPaths = {...clearedPaths};
      if (path != null && path.isNotEmpty) {
        if (event.forceRefresh) {
          await FileImage(File(path)).evict();
          PaintingBinding.instance.imageCache.clearLiveImages();
        }
        updatedPaths[event.stockId] = path;
      }

      final loadingDone = {...newLoading}..remove(event.stockId);

      // bump a UI revision counter so Image widget can be forced to rebuild
      final newRev = {...current.rev};
      newRev[event.stockId] = (newRev[event.stockId] ?? 0) + 1;

      emit(
        current.copyWith(
          thumbPaths: updatedPaths,
          loading: loadingDone,
          rev: newRev,
        ),
      );
    } catch (_) {
      if (_reqVer[event.stockId] != ver) return;
      final loadingDone = {...newLoading}..remove(event.stockId);
      emit(current.copyWith(thumbPaths: clearedPaths, loading: loadingDone));
    }
  }
}

class FullImageBloc extends Bloc<StockListEvent, FullImageState> {
  final FetchFullImage fetchFullImage;

  // per-stock request version
  final Map<dynamic, int> _reqVer = {};

  FullImageBloc({required this.fetchFullImage})
    : super(FullImageLoaded(imagePaths: {}, loading: {}, rev: {})) {
    on<RequestFullImageEvent>(_onRequest);
  }

  Future<void> _onRequest(
    RequestFullImageEvent event,
    Emitter<FullImageState> emit,
  ) async {
    final current = state is FullImageLoaded
        ? state as FullImageLoaded
        : FullImageLoaded(imagePaths: {}, loading: {}, rev: {});

    if (event.pictureFileName.isEmpty) return;

    final ver = (_reqVer[event.stockId] ?? 0) + 1;
    _reqVer[event.stockId] = ver;

    final newLoading = {...current.loading, event.stockId};
    final cleared = {...current.imagePaths};

    if (event.forceRefresh) {
      cleared.remove(event.stockId);
    } else {
      if (cleared.containsKey(event.stockId)) {
        // already have it and no refresh requested
        return;
      }
    }

    emit(current.copyWith(imagePaths: cleared, loading: newLoading));

    try {
      final path = await fetchFullImage(
        pictureFileName: event.pictureFileName,
        forceRefresh: event.forceRefresh,
      );

      // if a newer request started, ignore this stale result
      if (_reqVer[event.stockId] != ver) return;

      final updated = {...cleared};
      if (path != null && path.isNotEmpty) {
        if (event.forceRefresh) {
          await FileImage(File(path)).evict();
          PaintingBinding.instance.imageCache.clearLiveImages();
        }

        updated[event.stockId] = path;
      }

      final loadingDone = {...newLoading}..remove(event.stockId);

      final newRev = {...current.rev};
      newRev[event.stockId] = (newRev[event.stockId] ?? 0) + 1;
      emit(
        current.copyWith(
          imagePaths: updated,
          loading: loadingDone,
          rev: newRev,
        ),
      );
    } catch (_) {
      if (_reqVer[event.stockId] != ver) return;
      final loadingDone = {...newLoading}..remove(event.stockId);
      emit(current.copyWith(imagePaths: cleared, loading: loadingDone));
    }
  }
}

class StockImageUploadBloc
    extends Bloc<StockImageUploadEvent, StockImageUploadState> {
  final UploadStockImageUseCase uploadUseCase;

  StockImageUploadBloc({required this.uploadUseCase})
    : super(StockImageUploadInitial()) {
    on<UploadStockImageEvent>(_onUpload);
  }

  Future<void> _onUpload(
    UploadStockImageEvent event,
    Emitter<StockImageUploadState> emit,
  ) async {
    emit(StockImageUploading());
    try {
      final response = await uploadUseCase(
        stockId: event.stockId,
        imagePath: event.imagePath,
      );
      if (response.success) {
        emit(StockImageUploaded(response.message));
      } else {
        emit(
          StockImageUploadError("Failed to upload image: ${response.message}"),
        );
      }
    } catch (e) {
      emit(StockImageUploadError(e.toString()));
    }
  }
}

//Stock update
class StockUpdateBloc extends Bloc<StockUpdateEvent, StockUpdateState> {
  final UpdateSingleStock updateSingleStock;

  StockUpdateBloc({required this.updateSingleStock})
    : super(StockUpdateInitial()) {
    on<SubmitStockUpdateEvent>(_onSubmit);
  }

  Future<void> _onSubmit(
    SubmitStockUpdateEvent event,
    Emitter<StockUpdateState> emit,
  ) async {
    emit(StockUpdateLoading());
    try {
      final response = await updateSingleStock(
        stockId: event.stockId,
        description: event.description,
        sell: event.sell,
      );
      if (response.success) {
        emit(StockUpdateSuccess(response.message));
      } else {
        emit(StockUpdateError("Failed to update stock: ${response.message}"));
      }
    } catch (error) {
      emit(StockUpdateError("Failed to send update: $error"));
    }
  }
}
