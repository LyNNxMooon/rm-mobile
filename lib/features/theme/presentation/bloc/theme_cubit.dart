import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/load_dark_mode_enabled.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/update_dark_mode_enabled.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit({
    required LoadDarkModeEnabled loadDarkModeEnabled,
    required UpdateDarkModeEnabled updateDarkModeEnabled,
  })  : _loadDarkModeEnabled = loadDarkModeEnabled,
        _updateDarkModeEnabled = updateDarkModeEnabled,
        super(ThemeMode.light) {
    _load();
  }

  final LoadDarkModeEnabled _loadDarkModeEnabled;
  final UpdateDarkModeEnabled _updateDarkModeEnabled;

  Future<void> _load() async {
    try {
      final enabled = await _loadDarkModeEnabled();
      emit(enabled ? ThemeMode.dark : ThemeMode.light);
    } catch (_) {
      emit(ThemeMode.light);
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    emit(enabled ? ThemeMode.dark : ThemeMode.light);
    try {
      await _updateDarkModeEnabled(enabled);
    } catch (_) {}
  }
}
