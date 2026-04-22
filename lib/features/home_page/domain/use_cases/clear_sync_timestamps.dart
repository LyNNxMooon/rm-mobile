import 'package:rmmobile/features/home_page/domain/repositories/home_repo.dart';

class ClearSyncTimestamps {
  final HomeRepo repo;

  ClearSyncTimestamps(this.repo);

  Future<void> call(String shopfrontId) {
    return repo.clearSyncTimestamps(shopfrontId);
  }
}
