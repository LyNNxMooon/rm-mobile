import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmmobile/entities/response/staff_detail_response.dart';
import 'package:rmmobile/features/customer_lookup/domain/use_cases/get_staff_by_barcode.dart';

enum StaffBarcodeTarget { openedBy, owner }

class StaffBarcodeLookupEvent {
  final String barcode;
  final StaffBarcodeTarget target;

  StaffBarcodeLookupEvent({required this.barcode, required this.target});
}

class StaffBarcodeLookupState {
  final StaffBarcodeTarget target;
  final bool isLoading;
  final bool isValid;
  final String? message;
  final int? staffId;

  StaffBarcodeLookupState({
    required this.target,
    required this.isLoading,
    required this.isValid,
    required this.message,
    required this.staffId,
  });

  factory StaffBarcodeLookupState.initial(StaffBarcodeTarget target) {
    return StaffBarcodeLookupState(
      target: target,
      isLoading: false,
      isValid: false,
      message: null,
      staffId: null,
    );
  }
}

class StaffBarcodeLookupBloc
    extends Bloc<StaffBarcodeLookupEvent, StaffBarcodeLookupState> {
  final GetStaffByBarcode getStaffByBarcode;

  StaffBarcodeLookupBloc({required this.getStaffByBarcode})
      : super(StaffBarcodeLookupState.initial(StaffBarcodeTarget.openedBy)) {
    on<StaffBarcodeLookupEvent>(_onLookup);
  }

  Future<void> _onLookup(
    StaffBarcodeLookupEvent event,
    Emitter<StaffBarcodeLookupState> emit,
  ) async {
    final trimmed = event.barcode.trim();
    if (trimmed.isEmpty) {
      emit(
        StaffBarcodeLookupState(
          target: event.target,
          isLoading: false,
          isValid: false,
          message: null,
          staffId: null,
        ),
      );
      return;
    }

    emit(
      StaffBarcodeLookupState(
        target: event.target,
        isLoading: true,
        isValid: false,
        message: null,
        staffId: null,
      ),
    );

    try {
      final response = await getStaffByBarcode(trimmed);
      final StaffDetailInfo? staff = response.staff;
      final String message = _formatStaffLookupMessage(staff);

      emit(
        StaffBarcodeLookupState(
          target: event.target,
          isLoading: false,
          isValid: staff != null,
          message: message,
          staffId: staff?.staffId,
        ),
      );
    } catch (e) {
      emit(
        StaffBarcodeLookupState(
          target: event.target,
          isLoading: false,
          isValid: false,
          message: "Staff not found",
          staffId: null,
        ),
      );
    }
  }

  String _formatStaffLookupMessage(StaffDetailInfo? staff) {
    if (staff == null) return "Staff not found";
    final name = "${staff.givenNames} ${staff.surname}".trim();
    final staffNo = staff.staffNo.trim();
    if (staffNo.isEmpty && name.isEmpty) return "Staff found";
    if (staffNo.isEmpty) return "Found: $name";
    if (name.isEmpty) return "Found: $staffNo";
    return "Found: $staffNo - $name";
  }
}
