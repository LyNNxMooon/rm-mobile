import 'dart:io';

import '../repositories/home_repo.dart';

class ImportDatabaseFile {
  final HomeRepo repository;

  ImportDatabaseFile(this.repository);

  Future<void> call(String sourcePath) async {
    try {
      // Verify the source file exists
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return Future.error('Selected file not found');
      }

      // Verify it's a valid SQLite database file
      final bytes = await sourceFile.openRead(0, 16).first;
      final header = String.fromCharCodes(bytes.take(6));
      if (header != 'SQLite') {
        return Future.error('Invalid database file. Please select a valid SQLite database.');
      }

      // Close the current database connection
      await repository.closeDatabase();

      // Get the destination path
      final destPath = await repository.getDatabasePath();
      final destFile = File(destPath);

      // Create backup of current database
      if (await destFile.exists()) {
        final backupPath = '$destPath.backup';
        await destFile.copy(backupPath);
      }

      // Copy the new database
      await sourceFile.copy(destPath);

      // Reopen the database
      await repository.reopenDatabase();

    } catch (error) {
      return Future.error(error);
    }
  }
}
