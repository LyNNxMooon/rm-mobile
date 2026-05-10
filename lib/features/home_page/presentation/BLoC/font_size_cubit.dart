import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/load_font_size.dart';
import 'package:rmmobile/features/home_page/domain/use_cases/update_font_size.dart';

/// Cubit to manage font size preference.
/// States: "default" (normal font sizes) or "large" (bigger fonts for accessibility)
class FontSizeCubit extends Cubit<String> {
  FontSizeCubit({
    required LoadFontSize loadFontSize,
    required UpdateFontSize updateFontSize,
  })  : _loadFontSize = loadFontSize,
        _updateFontSize = updateFontSize,
        super("") {
    // Empty string = loading state
    _load();
  }

  final LoadFontSize _loadFontSize;
  final UpdateFontSize _updateFontSize;

  /// True while initial setting is being loaded
  bool get isLoading => state.isEmpty;

  Future<void> _load() async {
    try {
      final size = await _loadFontSize();
      emit(size);
    } catch (_) {
      emit("default"); // Default to normal on error
    }
  }

  Future<void> setFontSize(String size) async {
    emit(size);
    try {
      await _updateFontSize(size);
    } catch (_) {}
  }

  bool get isDefault => state == "default";
  bool get isLarge => state == "large";

  /// Returns the text scale factor based on current setting
  /// Default: 1.0, Large: 1.2
  double get scaleFactor {
    if (state == "large") return 1.2;
    return 1.0;
  }
}
