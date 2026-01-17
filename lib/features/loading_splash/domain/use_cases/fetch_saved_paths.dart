import 'package:rmstock_scanner/features/loading_splash/domain/repositories/loading_splash_repo.dart';

import '../../../../utils/log_utils.dart';

class FetchSavedPaths {
  final LoadingSplashRepo repository;

  FetchSavedPaths(this.repository);

  Future<List<Map<String, dynamic>>> call() async {
    try {
      final List<Map<String, dynamic>> pathData = await repository
          .getSavedPaths();

      logger.d('This is on use case lvl": $pathData');

      if (pathData.isEmpty) {
        return [];
      } else {
        return pathData;
      }
    } catch (error) {
      return Future.error(error);
    }
  }
}
