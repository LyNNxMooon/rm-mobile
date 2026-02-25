import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';

class SignOutStaff {
  final HomeRepo repository;

  SignOutStaff(this.repository);

  Future<void> call() async {
    try {
      await repository.signOutStaff();
    } catch (error) {
      return Future.error(error);
    }
  }
}
