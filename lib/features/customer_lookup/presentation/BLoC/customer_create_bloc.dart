import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/features/customer_lookup/domain/use_cases/create_customer.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_create_events.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_create_states.dart';
import 'package:rmstock_scanner/local_db/local_db_dao.dart';
import 'package:rmstock_scanner/utils/global_var_utils.dart';

class CustomerCreateBloc extends Bloc<CustomerCreateEvent, CustomerCreateState> {
  final CreateCustomer createCustomer;

  CustomerCreateBloc({required this.createCustomer}) : super(CustomerCreateInitial()) {
    on<CreateCustomerEvent>((event, emit) async {
      emit(CustomerCreateLoading());

      try {
        final response = await createCustomer.call(event.customerData);

        if (response.success) {
          emit(CustomerCreateSuccess(
            message: response.message,
            customerIds: response.customerIds,
          ));
        } else {
          emit(CustomerCreateError(response.message));
        }
      } catch (e) {
        emit(CustomerCreateError(e.toString()));
      }
    });

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

        final exists = await LocalDbDAO.instance.checkBarcodeExists(
          event.barcode.trim(),
          shopfront,
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
        final newBarcode = await LocalDbDAO.instance.getNextNumericBarcode(shopfront);
        
        emit(BarcodeGeneratedState(newBarcode));
      } catch (e) {
        emit(CustomerCreateError("Error generating barcode: $e"));
      }
    });

    on<ResetCustomerCreateEvent>((event, emit) {
      emit(CustomerCreateInitial());
    });
  }
}
