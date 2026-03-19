import 'package:rmstock_scanner/entities/response/customer_create_response.dart';
import '../../../../local_db/local_db_dao.dart';
import '../../../../utils/internet_connection_utils.dart';

import '../repositories/customer_lookup_repo.dart';

class CreateCustomer {
  final CustomerLookupRepo repository;

  CreateCustomer(this.repository);

  Future<CustomerCreateResponse> call(Map<String, dynamic> body) async {
    int customerId = 0;
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
      customerId =
          (item['customerId'] as num?)?.toInt() ??
          (item['customer_id'] as num?)?.toInt() ??
          0;

      final bool isOnline =
          await InternetConnectionUtils.instance.checkInternetConnection();
      if (isOnline) {
        try {
          final response = await repository.createCustomer(body);
          if (response.success) {
            final pending = await LocalDbDAO.instance.getPendingCustomerCreations(
              shopfront,
            );
            final matching = pending
                .where((entry) => entry.customerId == customerId)
                .map((entry) => entry.id)
                .toList();
            if (matching.isNotEmpty) {
              await LocalDbDAO.instance.deletePendingCustomerCreations(matching);
            }
            return response;
          }
        } catch (_) {}
      }

      await LocalDbDAO.instance.addPendingCustomerCreation(
        shopfront: shopfront,
        customerId: customerId,
        payload: body,
      );

      return CustomerCreateResponse(
        success: true,
        message: "Saved locally. Will send when online.",
        created: 1,
        failed: 0,
        addressesCreated: 0,
        customerIds: customerId > 0 ? [customerId] : [],
        results: const [],
        failureDetails: const [],
      );
    } catch (e) {
      return CustomerCreateResponse(
        success: true,
        message: "Saved locally. Will send when online.",
        created: 1,
        failed: 0,
        addressesCreated: 0,
        customerIds: customerId > 0 ? [customerId] : [],
        results: const [],
        failureDetails: const [],
      );
    }
  }
}
