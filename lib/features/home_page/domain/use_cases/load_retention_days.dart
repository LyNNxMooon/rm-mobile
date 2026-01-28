import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';

class LoadRetentionDays {
  final HomeRepo repository;
  LoadRetentionDays(this.repository);

  Future<int> call() => repository.getRetentionDays();
}
