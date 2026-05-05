import 'package:rmmobile/features/home_page/domain/repositories/home_repo.dart';

/// Returns the saved dashboard style.
/// "pro" = new design (default for new installations)
/// "default" = old glass drawer design
class LoadDashboardStyle {
  final HomeRepo repository;
  LoadDashboardStyle(this.repository);

  Future<String> call() => repository.getDashboardStyle();
}
