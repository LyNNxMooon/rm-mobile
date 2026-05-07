import 'package:rmmobile/features/home_page/domain/repositories/home_repo.dart';

/// Saves the font size setting.
/// "default" = normal font sizes
/// "large" = larger fonts for accessibility
class UpdateFontSize {
  final HomeRepo repository;
  UpdateFontSize(this.repository);

  Future<void> call(String size) => repository.setFontSize(size);
}
