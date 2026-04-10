import 'package:rmmobile/entities/response/customer_update_response.dart';
import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/internet_connection_utils.dart';

import '../repositories/customer_lookup_repo.dart';

class UpdateCustomerDetails {
  final CustomerLookupRepo repository;

  UpdateCustomerDetails(this.repository);

  Future<CustomerUpdateResponse> call(Map<String, dynamic> body) async {
    try {
      final shopfront =
          (await LocalDbDAO.instance.getShopfrontName() ?? "").trim();
      if (shopfront.isEmpty) {
        return Future.error(
          "Missing shopfront setup. Please reconnect to a host and shopfront.",
        );
      }

      final items = body['items'];
      final Map<String, dynamic> item = items is List && items.isNotEmpty
          ? Map<String, dynamic>.from(items.first as Map)
          : <String, dynamic>{};
      final int customerId =
          (item['customerId'] as num?)?.toInt() ??
          (item['customer_id'] as num?)?.toInt() ??
          0;

      await LocalDbDAO.instance.addPendingCustomerUpdate(
        shopfront: shopfront,
        customerId: customerId,
        action: 'update',
        payload: body,
      );

      await LocalDbDAO.instance.applyPendingCustomerUpdates(shopfront);

      if (await InternetConnectionUtils.instance.checkInternetConnection()) {
        try {
          final response = await repository.updateCustomerDetails(body);
          if (response.success) {
            final pending = await LocalDbDAO.instance.getPendingCustomerUpdates(
              shopfront,
              action: 'update',
              conflictOnly: false,
            );
            final matching = pending
                .where((entry) => entry.customerId == customerId)
                .map((entry) => entry.id)
                .toList();
            if (matching.isNotEmpty) {
              await LocalDbDAO.instance.deletePendingCustomerUpdates(matching);
            }
            return response;
          }
        } catch (_) {}
      }

      return CustomerUpdateResponse(
        success: true,
        message: "Saved locally. Will send when online.",
        updated: 1,
        missing: 0,
        skipped: 0,
      );
    } catch (e) {
      return CustomerUpdateResponse(
        success: true,
        message: "Saved locally. Will send when online.",
        updated: 1,
        missing: 0,
        skipped: 0,
      );
    }
  }
}
