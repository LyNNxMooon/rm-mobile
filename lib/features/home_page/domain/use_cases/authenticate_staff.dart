import 'package:rmstock_scanner/entities/response/authenticate_staff_response.dart';
import 'package:rmstock_scanner/features/home_page/domain/repositories/home_repo.dart';

class AuthenticateStaff {
  final HomeRepo repository;

  AuthenticateStaff(this.repository);

  Future<AuthenticateStaffResponse> call({
    required String ip,
    required int port,
    required String apiKey,
    required String shopfrontId,
    required String shopfrontName,
    required String staffNo,
    required String password,
  }) async {
    try {
      return await repository.authenticateStaff(
        ip: ip,
        port: port,
        apiKey: apiKey,
        shopfrontId: shopfrontId,
        shopfrontName: shopfrontName,
        staffNo: staffNo,
        password: password,
      );
    } catch (error) {
      return Future.error(error);
    }
  }
}
