import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/utils/global_var_utils.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/get_sale_session_counts.dart';

/// State for session counts
class SessionCountsState {
  final Map<String, int> counts;
  final bool isLoading;

  const SessionCountsState({
    this.counts = const {},
    this.isLoading = false,
  });

  SessionCountsState copyWith({
    Map<String, int>? counts,
    bool? isLoading,
  }) {
    return SessionCountsState(
      counts: counts ?? this.counts,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Cubit for managing sale session counts
class SessionCountsCubit extends Cubit<SessionCountsState> {
  SessionCountsCubit({required this.getSaleSessionCounts})
      : super(const SessionCountsState());

  final GetSaleSessionCounts getSaleSessionCounts;

  Future<void> loadSessionCounts() async {
    final shopfront = AppGlobals.instance.shopfront;
    if (shopfront == null || shopfront.isEmpty) return;

    emit(state.copyWith(isLoading: true));

    try {
      final counts = await getSaleSessionCounts(shopfront);
      emit(state.copyWith(counts: counts, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  void clearCounts() {
    emit(const SessionCountsState());
  }
}
