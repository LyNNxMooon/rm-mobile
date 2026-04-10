import 'package:rmmobile/entities/response/staff_detail_response.dart';

import '../repositories/customer_lookup_repo.dart';

class GetStaffByBarcode {
  final CustomerLookupRepo repository;

  GetStaffByBarcode(this.repository);

  Future<StaffDetailResponse> call(String staffBarcode) async {
    try {
      return await repository.fetchStaffByBarcode(staffBarcode);
    } catch (e) {
      return Future.error("Failed to load staff by barcode: $e");
    }
  }
}
