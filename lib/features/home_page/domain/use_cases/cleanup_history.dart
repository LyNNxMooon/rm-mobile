import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';

class CleanupHistory {
  final HomeRepo repository;
  CleanupHistory(this.repository);

  Future<int> call() => repository.runHistoryCleanup();
}
