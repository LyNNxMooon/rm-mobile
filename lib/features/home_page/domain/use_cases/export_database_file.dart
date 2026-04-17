import 'dart:io';

import '../repositories/home_repo.dart';

class ExportDatabaseFile {
  final HomeRepo repository;

  ExportDatabaseFile(this.repository);

  Future<String> call() async {
    try {
      await repository.checkpointDatabase();
      final path = await repository.getDatabasePath();
      final dbFile = File(path);
      if (!await dbFile.exists()) {
        return Future.error('Database file not found');
      }
      return path;
    } catch (error) {
      return Future.error(error);
    }
  }
}
