import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';

class UpdateRetentionDays {
  final HomeRepo repository;
  UpdateRetentionDays(this.repository);

  Future<void> call(int days) => repository.setRetentionDays(days);
}
