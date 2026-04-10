import 'package:rmmobile/entities/vos/filter_criteria.dart';
import 'package:rmmobile/entities/vos/search_mode.dart';

import '../../../../entities/vos/stock_vo.dart';
import '../../../../entities/vos/pending_stock_update_vo.dart';

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
  final SearchMode searchMode;
  final Map<int, String> matchedFields; // stockId -> matched column

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
    this.searchMode = SearchMode.partial,
    Map<int, String>? matchedFields,
  }) : matchedFields = matchedFields ?? {};

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
    SearchMode? searchMode,
    Map<int, String>? matchedFields,
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
      searchMode: searchMode ?? this.searchMode,
      matchedFields: matchedFields ?? this.matchedFields,
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
  final Map<dynamic, String> thumbPaths;
  final Set<dynamic> loading;
  final Map<dynamic, int> rev;

  ThumbnailLoaded({
    required this.thumbPaths,
    required this.loading,
    required this.rev,
  });

  ThumbnailLoaded copyWith({
    Map<dynamic, String>? thumbPaths,
    Set<dynamic>? loading,
    Map<dynamic, int>? rev,
  }) {
    return ThumbnailLoaded(
      thumbPaths: thumbPaths ?? this.thumbPaths,
      loading: loading ?? this.loading,
      rev: rev ?? this.rev,
    );
  }
}

abstract class FullImageState {}

class FullImageLoaded extends FullImageState {
  final Map<num, String> imagePaths;
  final Set<num> loading;
  final Map<dynamic, int> rev;

  FullImageLoaded({
    required this.imagePaths,
    required this.loading,
    required this.rev,
  });

  FullImageLoaded copyWith({
    Map<num, String>? imagePaths,
    Set<num>? loading,
    Map<dynamic, int>? rev,
  }) {
    return FullImageLoaded(
      imagePaths: imagePaths ?? this.imagePaths,
      loading: loading ?? this.loading,
      rev: rev ?? this.rev,
    );
  }
}

abstract class StockImageUploadState {}

class StockImageUploadInitial extends StockImageUploadState {}

class StockImageUploading extends StockImageUploadState {}

class StockImageUploaded extends StockImageUploadState {
  final String message;
  StockImageUploaded(this.message);
}

class StockImageUploadError extends StockImageUploadState {
  final String message;
  StockImageUploadError(this.message);
}

//Stock update
abstract class StockUpdateState {}

class StockUpdateInitial extends StockUpdateState {}

class StockUpdateLoading extends StockUpdateState {}

class StockUpdateSuccess extends StockUpdateState {
  final String message;
  StockUpdateSuccess(this.message);
}

class StockUpdateError extends StockUpdateState {
  final String message;
  StockUpdateError(this.message);
}

// Pending stock updates
abstract class PendingStockUpdatesState {}

class PendingStockUpdatesInitial extends PendingStockUpdatesState {}

class PendingStockUpdatesLoading extends PendingStockUpdatesState {}

class PendingStockUpdatesCountLoaded extends PendingStockUpdatesState {
  final int count;
  PendingStockUpdatesCountLoaded(this.count);
}

class PendingStockUpdatesLoaded extends PendingStockUpdatesState {
  final List<PendingStockUpdateVO> updates;
  final bool showDialog;

  PendingStockUpdatesLoaded(this.updates, {this.showDialog = true});
}

class PendingStockUpdatesSent extends PendingStockUpdatesState {
  final String message;
  PendingStockUpdatesSent(this.message);
}

class PendingStockUpdatesSyncReady extends PendingStockUpdatesState {}

class PendingStockUpdatesError extends PendingStockUpdatesState {
  final String message;
  PendingStockUpdatesError(this.message);
}
