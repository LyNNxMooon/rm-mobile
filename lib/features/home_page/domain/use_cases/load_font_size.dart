import 'package:rmmobile/features/home_page/domain/repositories/home_repo.dart';

/// Returns the saved font size setting.
/// "default" = normal font sizes
/// "large" = larger fonts for accessibility
class LoadFontSize {
  final HomeRepo repository;
  LoadFontSize(this.repository);

  Future<String> call() => repository.getFontSize();
}
