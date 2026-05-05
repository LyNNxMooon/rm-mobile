import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/load_dashboard_style.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/update_dashboard_style.dart';

/// Cubit to manage dashboard style preference.
/// States: "pro" (new design) or "default" (old glass drawer design)
class DashboardStyleCubit extends Cubit<String> {
  DashboardStyleCubit({
    required LoadDashboardStyle loadDashboardStyle,
    required UpdateDashboardStyle updateDashboardStyle,
  })  : _loadDashboardStyle = loadDashboardStyle,
        _updateDashboardStyle = updateDashboardStyle,
        super("") {
    // Empty string = loading state
    _load();
  }

  final LoadDashboardStyle _loadDashboardStyle;
  final UpdateDashboardStyle _updateDashboardStyle;

  /// True while initial style is being loaded
  bool get isLoading => state.isEmpty;

  Future<void> _load() async {
    try {
      final style = await _loadDashboardStyle();
      emit(style);
    } catch (_) {
      emit("pro"); // Default to Pro on error
    }
  }

  Future<void> setStyle(String style) async {
    emit(style);
    try {
      await _updateDashboardStyle(style);
    } catch (_) {}
  }

  bool get isPro => state == "pro";
  bool get isDefault => state == "default";
}
