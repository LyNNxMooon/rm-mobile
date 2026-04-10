import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/features/customer_lookup/domain/use_cases/check_barcode_exists.dart';
import 'package:rmmobile/features/customer_lookup/domain/use_cases/create_customer.dart';
import 'package:rmmobile/features/customer_lookup/domain/use_cases/get_next_customer_address_id.dart';
import 'package:rmmobile/features/customer_lookup/domain/use_cases/get_next_customer_id.dart';
import 'package:rmmobile/features/customer_lookup/domain/use_cases/get_next_numeric_barcode.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_create_events.dart';
import 'package:rmmobile/features/customer_lookup/presentation/BLoC/customer_create_states.dart';
import 'package:rmmobile/utils/global_var_utils.dart';
import 'package:rmmobile/utils/log_utils.dart';

class CustomerCreateBloc extends Bloc<CustomerCreateEvent, CustomerCreateState> {
  final CreateCustomer createCustomer;
  final CheckBarcodeExists checkBarcodeExists;
  final GetNextNumericBarcode getNextNumericBarcode;
  final GetNextCustomerId getNextCustomerId;
  final GetNextCustomerAddressId getNextCustomerAddressId;

  CustomerCreateBloc({
    required this.createCustomer,
    required this.checkBarcodeExists,
    required this.getNextNumericBarcode,
    required this.getNextCustomerId,
    required this.getNextCustomerAddressId,
  }) : super(CustomerCreateInitial()) {
    on<CreateCustomerEvent>(_onCreateCustomer);
    on<SubmitCustomerCreateFormEvent>(_onSubmitCustomerCreateForm);

    on<ValidateBarcodeEvent>((event, emit) async {
      try {
        final shopfront = AppGlobals.instance.shopfront ?? "";
        
        if (event.barcode.trim().isEmpty) {
          emit(BarcodeValidationState(
            isValid: false,
            message: "Barcode cannot be empty",
            barcode: event.barcode,
          ));
          return;
        }

        final exists = await checkBarcodeExists(
          shopfront: shopfront,
          barcode: event.barcode.trim(),
        );

        if (exists) {
          emit(BarcodeValidationState(
            isValid: false,
            message: "Barcode already exists",
            barcode: event.barcode,
          ));
        } else {
          emit(BarcodeValidationState(
            isValid: true,
            message: "Barcode is available",
            barcode: event.barcode,
          ));
        }
      } catch (e) {
        emit(CustomerCreateError("Error validating barcode: $e"));
      }
    });

    on<GenerateBarcodeEvent>((event, emit) async {
      try {
        final shopfront = AppGlobals.instance.shopfront ?? "";
        final newBarcode = await getNextNumericBarcode(shopfront: shopfront);
        
        emit(BarcodeGeneratedState(newBarcode));
      } catch (e) {
        emit(CustomerCreateError("Error generating barcode: $e"));
      }
    });

    on<ResetCustomerCreateEvent>((event, emit) {
      emit(CustomerCreateInitial());
    });
  }

  Future<void> _onCreateCustomer(
    CreateCustomerEvent event,
    Emitter<CustomerCreateState> emit,
  ) async {
    emit(CustomerCreateLoading());

    try {
      logger.d("Create customer payload: ${event.customerData}");
      final response = await createCustomer.call(event.customerData);

      if (response.success) {
        emit(
          CustomerCreateSuccess(
            message: response.message,
            customerIds: response.customerIds,
          ),
        );
      } else {
        emit(CustomerCreateError(response.message));
      }
    } catch (e) {
      emit(CustomerCreateError(e.toString()));
    }
  }

  Future<void> _onSubmitCustomerCreateForm(
    SubmitCustomerCreateFormEvent event,
    Emitter<CustomerCreateState> emit,
  ) async {
    emit(CustomerCreateLoading());

    try {
      final shopfront = AppGlobals.instance.shopfront ?? "";
      final nextCustomerId = await getNextCustomerId(shopfront: shopfront);
      final nextAddressId = await getNextCustomerAddressId(
        shopfront: shopfront,
      );

      final List<Map<String, dynamic>> addresses = [
        {
          'addressId': nextAddressId,
          'customerId': nextCustomerId,
          'addressNumber': 1,
          'addr1': event.form.addr1,
          'addr2': event.form.addr2,
          'addr3': event.form.addr3,
          'suburb': event.form.suburb,
          'state': event.form.state,
          'postcode': event.form.postcode,
          'country': event.form.country,
          'phone': event.form.phone,
          'fax': event.form.fax,
          'mobile': event.form.mobile,
          'email': event.form.email,
        },
      ];

      var addressIdCursor = nextAddressId + 1;
      for (final address in event.form.secondaryAddresses) {
        addresses.add(
          {
            'addressId': addressIdCursor,
            'customerId': nextCustomerId,
            'addressNumber': address.addressNumber,
            'addr1': address.addr1,
            'addr2': address.addr2,
            'addr3': address.addr3,
            'suburb': address.suburb,
            'state': address.state,
            'postcode': address.postcode,
            'country': address.country,
            'phone': address.phone,
            'mobile': address.mobile,
            'email': address.email,
          },
        );
        addressIdCursor += 1;
      }

      final Map<String, dynamic> customerData = {
        "items": [
          {
            "customerId": nextCustomerId,
            "barcode": event.form.barcode,
            "surname": event.form.surname,
            "givenNames": event.form.givenNames,
            "grade": event.form.grade,
            "company": event.form.company,
            "position": event.form.position,
            "salutation": event.form.salutation,
            "status": event.form.status,
            "abn": event.form.abn,
            "notes": event.form.notes,
            "comments": event.form.comments,
            "custom1": event.form.custom1,
            "custom2": event.form.custom2,
            "inactive": event.form.inactive,
            "addr1": event.form.addr1,
            "addr2": event.form.addr2,
            "addr3": event.form.addr3,
            "suburb": event.form.suburb,
            "state": event.form.state,
            "postcode": event.form.postcode,
            "country": event.form.country,
            "phone": event.form.phone,
            "fax": event.form.fax,
            "mobile": event.form.mobile,
            "email": event.form.email,
            "account": event.form.account,
            "openedId": event.form.openedStaffId ?? 0,
            "opened_id": event.form.openedStaffId ?? 0,
            "ownerId": event.form.ownerStaffId ?? 0,
            "owner_id": event.form.ownerStaffId ?? 0,
            "fromEOM": event.form.fromEom,
            "days": event.form.days,
            "limit": event.form.limit,
            "overseas": event.form.overseas,
            "defaultDeliveryAddress": event.form.defaultDeliveryAddress,
            "documentDeliveryType": event.form.documentDeliveryType,
            if (addresses.isNotEmpty) "addresses": addresses,
          },
        ],
      };

      logger.d("Create customer payload: $customerData");
      final response = await createCustomer.call(customerData);

      if (response.success) {
        emit(
          CustomerCreateSuccess(
            message: response.message,
            customerIds: response.customerIds,
          ),
        );
      } else {
        emit(CustomerCreateError(response.message));
      }
    } catch (e) {
      emit(CustomerCreateError(e.toString()));
    }
  }
}
