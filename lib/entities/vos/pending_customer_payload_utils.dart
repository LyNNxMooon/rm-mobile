import 'package:rmstock_scanner/entities/vos/customer_vo.dart';
import 'package:rmstock_scanner/entities/vos/pending_customer_creation_vo.dart';
import 'package:rmstock_scanner/entities/vos/pending_customer_update_vo.dart';

Map<String, dynamic> firstCustomerPayloadItem(Map<String, dynamic> payload) {
  final items = payload['items'];
  if (items is List && items.isNotEmpty) {
    final raw = items.first;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
  }
  return <String, dynamic>{};
}

String payloadString(Map<String, dynamic> item, String key) {
  final value = item[key];
  return value is String ? value.trim() : '';
}

String pendingCustomerName(PendingCustomerUpdateVO update) {
  final item = firstCustomerPayloadItem(update.payload);
  final given = payloadString(item, 'givenNames').isNotEmpty
      ? payloadString(item, 'givenNames')
      : payloadString(item, 'given_names');
  final surname = payloadString(item, 'surname');
  final company = payloadString(item, 'company');
  final baseName = [given, surname].where((s) => s.isNotEmpty).join(' ');
  final name = baseName.isNotEmpty
      ? baseName
      : (update.customerId > 0 ? 'Customer #${update.customerId}' : 'New customer');
  return company.isNotEmpty ? '$name ($company)' : name;
}

String pendingCustomerBarcode(PendingCustomerUpdateVO update) {
  final item = firstCustomerPayloadItem(update.payload);
  final barcode = payloadString(item, 'barcode');
  return barcode.isNotEmpty ? barcode : 'Pending update';
}

CustomerVO? customerFromPendingUpdate(PendingCustomerUpdateVO update) {
  final item = firstCustomerPayloadItem(update.payload);
  if (item.isEmpty) return null;
  return CustomerVO.fromApiItem(item);
}

String initialsFromName(String name) {
  final parts = name.split(' ').where((part) => part.trim().isNotEmpty).toList();
  if (parts.isEmpty) return 'C';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
      .toUpperCase();
}

String pendingCustomerCreationName(PendingCustomerCreationVO creation) {
  final item = firstCustomerPayloadItem(creation.payload);
  final given = payloadString(item, 'givenNames').isNotEmpty
      ? payloadString(item, 'givenNames')
      : payloadString(item, 'given_names');
  final surname = payloadString(item, 'surname');
  final company = payloadString(item, 'company');
  final baseName = [given, surname].where((s) => s.isNotEmpty).join(' ');
  final name = baseName.isNotEmpty
      ? baseName
      : (creation.customerId > 0
          ? 'Customer #${creation.customerId}'
          : 'New customer');
  return company.isNotEmpty ? '$name ($company)' : name;
}

String pendingCustomerCreationBarcode(PendingCustomerCreationVO creation) {
  final item = firstCustomerPayloadItem(creation.payload);
  final barcode = payloadString(item, 'barcode');
  if (barcode.isEmpty) return 'Pending create';
  return barcode;
}
