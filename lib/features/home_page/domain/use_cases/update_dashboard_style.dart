import 'package:rmmobile/features/home_page/domain/repositories/home_repo.dart';

/// Updates the saved dashboard style.
/// "pro" = new design
/// "default" = old glass drawer design
class UpdateDashboardStyle {
  final HomeRepo repository;
  UpdateDashboardStyle(this.repository);

  Future<void> call(String style) => repository.setDashboardStyle(style);
}
