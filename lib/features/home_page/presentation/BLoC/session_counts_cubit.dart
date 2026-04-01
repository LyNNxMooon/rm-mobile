import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/local_db/local_db_dao.dart';
import 'package:rmstock_scanner/utils/global_var_utils.dart';

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
  SessionCountsCubit() : super(const SessionCountsState());

  Future<void> loadSessionCounts() async {
    final shopfront = AppGlobals.instance.shopfront;
    if (shopfront == null || shopfront.isEmpty) return;

    emit(state.copyWith(isLoading: true));

    try {
      final counts = await LocalDbDAO.instance.getSaleSessionCounts(shopfront);
      emit(state.copyWith(counts: counts, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  void clearCounts() {
    emit(const SessionCountsState());
  }
}
