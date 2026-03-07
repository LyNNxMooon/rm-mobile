import 'package:rmstock_scanner/entities/response/staff_detail_response.dart';

import '../repositories/customer_lookup_repo.dart';

class GetStaffDetail {
  final CustomerLookupRepo repository;

  GetStaffDetail(this.repository);

  Future<StaffDetailResponse> call(int staffId) async {
    try {
      return await repository.fetchStaffDetail(staffId);
    } catch (e) {
      return Future.error("Failed to load staff detail: $e");
    }
  }
}
