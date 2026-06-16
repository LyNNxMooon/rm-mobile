import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/utils/global_var_utils.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/get_sale_session_counts.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/get_sale_session_summaries.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/get_stocktake_session_summary.dart';

/// Summary data for a session type
class SessionSummary {
  final int count;
  final double totalValue;
  final DateTime? oldestDate;
  final int customerCount;
  final int itemCount;

  const SessionSummary({
    this.count = 0,
    this.totalValue = 0.0,
    this.oldestDate,
    this.customerCount = 0,
    this.itemCount = 0,
  });

  factory SessionSummary.fromMap(Map<String, dynamic> map) {
    DateTime? oldest;
    if (map['oldestDate'] != null) {
      try {
        oldest = DateTime.parse(map['oldestDate'] as String);
      } catch (_) {}
    }
    return SessionSummary(
      count: map['count'] as int? ?? 0,
      totalValue: (map['totalValue'] as num?)?.toDouble() ?? 0.0,
      oldestDate: oldest,
      customerCount: map['customerCount'] as int? ?? 0,
      itemCount: map['itemCount'] as int? ?? 0,
    );
  }

  /// Get age in days
  int get ageInDays {
    if (oldestDate == null) return 0;
    return DateTime.now().difference(oldestDate!).inDays;
  }
}

/// State for session counts
class SessionCountsState {
  final Map<String, int> counts;
  final Map<String, SessionSummary> summaries;
  final bool isLoading;

  const SessionCountsState({
    this.counts = const {},
    this.summaries = const {},
    this.isLoading = false,
  });

  SessionCountsState copyWith({
    Map<String, int>? counts,
    Map<String, SessionSummary>? summaries,
    bool? isLoading,
  }) {
    return SessionCountsState(
      counts: counts ?? this.counts,
      summaries: summaries ?? this.summaries,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Cubit for managing sale session counts
class SessionCountsCubit extends Cubit<SessionCountsState> {
  SessionCountsCubit({
    required this.getSaleSessionCounts,
    required this.getSaleSessionSummaries,
    required this.getStocktakeSessionSummary,
  }) : super(const SessionCountsState());

  final GetSaleSessionCounts getSaleSessionCounts;
  final GetSaleSessionSummaries getSaleSessionSummaries;
  final GetStocktakeSessionSummary getStocktakeSessionSummary;

  Future<void> loadSessionCounts() async {
    final shopfront = AppGlobals.instance.shopfront;
    if (shopfront == null || shopfront.isEmpty) return;

    emit(state.copyWith(isLoading: true));

    try {
      final counts = await getSaleSessionCounts(shopfront);
      final summariesRaw = await getSaleSessionSummaries(shopfront);

      final summaries = <String, SessionSummary>{};
      for (final entry in summariesRaw.entries) {
        summaries[entry.key] = SessionSummary.fromMap(entry.value);
      }

      // Merge in the in-progress (uncommitted) stocktake summary.
      final stocktakeRaw = await getStocktakeSessionSummary(shopfront);
      final int stocktakeItemCount = stocktakeRaw['count'] as int? ?? 0;
      // Badge/pending count is a fixed 1 when a stocktake is in progress
      // (not the item count).
      final Map<String, int> mergedCounts = {
        ...counts,
        'Stocktake': stocktakeItemCount > 0 ? 1 : 0,
      };
      summaries['Stocktake'] = SessionSummary.fromMap({
        'count': stocktakeItemCount,
        'itemCount': stocktakeItemCount,
        'oldestDate': stocktakeRaw['oldestDate'],
      });

      emit(state.copyWith(
        counts: mergedCounts,
        summaries: summaries,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  void clearCounts() {
    emit(const SessionCountsState());
  }
}
