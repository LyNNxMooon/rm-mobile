import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/load_dashboard_white_theme.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/update_dashboard_white_theme.dart';

/// Cubit to manage the dashboard white-theme preference.
/// State is `true` when the white palette is enabled, `false` otherwise.
class DashboardWhiteThemeCubit extends Cubit<bool> {
  DashboardWhiteThemeCubit({
    required LoadDashboardWhiteTheme loadDashboardWhiteTheme,
    required UpdateDashboardWhiteTheme updateDashboardWhiteTheme,
  })  : _loadDashboardWhiteTheme = loadDashboardWhiteTheme,
        _updateDashboardWhiteTheme = updateDashboardWhiteTheme,
        super(false) {
    _load();
  }

  final LoadDashboardWhiteTheme _loadDashboardWhiteTheme;
  final UpdateDashboardWhiteTheme _updateDashboardWhiteTheme;

  Future<void> _load() async {
    try {
      final enabled = await _loadDashboardWhiteTheme();
      emit(enabled);
    } catch (_) {
      emit(false);
    }
  }

  Future<void> setWhiteTheme(bool enabled) async {
    emit(enabled);
    try {
      await _updateDashboardWhiteTheme(enabled);
    } catch (_) {}
  }
}
