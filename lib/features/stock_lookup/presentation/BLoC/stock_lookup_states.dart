import 'package:rmstock_scanner/entities/vos/filter_criteria.dart';

import '../../../../entities/vos/stock_vo.dart';

abstract class StockListState {}

class StockListInitial extends StockListState {}

class StockListLoading extends StockListState {}

class StockListLoaded extends StockListState {
  final List<StockVO> stocks;
  final int totalCount;
  final bool hasReachedMax;

  // Keep track of current filter state for "LoadMore" to use
  final int currentPage;
  final String currentQuery;
  final String currentSortCol;
  final String currentFilterCol;
  final bool isAscending;
  final FilterCriteria? activeFilters;

  StockListLoaded({
    required this.stocks,
    required this.totalCount,
    this.hasReachedMax = false,
    required this.currentPage,
    required this.currentQuery,
    required this.currentSortCol,
    required this.currentFilterCol,
    required this.isAscending,
    this.activeFilters,
  });

  StockListLoaded copyWith({
    List<StockVO>? stocks,
    int? totalCount,
    bool? hasReachedMax,
    int? currentPage,
    String? currentQuery,
    String? currentSortCol,
    String? currentFilterCol,
    bool? isAscending,
    FilterCriteria? activeFilters,
  }) {
    return StockListLoaded(
      stocks: stocks ?? this.stocks,
      totalCount: totalCount ?? this.totalCount,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      currentQuery: currentQuery ?? this.currentQuery,
      currentSortCol: currentSortCol ?? this.currentSortCol,
      currentFilterCol: currentFilterCol ?? this.currentFilterCol,
      isAscending: isAscending ?? this.isAscending,
      activeFilters: activeFilters ?? this.activeFilters,
    );
  }
}

class StockListError extends StockListState {
  final String message;
  StockListError(this.message);
}

//Filter options states
abstract class FilterOptionsState {}

class FiltersInitial extends FilterOptionsState {}

class FiltersLoading extends FilterOptionsState {}

class FiltersError extends FilterOptionsState {
  final String message;
  FiltersError(this.message);
}

class FiltersLoaded extends FilterOptionsState {
  final List<String> departments;
  final List<String> cat1;
  final List<String> cat2;
  final List<String> cat3;

  FiltersLoaded({
    required this.departments,
    required this.cat1,
    required this.cat2,
    required this.cat3,
  });
}

//Fetching thumbnail states
abstract class ThumbnailState {}

class ThumbnailInitial extends ThumbnailState {}

class ThumbnailLoaded extends ThumbnailState {
  final Map<num, String> thumbPaths;
  final Set<num> loading;

  ThumbnailLoaded({required this.thumbPaths, required this.loading});

  ThumbnailLoaded copyWith({Map<num, String>? thumbPaths, Set<num>? loading}) {
    return ThumbnailLoaded(
      thumbPaths: thumbPaths ?? this.thumbPaths,
      loading: loading ?? this.loading,
    );
  }
}

abstract class FullImageState {}

class FullImageLoaded extends FullImageState {
  final Map<num, String> imagePaths; 
  final Set<num> loading;

  FullImageLoaded({required this.imagePaths, required this.loading});

  FullImageLoaded copyWith({
    Map<num, String>? imagePaths,
    Set<num>? loading,
  }) {
    return FullImageLoaded(
      imagePaths: imagePaths ?? this.imagePaths,
      loading: loading ?? this.loading,
    );
  }
}

