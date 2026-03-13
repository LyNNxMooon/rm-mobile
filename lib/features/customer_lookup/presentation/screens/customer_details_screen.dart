import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/entities/response/staff_detail_response.dart';
import 'package:rmstock_scanner/entities/vos/customer_address_vo.dart';
import 'package:rmstock_scanner/entities/vos/customer_vo.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_lookup_bloc.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_lookup_events.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_lookup_states.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/screens/customer_transactions_screen.dart';
import 'package:rmstock_scanner/utils/enums.dart';
import 'package:rmstock_scanner/utils/global_var_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/staff_barcode_lookup_bloc.dart';
import '../../../../constants/colors.dart';

// Assuming you have this gradient defined in your constants
const kGColor = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0F8ABE), Color(0xFF05203C)],
);

class _AddressControllers {
  _AddressControllers({
    required this.addressNumber,
    required this.addressId,
    required this.addr1,
    required this.addr2,
    required this.addr3,
    required this.suburb,
    required this.state,
    required this.postcode,
    required this.country,
    required this.phone,
    required this.fax,
    required this.mobile,
    required this.email,
  });

  final int addressNumber;
  final int addressId;
  final TextEditingController addr1;
  final TextEditingController addr2;
  final TextEditingController addr3;
  final TextEditingController suburb;
  final TextEditingController state;
  final TextEditingController postcode;
  final TextEditingController country;
  final TextEditingController phone;
  final TextEditingController fax;
  final TextEditingController mobile;
  final TextEditingController email;

  factory _AddressControllers.fromCustomerAddress(
    CustomerAddressVO? address,
    int addressNumber,
  ) {
    return _AddressControllers(
      addressNumber: addressNumber,
      addressId: address?.addressId ?? 0,
      addr1: TextEditingController(text: address?.addr1 ?? ""),
      addr2: TextEditingController(text: address?.addr2 ?? ""),
      addr3: TextEditingController(text: address?.addr3 ?? ""),
      suburb: TextEditingController(text: address?.suburb ?? ""),
      state: TextEditingController(text: address?.state ?? ""),
      postcode: TextEditingController(text: address?.postcode ?? ""),
      country: TextEditingController(text: address?.country ?? ""),
      phone: TextEditingController(text: address?.phone ?? ""),
      fax: TextEditingController(text: address?.fax ?? ""),
      mobile: TextEditingController(text: address?.mobile ?? ""),
      email: TextEditingController(text: address?.email ?? ""),
    );
  }

  bool get hasAnyValue {
    return addr1.text.trim().isNotEmpty ||
        addr2.text.trim().isNotEmpty ||
        addr3.text.trim().isNotEmpty ||
        suburb.text.trim().isNotEmpty ||
        state.text.trim().isNotEmpty ||
        postcode.text.trim().isNotEmpty ||
        country.text.trim().isNotEmpty ||
        phone.text.trim().isNotEmpty ||
        fax.text.trim().isNotEmpty ||
        mobile.text.trim().isNotEmpty ||
        email.text.trim().isNotEmpty;
  }

  Map<String, dynamic> toUpdateMap(int customerId) {
    return <String, dynamic>{
      'addressId': addressId,
      'customerId': customerId,
      'addressNumber': addressNumber,
      'addr1': addr1.text.trim(),
      'addr2': addr2.text.trim(),
      'addr3': addr3.text.trim(),
      'suburb': suburb.text.trim(),
      'state': state.text.trim(),
      'postcode': postcode.text.trim(),
      'country': country.text.trim(),
      'phone': phone.text.trim(),
      'fax': fax.text.trim(),
      'mobile': mobile.text.trim(),
      'email': email.text.trim(),
    };
  }

  void dispose() {
    addr1.dispose();
    addr2.dispose();
    addr3.dispose();
    suburb.dispose();
    state.dispose();
    postcode.dispose();
    country.dispose();
    phone.dispose();
    fax.dispose();
    mobile.dispose();
    email.dispose();
  }
}

class CustomerDetailsScreen extends StatefulWidget {
  const CustomerDetailsScreen({super.key, required this.customer});

  final CustomerVO customer;

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _AbnInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clipped = digitsOnly.length > 11
        ? digitsOnly.substring(0, 11)
        : digitsOnly;

    final buffer = StringBuffer();
    for (var i = 0; i < clipped.length; i++) {
      if (i == 2 || i == 5 || i == 8) {
        buffer.write('-');
      }
      buffer.write(clipped[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  bool _shouldSyncOnExit = false;

  CustomerEditSection? _editingSection;
  CustomerEditSection? _savingSection;

  late TextEditingController _surnameController;
  late TextEditingController _givenNamesController;
  late TextEditingController _companyController;
  late TextEditingController _positionController;
  late TextEditingController _salutationController;
  late TextEditingController _gradeController;

  late TextEditingController _phoneController;
  late TextEditingController _faxController;
  late TextEditingController _mobileController;
  late TextEditingController _emailController;

  late TextEditingController _addr1Controller;
  late TextEditingController _addr2Controller;
  late TextEditingController _addr3Controller;
  late TextEditingController _suburbController;
  late TextEditingController _stateController;
  late TextEditingController _postcodeController;
  late TextEditingController _countryController;

  late TextEditingController _limitController;
  late TextEditingController _daysController;
  bool _fromEomValue = false;
  late TextEditingController _openedByController;
  Timer? _openedByStaffLookupDebounce;
  String? _openedByStaffLookupMessage;
  bool _openedByStaffLookupValid = false;
  bool _openedByStaffLookupLoading = false;
  int? _openedByStaffId;
  bool _openedByStaffEdited = false;
  late TextEditingController _ownerAccountController;
  Timer? _ownerStaffLookupDebounce;
  String? _ownerStaffLookupMessage;
  bool _ownerStaffLookupValid = false;
  bool _ownerStaffLookupLoading = false;
  int? _ownerStaffId;
  bool _ownerStaffEdited = false;

  late TextEditingController _abnController;
  late TextEditingController _defaultDeliveryAddressController;
  late TextEditingController _documentDeliveryTypeController;
  late TextEditingController _custom1Controller;
  late TextEditingController _custom2Controller;
  bool _statusValue = false;
  bool _inactiveValue = false;
  bool _accountValue = false;
  bool _overseasValue = false;

  late TextEditingController _notesController;
  late TextEditingController _commentsController;

  late Map<int, _AddressControllers> _secondaryAddressControllers;

  @override
  void initState() {
    _initControllers();
    _openedByStaffId = widget.customer.openedId;
    _ownerStaffId = widget.customer.ownerId;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffDetailBloc>().add(
        LoadStaffDetailsEvent(
          openedId: widget.customer.openedId,
          ownerId: widget.customer.ownerId,
        ),
      );
    });
  }

  @override
  void dispose() {
    _openedByController.dispose();
    _surnameController.dispose();
    _givenNamesController.dispose();
    _companyController.dispose();
    _positionController.dispose();
    _salutationController.dispose();
    _gradeController.dispose();

    _phoneController.dispose();
    _faxController.dispose();
    _mobileController.dispose();
    _emailController.dispose();

    _addr1Controller.dispose();
    _addr2Controller.dispose();
    _addr3Controller.dispose();
    _suburbController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    _countryController.dispose();

    _limitController.dispose();
    _daysController.dispose();
    _ownerAccountController.dispose();
    _ownerStaffLookupDebounce?.cancel();

    _abnController.dispose();
    _defaultDeliveryAddressController.dispose();
    _documentDeliveryTypeController.dispose();
    _custom1Controller.dispose();
    _custom2Controller.dispose();

    _notesController.dispose();
    _commentsController.dispose();

    for (final address in _secondaryAddressControllers.values) {
      address.dispose();
    }

    super.dispose();
  }

  double _uiScale(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return isTablet ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2) : 1.0;
  }

  double _font(BuildContext context, double size) => size * _uiScale(context);

  void _initControllers() {
    _surnameController = TextEditingController(text: widget.customer.surname);
    _givenNamesController = TextEditingController(
      text: widget.customer.givenNames,
    );
    _companyController = TextEditingController(text: widget.customer.company);
    _positionController = TextEditingController(text: widget.customer.position);
    _salutationController = TextEditingController(
      text: widget.customer.salutation,
    );
    _gradeController = TextEditingController(
      text: widget.customer.grade.toString(),
    );

    _phoneController = TextEditingController(text: widget.customer.phone);
    _faxController = TextEditingController(text: widget.customer.fax);
    _mobileController = TextEditingController(text: widget.customer.mobile);
    _emailController = TextEditingController(text: widget.customer.email);

    _addr1Controller = TextEditingController(text: widget.customer.addr1);
    _addr2Controller = TextEditingController(text: widget.customer.addr2);
    _addr3Controller = TextEditingController(text: widget.customer.addr3);
    _suburbController = TextEditingController(text: widget.customer.suburb);
    _stateController = TextEditingController(text: widget.customer.state);
    _postcodeController = TextEditingController(text: widget.customer.postcode);
    _countryController = TextEditingController(text: widget.customer.country);

    _limitController = TextEditingController(
      text: widget.customer.limit.toString(),
    );
    _daysController = TextEditingController(
      text: widget.customer.days.toString(),
    );
    _fromEomValue = widget.customer.fromEOM;
    _openedByController = TextEditingController();
    _ownerAccountController = TextEditingController();

    _abnController = TextEditingController(text: widget.customer.abn);
    _defaultDeliveryAddressController = TextEditingController(
      text: widget.customer.defaultDeliveryAddress.toString(),
    );
    if (_defaultDeliveryAddressController.text.trim() == '0') {
      _defaultDeliveryAddressController.text = '1';
    }
    _documentDeliveryTypeController = TextEditingController(
      text: widget.customer.documentDeliveryType.toString(),
    );
    _custom1Controller = TextEditingController(text: widget.customer.custom1);
    _custom2Controller = TextEditingController(text: widget.customer.custom2);
    _statusValue = widget.customer.status;
    _inactiveValue = widget.customer.inactive;
    _accountValue = widget.customer.account;
    _overseasValue = widget.customer.overseas;

    _abnController.addListener(() {
      if (_abnController.text.trim().isNotEmpty && _overseasValue) {
        setState(() {
          _overseasValue = false;
        });
      }
    });

    _notesController = TextEditingController(text: widget.customer.notes);
    _commentsController = TextEditingController(text: widget.customer.comments);

    _secondaryAddressControllers = <int, _AddressControllers>{
      2: _AddressControllers.fromCustomerAddress(_findAddress(2), 2),
      3: _AddressControllers.fromCustomerAddress(_findAddress(3), 3),
    };
  }

  CustomerAddressVO? _findAddress(int addressNumber) {
    for (final address in widget.customer.addresses) {
      if (address.addressNumber == addressNumber) {
        return address;
      }
    }
    return null;
  }

  String _currentDisplayName() {
    final String given = _givenNamesController.text.trim();
    final String surname = _surnameController.text.trim();
    final String company = _companyController.text.trim();
    final String name = [given, surname].where((s) => s.isNotEmpty).join(' ');
    return company.isNotEmpty ? "$name ($company)" : name;
  }

  String _formatStaffLookupMessage(StaffDetailInfo? staff) {
    if (staff == null) return "Staff not found";
    return "Found: ${_formatStaffDisplay(staff)}";
  }

  void _onOpenedByStaffBarcodeChanged(String raw) {
    _openedByStaffEdited = true;
    _openedByStaffLookupDebounce?.cancel();

    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _openedByStaffLookupMessage = null;
        _openedByStaffLookupValid = false;
        _openedByStaffLookupLoading = false;
        _openedByStaffId = null;
      });
      context.read<StaffBarcodeLookupBloc>().add(
        StaffBarcodeLookupEvent(
          barcode: "",
          target: StaffBarcodeTarget.openedBy,
        ),
      );
      return;
    }

    setState(() {
      _openedByStaffLookupLoading = true;
    });

    _openedByStaffLookupDebounce = Timer(
      const Duration(milliseconds: 400),
      () {
        context.read<StaffBarcodeLookupBloc>().add(
          StaffBarcodeLookupEvent(
            barcode: trimmed,
            target: StaffBarcodeTarget.openedBy,
          ),
        );
      },
    );
  }

  void _onOwnerStaffBarcodeChanged(String raw) {
    _ownerStaffEdited = true;
    _ownerStaffLookupDebounce?.cancel();

    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _ownerStaffLookupMessage = null;
        _ownerStaffLookupValid = false;
        _ownerStaffLookupLoading = false;
        _ownerStaffId = null;
      });
      context.read<StaffBarcodeLookupBloc>().add(
        StaffBarcodeLookupEvent(
          barcode: "",
          target: StaffBarcodeTarget.owner,
        ),
      );
      return;
    }

    setState(() {
      _ownerStaffLookupLoading = true;
    });

    _ownerStaffLookupDebounce = Timer(
      const Duration(milliseconds: 400),
      () {
        context.read<StaffBarcodeLookupBloc>().add(
          StaffBarcodeLookupEvent(
            barcode: trimmed,
            target: StaffBarcodeTarget.owner,
          ),
        );
      },
    );
  }

  int _parseInt(String raw, int fallback) {
    final parsed = int.tryParse(raw.trim());
    return parsed ?? fallback;
  }

  num _parseNum(String raw, num fallback) {
    final parsed = num.tryParse(raw.trim());
    return parsed ?? fallback;
  }

  String _abnDigitsOnly() {
    return _abnController.text.replaceAll(RegExp(r'\D'), '');
  }

  String _formatAbnForDisplay(String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');
    final clipped = digitsOnly.length > 11
        ? digitsOnly.substring(0, 11)
        : digitsOnly;

    if (clipped.isEmpty) return "";

    final buffer = StringBuffer();
    for (var i = 0; i < clipped.length; i++) {
      if (i == 2 || i == 5 || i == 8) {
        buffer.write('-');
      }
      buffer.write(clipped[i]);
    }

    return buffer.toString();
  }

  int _normalizedDefaultDeliveryAddress() {
    final parsed = _parseInt(
      _defaultDeliveryAddressController.text,
      widget.customer.defaultDeliveryAddress,
    );
    return parsed == 0 ? 1 : parsed;
  }

  void _setOverseasValue(bool value) {
    if (value && _abnController.text.trim().isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cannot set Overseas while ABN is present."),
        ),
      );
      return;
    }

    setState(() {
      _overseasValue = value;
    });
  }

  void _triggerSyncIfNeeded() {
    if (!_shouldSyncOnExit) return;
    context.read<FetchCustomerBloc>().add(
      StartCustomerSyncEvent(
        ipAddress: "",
      ),
    );
    _shouldSyncOnExit = false;
  }

  Map<String, dynamic> _buildUpdateBody({bool includeAddresses = false}) {
    final int resolvedOpenedId =
        _openedByStaffId ??
        _parseInt(_openedByController.text, widget.customer.openedId);
    final int resolvedOwnerId =
        _ownerStaffId ??
        _parseInt(_ownerAccountController.text, widget.customer.ownerId);
    final Map<String, dynamic> item = <String, dynamic>{
      'customerId': widget.customer.customerId,
      'surname': _surnameController.text.trim(),
      'givenNames': _givenNamesController.text.trim(),
      'grade': _parseInt(_gradeController.text, widget.customer.grade),
      'company': _companyController.text.trim(),
      'position': _positionController.text.trim(),
      'salutation': _salutationController.text.trim(),
      'status': _statusValue,
      'inactive': _inactiveValue,
      'account': _accountValue,
      'overseas': _overseasValue,
      'abn': _abnDigitsOnly(),
      'addr1': _addr1Controller.text.trim(),
      'addr2': _addr2Controller.text.trim(),
      'addr3': _addr3Controller.text.trim(),
      'suburb': _suburbController.text.trim(),
      'state': _stateController.text.trim(),
      'postcode': _postcodeController.text.trim(),
      'country': _countryController.text.trim(),
      'phone': _phoneController.text.trim(),
      'fax': _faxController.text.trim(),
      'mobile': _mobileController.text.trim(),
      'email': _emailController.text.trim(),
      'openedId': resolvedOpenedId,
      'opened_id': resolvedOpenedId,
      'ownerId': resolvedOwnerId,
      'owner_id': resolvedOwnerId,
      'fromEOM': _fromEomValue,
      'days': _parseInt(_daysController.text, widget.customer.days),
      'limit': _parseNum(_limitController.text, widget.customer.limit),
      'defaultDeliveryAddress': _normalizedDefaultDeliveryAddress(),
      'documentDeliveryType': _parseInt(
        _documentDeliveryTypeController.text,
        widget.customer.documentDeliveryType,
      ),
      'custom1': _custom1Controller.text.trim(),
      'custom2': _custom2Controller.text.trim(),
      'notes': _notesController.text.trim(),
      'comments': _commentsController.text.trim(),
    };

    if (includeAddresses) {
      final List<Map<String, dynamic>> secondaryAddresses = [];
      final addressOne = _findAddress(1);
      if (addressOne != null) {
        secondaryAddresses.add({
          'addressId': addressOne.addressId,
          'customerId': widget.customer.customerId,
          'addressNumber': 1,
          'addr1': _addr1Controller.text.trim(),
          'addr2': _addr2Controller.text.trim(),
          'addr3': _addr3Controller.text.trim(),
          'suburb': _suburbController.text.trim(),
          'state': _stateController.text.trim(),
          'postcode': _postcodeController.text.trim(),
          'country': _countryController.text.trim(),
          'phone': _phoneController.text.trim(),
          'fax': _faxController.text.trim(),
          'mobile': _mobileController.text.trim(),
          'email': _emailController.text.trim(),
        });
      }
      for (final address in _secondaryAddressControllers.values) {
        if (address.hasAnyValue) {
          secondaryAddresses.add(
            address.toUpdateMap(widget.customer.customerId),
          );
        }
      }
      if (secondaryAddresses.isNotEmpty) {
        item['addresses'] = secondaryAddresses;
      }
    }

    return <String, dynamic>{
      'items': [item],
    };
  }

  Future<void> _toggleEditSection(CustomerEditSection section) async {
    if (_savingSection != null) return;

    if (_editingSection == section) {
      await _saveSection(section);
      return;
    }

    setState(() {
      _editingSection = section;
    });
  }

  Future<void> _saveSection(CustomerEditSection section) async {
    setState(() {
      _savingSection = section;
    });

    if (section == CustomerEditSection.financial) {
      final openedByBarcode = _openedByController.text.trim();
      if (openedByBarcode.isNotEmpty && !_openedByStaffLookupValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter a valid Opened By staff barcode"),
          ),
        );
        setState(() {
          _savingSection = null;
        });
        return;
      }

      final ownerBarcode = _ownerAccountController.text.trim();
      if (ownerBarcode.isNotEmpty && !_ownerStaffLookupValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter a valid owner staff barcode"),
          ),
        );
        setState(() {
          _savingSection = null;
        });
        return;
      }
    }

    final body = _buildUpdateBody(
      includeAddresses: section == CustomerEditSection.address,
    );
    context.read<CustomerUpdateBloc>().add(
      SubmitCustomerUpdateEvent(body: body, section: section),
    );
  }

  InputDecoration _minimalInputDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kPrimaryColor, width: 1.2),
      ),
    );
  }

  Widget _buildEditRow(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
    String? message,
    bool isValid = false,
    bool isLoading = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final double baseSize = _font(context, 14);
    final double smallSize = _font(context, 12);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: TextStyle(fontSize: baseSize, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  style: TextStyle(fontSize: baseSize),
                  decoration: _minimalInputDecoration(),
                  onChanged: onChanged,
                  inputFormatters: inputFormatters,
                  onEditingComplete: () {
                    final trimmedValue = controller.text.trim();
                    if (controller.text != trimmedValue) {
                      controller.value = controller.value.copyWith(
                        text: trimmedValue,
                        selection: TextSelection.collapsed(
                          offset: trimmedValue.length,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          if (isLoading || message != null) ...[
            const SizedBox(height: 6),
            Text(
              isLoading ? "Checking staff..." : (message ?? ""),
              style: TextStyle(
                fontSize: smallSize,
                color: isLoading
                    ? Colors.grey[600]
                    : (isValid ? Colors.green[700] : Colors.red[700]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditIconRow(
    IconData icon,
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    final double baseSize = _font(context, 14);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: baseSize,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: TextStyle(fontSize: baseSize),
              decoration: _minimalInputDecoration(),
              onEditingComplete: () {
                final trimmedValue = controller.text.trim();
                if (controller.text != trimmedValue) {
                  controller.value = controller.value.copyWith(
                    text: trimmedValue,
                    selection: TextSelection.collapsed(
                      offset: trimmedValue.length,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged, {
    bool enabled = true,
  }) {
    final double baseSize = _font(context, 14);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: baseSize, color: Colors.grey[600]),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: kPrimaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final double baseSize = _font(context, 14);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: baseSize, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: DropdownButtonFormField<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              decoration: _minimalInputDecoration(),
              style: TextStyle(fontSize: baseSize, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSecondaryAddressEditors() {
    final double baseSize = _font(context, 13);
    final List<Widget> widgets = [];

    for (final entry in _secondaryAddressControllers.entries) {
      final int addressNumber = entry.key;
      final _AddressControllers address = entry.value;

      widgets.add(
        Text(
          "Address $addressNumber",
          style: TextStyle(
            fontSize: baseSize,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 6));
      widgets.add(_buildEditRow("Addr1", address.addr1));
      widgets.add(_buildEditRow("Addr2", address.addr2));
      widgets.add(_buildEditRow("Addr3", address.addr3));
      widgets.add(_buildEditRow("Suburb", address.suburb));
      widgets.add(_buildEditRow("State", address.state));
      widgets.add(
        _buildEditRow(
          "Postcode",
          address.postcode,
          keyboardType: TextInputType.number,
        ),
      );
      widgets.add(_buildEditRow("Country", address.country));
      widgets.add(
        _buildEditRow(
          "Phone",
          address.phone,
          keyboardType: TextInputType.phone,
        ),
      );
      widgets.add(
        _buildEditRow(
          "Mobile",
          address.mobile,
          keyboardType: TextInputType.phone,
        ),
      );
      widgets.add(
        _buildEditRow(
          "Email",
          address.email,
          keyboardType: TextInputType.emailAddress,
        ),
      );
      widgets.add(const SizedBox(height: 12));
    }

    return widgets;
  }

  String _getInitials(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return "";

    List<String> nameParts = trimmedName.split(RegExp(r'\s+'));

    if (nameParts.length == 1) {
      String word = nameParts[0];
      return word.length >= 2
          ? word.substring(0, 2).toUpperCase()
          : word.toUpperCase();
    } else {
      String firstLetter = nameParts.first[0];
      String lastLetter = nameParts.last[0];
      return (firstLetter + lastLetter).toUpperCase();
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return "-";
    try {
      DateTime dt = DateTime.parse(dateStr);
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (e) {
      return dateStr;
    }
  }

  String _formatStaffDisplay(StaffDetailInfo? staff) {
    if (staff == null) return "-";
    final String fullName = "${staff.givenNames} ${staff.surname}".trim();
    final String barcode = staff.staffNo.trim();

    if (barcode.isEmpty && fullName.isEmpty) return "-";
    if (barcode.isEmpty) return fullName;
    if (fullName.isEmpty) return barcode;
    return "$barcode - $fullName";
  }

  void _showLaunchError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _dialNumber(String number) async {
    final String trimmed = number.trim();
    if (trimmed.isEmpty) return;

    final Uri uri = Uri(scheme: 'tel', path: trimmed);
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      _showLaunchError("No phone app found for this device.");
    }
  }

  Future<void> _emailTo(String email) async {
    final String trimmed = email.trim();
    if (trimmed.isEmpty) return;

    final Uri mailtoUri = Uri(scheme: 'mailto', path: trimmed);
    final bool launched = await launchUrl(
      mailtoUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      _showLaunchError("No email app found for this device.");
    }
  }

  Future<void> _openMapForAddress(String addressQuery) async {
    final String trimmed = addressQuery.trim();
    if (trimmed.isEmpty) return;

    final Uri primaryUri = Platform.isIOS
        ? Uri(
            scheme: 'https',
            host: 'maps.apple.com',
            queryParameters: <String, String>{'q': trimmed},
          )
        : Uri(
            scheme: 'geo',
            path: '0,0',
            queryParameters: <String, String>{'q': trimmed},
          );

    final bool launched = await launchUrl(
      primaryUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      final Uri fallbackUri = Uri(
        scheme: 'https',
        host: 'www.google.com',
        path: '/maps/search/',
        queryParameters: <String, String>{'api': '1', 'query': trimmed},
      );
      final bool fallbackLaunched = await launchUrl(
        fallbackUri,
        mode: LaunchMode.externalApplication,
      );

      if (!fallbackLaunched) {
        _showLaunchError("No maps app found for this device.");
      }
    }
  }

  void _showSecondaryAddressesDialog() {
    final double baseSize = _font(context, 14);
    final double smallSize = _font(context, 12);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 10,
          backgroundColor: Colors
              .white, // Or a slightly off-white like Color(0xFFF9FAFB) if you prefer
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFF3F4F6,
                  ), // Matches the scaffold background of the details screen
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 1.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 20,
                          color: kPrimaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Secondary Addresses",
                          style: TextStyle(
                            fontSize: _font(context, 16),
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    // Close Button in header instead of actions
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Dialog Content (Scrollable list of addresses)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: List.generate(widget.customer.addresses.length, (
                      index,
                    ) {
                      final address = widget.customer.addresses[index];
                      final List<String> addressParts = [
                        address.addr1,
                        address.addr2,
                        address.addr3,
                        "${address.suburb} ${address.state} ${address.postcode}"
                            .trim(),
                        address.country,
                      ].where((s) => s.isNotEmpty).toList();
                      final String addressQuery = addressParts.join(', ');
                      final bool showMapIcon =
                          address.addressNumber == 2 ||
                          address.addressNumber == 3;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Address Number Badge + Map Icon
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kPrimaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "Address ${address.addressNumber}",
                                    style: TextStyle(
                                      fontSize: _font(context, 12),
                                      fontWeight: FontWeight.bold,
                                      color: kPrimaryColor,
                                    ),
                                  ),
                                ),
                                if (showMapIcon)
                                  InkWell(
                                    onTap: () =>
                                        _openMapForAddress(addressQuery),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 46,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.asset(
                                          "assets/images/map.png",
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Address Lines
                            if (address.addr1.isNotEmpty) ...[
                              Text(
                                address.addr1,
                                style: TextStyle(
                                  fontSize: baseSize,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                            if (address.addr2.isNotEmpty) ...[
                              Text(
                                address.addr2,
                                style: TextStyle(
                                  fontSize: baseSize,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                            if (address.addr3.isNotEmpty) ...[
                              Text(
                                address.addr3,
                                style: TextStyle(
                                  fontSize: baseSize,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                            if (address.suburb.isNotEmpty ||
                                address.state.isNotEmpty ||
                                address.postcode.isNotEmpty) ...[
                              Text(
                                "${address.suburb} ${address.state} ${address.postcode}"
                                    .trim(),
                                style: TextStyle(
                                  fontSize: baseSize,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                            if (address.country.isNotEmpty) ...[
                              Text(
                                address.country,
                                style: TextStyle(
                                  fontSize: baseSize,
                                  color: Colors.black87,
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),

                            // Contact Info within this address
                            if (address.phone.isNotEmpty) ...[
                              _buildDialogContactRow(
                                Icons.phone_outlined,
                                address.phone,
                                smallSize,
                              ),
                            ],
                            if (address.mobile.isNotEmpty) ...[
                              _buildDialogContactRow(
                                Icons.phone_iphone_outlined,
                                address.mobile,
                                smallSize,
                              ),
                            ],
                            if (address.email.isNotEmpty) ...[
                              _buildDialogContactRow(
                                Icons.email_outlined,
                                address.email,
                                smallSize,
                              ),
                            ],

                            // Show a message if no contact info exists for this address to avoid empty space
                            if (address.phone.isEmpty &&
                                address.mobile.isEmpty &&
                                address.email.isEmpty) ...[
                              Text(
                                "No contact details for this address.",
                                style: TextStyle(
                                  fontSize: smallSize,
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getGradeLabel(int grade) {
    switch (grade) {
      case 0:
        return "Grade (Default)";
      case 1:
        return "Grade (A)";
      case 2:
        return "Grade (B)";
      case 3:
        return "Grade (C)";
      case 4:
        return "Grade (D)";
      default:
        return "Grade ($grade)";
    }
  }

  Widget _buildDialogContactRow(IconData icon, String text, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: fontSize, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CustomerUpdateBloc, CustomerUpdateState>(
          listener: (context, state) {
            if (state is CustomerUpdateInProgress) {
              setState(() {
                _savingSection = state.section;
              });
            } else if (state is CustomerUpdateSuccess) {
              _shouldSyncOnExit = true;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));

              // Refresh staff details after successful update
              setState(() {
                _savingSection = null;
                _editingSection = null;
                // Reset edit flags so staff details can be refreshed
                _openedByStaffEdited = false;
                _ownerStaffEdited = false;
              });

              // Re-fetch staff details with updated IDs
              context.read<StaffDetailBloc>().add(
                LoadStaffDetailsEvent(
                  openedId: _openedByStaffId ?? 0,
                  ownerId: _ownerStaffId ?? 0,
                ),
              );
              context.read<PendingCustomerUpdatesBloc>().add(
                LoadPendingCustomerUpdatesCountEvent(),
              );
            } else if (state is CustomerUpdateFailure) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
              setState(() {
                _savingSection = null;
              });
            }
          },
        ),
        BlocListener<StaffDetailBloc, StaffDetailState>(
          listener: (context, state) {
            if (state is StaffDetailLoaded) {
              // Handle opened by staff
              if (!_openedByStaffEdited) {
                final openedByStaff = state.openedBy;
                if (openedByStaff != null) {
                  final staffNo = openedByStaff.staffNo.trim();
                  if (staffNo.isNotEmpty) {
                    setState(() {
                      _openedByController.text = staffNo;
                      _openedByStaffId = openedByStaff.staffId;
                      _openedByStaffLookupValid = true;
                      _openedByStaffLookupMessage = _formatStaffLookupMessage(
                        openedByStaff,
                      );
                      _openedByStaffLookupLoading = false;
                    });
                  }
                }
              }

              // Handle owner account staff
              if (!_ownerStaffEdited) {
                final staff = state.ownerAccount;
                if (staff != null) {
                  final staffNo = staff.staffNo.trim();
                  if (staffNo.isNotEmpty) {
                    setState(() {
                      _ownerAccountController.text = staffNo;
                      _ownerStaffId = staff.staffId;
                      _ownerStaffLookupValid = true;
                      _ownerStaffLookupMessage = _formatStaffLookupMessage(
                        staff,
                      );
                      _ownerStaffLookupLoading = false;
                    });
                  }
                }
              }
            }
          },
        ),
        BlocListener<StaffBarcodeLookupBloc, StaffBarcodeLookupState>(
          listener: (context, state) {
            if (!mounted) return;
            if (state.target == StaffBarcodeTarget.openedBy) {
              setState(() {
                _openedByStaffLookupLoading = state.isLoading;
                _openedByStaffLookupValid = state.isValid;
                _openedByStaffLookupMessage = state.message;
                _openedByStaffId = state.staffId;
              });
            } else {
              setState(() {
                _ownerStaffLookupLoading = state.isLoading;
                _ownerStaffLookupValid = state.isValid;
                _ownerStaffLookupMessage = state.message;
                _ownerStaffId = state.staffId;
              });
            }
          },
        ),
      ],
      child: WillPopScope(
        onWillPop: () async {
          _triggerSyncIfNeeded();
          return true;
        },
        child: Scaffold(
          // A slightly deeper grey helps the white cards pop and look solid
          backgroundColor: const Color(0xFFF3EFE8),
          body: Stack(
            children: [
              // Background Gradient Container (Top Half)
              Container(
                height: MediaQuery.of(context).size.height * 0.4,
                decoration: const BoxDecoration(gradient: kGColor),
              ),

              // Custom App Bar Elements (Overlay)
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              _triggerSyncIfNeeded();
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: const Text(
                              "Customers",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          const Text(
                            "Profile",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 80),
                        ],
                      ),
                    ),

                    // Scrollable Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                        child: Column(
                          children: [
                            _buildHeaderCard(),
                            const SizedBox(height: 12),
                            _buildContactDetailsCard(),
                            const SizedBox(height: 12),
                            _buildAddressCard(),
                            const SizedBox(height: 12),
                            _buildFinancialCard(),
                            const SizedBox(height: 12),
                            _buildPersonalCard(),
                            const SizedBox(height: 12),
                            _buildAdditionalInfoCard(),
                            if (_notesController.text.isNotEmpty ||
                                _commentsController.text.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildNotesCard(),
                            ],
                            const SizedBox(height: 12),
                            _buildMetadataCard(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Card Builders ---

  String get _customerCustom1Label => AppGlobals.instance.customerCustom1Label;
  String get _customerCustom2Label => AppGlobals.instance.customerCustom2Label;
  String get _customerStatusLabel => AppGlobals.instance.customerStatusLabel;

  Widget _buildHeaderCard() {
    final double baseSize = _font(context, 14);
    final double smallSize = _font(context, 12);
    final double badgeSize = _font(context, 12);
    final double avatarSize = _font(context, 24);
    final String displayName = _currentDisplayName();
    final String companyName = _companyController.text.trim();
    final int gradeValue = _parseInt(
      _gradeController.text,
      widget.customer.grade,
    );
    final bool statusValue = _statusValue;
    final bool inactiveValue = _inactiveValue;
    final bool accountValue = _accountValue;
    final bool overseasValue = _overseasValue;
    final bool isEditing = _editingSection == CustomerEditSection.header;
    final String statusLabel =
        "$_customerStatusLabel: ${statusValue ? 'True' : 'False'}";
    return _buildBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment
            .start, // <--- ADDED THIS to align chips & content to the left
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.grey[400]!, Colors.grey[500]!],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _getInitials(widget.customer.displayName),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: avatarSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Name and Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            displayName.isEmpty
                                ? widget.customer.displayName
                                : displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Active/Inactive Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: inactiveValue
                                ? Colors.red[50]
                                : Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            inactiveValue ? 'Inactive' : 'Active',
                            style: TextStyle(
                              color: inactiveValue
                                  ? Colors.red[700]
                                  : Colors.green[700],
                              fontSize: badgeSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.customer.company.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        companyName.isNotEmpty
                            ? companyName
                            : widget.customer.company,
                        style: TextStyle(
                          fontSize: baseSize,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      "Customer ID: ${widget.customer.barcode}",
                      style: TextStyle(
                        fontSize: smallSize,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Permanent Chips Row (Uses Wrap so it doesn't overflow)
          Wrap(
            alignment: WrapAlignment.start,
            runAlignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.start,
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildPillBadge(
                accountValue ? "Account" : "Cash",
                Colors.green,
                accountValue,
              ),
              _buildPillBadge(
                _getGradeLabel(gradeValue),
                Colors.blue,
                true, // Always active for visibility
              ),
              _buildPillBadge(
                overseasValue ? "Overseas" : "Local",
                Colors.orange,
                overseasValue,
              ),
              _buildPillBadge(
                statusLabel,
                statusValue ? Colors.green : Colors.amber,
                true,
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),

          if (isEditing) ...[
            _buildEditRow("Given Names", _givenNamesController),
            _buildEditRow("Surname", _surnameController),
            _buildEditRow("Company", _companyController),
            _buildDropdownRow<int>(
              label: "Grade",
              value: _parseInt(_gradeController.text, widget.customer.grade),
              items: const [
                DropdownMenuItem(value: 0, child: Text("Default")),
                DropdownMenuItem(value: 1, child: Text("A")),
                DropdownMenuItem(value: 2, child: Text("B")),
                DropdownMenuItem(value: 3, child: Text("C")),
                DropdownMenuItem(value: 4, child: Text("D")),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _gradeController.text = value.toString();
                });
              },
            ),
            _buildSwitchRow(
              "Active",
              !_inactiveValue,
              (value) => setState(() => _inactiveValue = !value),
            ),
            _buildSwitchRow("Account", _accountValue, (value) {
              if (!value) return;
              setState(() => _accountValue = true);
            }, enabled: !_accountValue),
            _buildSwitchRow(
              "Overseas",
              _overseasValue,
              (value) => _setOverseasValue(value),
            ),
            _buildSwitchRow(
              _customerStatusLabel,
              _statusValue,
              (value) => setState(() => _statusValue = value),
            ),
            const SizedBox(height: 4),
          ],

          // Quick Action Buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(Icons.phone_outlined, "Call", () {
                final String resolvedNumber =
                    widget.customer.phone.trim().isNotEmpty
                    ? widget.customer.phone
                    : widget.customer.mobile;
                _dialNumber(resolvedNumber);
              }),
              _buildActionButton(Icons.email_outlined, "Email", () {
                _emailTo(widget.customer.email);
              }),
              _buildActionButton(
                isEditing ? Icons.save_rounded : Icons.edit,
                isEditing ? "Save" : "Edit",
                () => _toggleEditSection(CustomerEditSection.header),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLongActionButton(
            label: "View Recent Transactions",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CustomerTransactionsScreen(customer: widget.customer),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPillBadge(String text, MaterialColor themeColor, bool isActive) {
    final double badgeSize = _font(context, 11);
    // If not active, it falls back to a muted grey styling
    final bgColor = isActive ? themeColor[50] : Colors.grey[100];
    final textColor = isActive ? themeColor[700] : Colors.grey[600];
    final borderColor = isActive ? themeColor[200] : Colors.grey[300];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor!, width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: badgeSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    final double baseSize = _font(context, 14);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.grey[800]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: baseSize,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLongActionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    final double baseSize = _font(context, 14);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: baseSize, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildContactDetailsCard() {
    final bool isEditing = _editingSection == CustomerEditSection.contact;
    return _buildSectionCard(
      title: "Contact Details",
      isEditing: isEditing,
      isSaving: _savingSection == CustomerEditSection.contact,
      onEditTap: () => _toggleEditSection(CustomerEditSection.contact),
      children: isEditing
          ? [
              _buildEditIconRow(
                Icons.phone_outlined,
                "Phone",
                _phoneController,
                keyboardType: TextInputType.phone,
              ),
              _buildEditIconRow(
                Icons.phone_iphone_outlined,
                "Mobile",
                _mobileController,
                keyboardType: TextInputType.phone,
              ),
              _buildEditIconRow(
                Icons.email_outlined,
                "Email",
                _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              _buildEditIconRow(
                Icons.print_outlined,
                "Fax",
                _faxController,
                keyboardType: TextInputType.phone,
              ),
            ]
          : [
              _buildIconDataRow(
                Icons.phone_outlined,
                "Phone",
                _phoneController.text,
              ),
              _buildIconDataRow(
                Icons.phone_iphone_outlined,
                "Mobile",
                _mobileController.text,
              ),
              _buildIconDataRow(
                Icons.email_outlined,
                "Email",
                _emailController.text,
              ),
              _buildIconDataRow(
                Icons.print_outlined,
                "Fax",
                _faxController.text,
              ),
            ],
    );
  }

  Widget _buildAddressCard() {
    final double baseSize = _font(context, 14);
    final bool isEditing = _editingSection == CustomerEditSection.address;
    final List<String> primaryAddressParts = [
      _addr1Controller.text,
      _addr2Controller.text,
      _addr3Controller.text,
      "${_suburbController.text} ${_stateController.text} ${_postcodeController.text}"
          .trim(),
      _countryController.text,
    ].where((s) => s.trim().isNotEmpty).toList();

    String primaryAddressStr = primaryAddressParts.join('\n');
    final String primaryAddressQuery = primaryAddressParts.join(', ');

    if (primaryAddressStr.isEmpty) {
      primaryAddressStr = "No primary address provided.";
    }

    return _buildSectionCard(
      title: "Addresses",
      isEditing: isEditing,
      isSaving: _savingSection == CustomerEditSection.address,
      onEditTap: () => _toggleEditSection(CustomerEditSection.address),
      children: isEditing
          ? [
              _buildEditRow("Addr1", _addr1Controller),
              _buildEditRow("Addr2", _addr2Controller),
              _buildEditRow("Addr3", _addr3Controller),
              _buildEditRow("Suburb", _suburbController),
              _buildEditRow("State", _stateController),
              _buildEditRow(
                "Postcode",
                _postcodeController,
                keyboardType: TextInputType.number,
              ),
              _buildEditRow("Country", _countryController),
              const SizedBox(height: 8),
              Text(
                "Secondary Addresses",
                style: TextStyle(
                  fontSize: baseSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._buildSecondaryAddressEditors(),
            ]
          : [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 18,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      primaryAddressStr,
                      style: TextStyle(
                        fontSize: baseSize,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _openMapForAddress(primaryAddressQuery),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 60,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          "assets/images/map.png",
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.customer.addresses.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                ),
                InkWell(
                  onTap: () => _showSecondaryAddressesDialog(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Secondary Addresses",
                        style: TextStyle(
                          fontSize: baseSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            "View All Addr",
                            style: TextStyle(
                              fontSize: baseSize,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
    );
  }

  Widget _buildFinancialCard() {
    final double baseSize = _font(context, 14);
    final double smallSize = _font(context, 12);
    final bool isEditing = _editingSection == CustomerEditSection.financial;

    return _buildSectionCard(
      title: "Financial & Account",
      isEditing: isEditing,
      isSaving: _savingSection == CustomerEditSection.financial,
      onEditTap: () => _toggleEditSection(CustomerEditSection.financial),
      children: [
        if (isEditing) ...[
          _buildEditRow(
            "Credit Limit",
            _limitController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          _buildEditRow(
            "Payment Days",
            _daysController,
            keyboardType: TextInputType.number,
          ),
          _buildSwitchRow(
            "From EOM",
            _fromEomValue,
            (value) => setState(() => _fromEomValue = value),
          ),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Credit Limit",
                      style: TextStyle(
                        fontSize: smallSize,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "\$${_parseNum(_limitController.text, widget.customer.limit).toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: baseSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Payment Terms",
                      style: TextStyle(
                        fontSize: smallSize,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${_parseInt(_daysController.text, widget.customer.days)} Days ${_fromEomValue ? 'EOM' : ''}",
                      style: TextStyle(
                        fontSize: baseSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        BlocBuilder<StaffDetailBloc, StaffDetailState>(
          builder: (context, state) {
            String openedBy = "-";
            String ownerAccount = "-";

            if (state is StaffDetailLoading) {
              openedBy = "Loading...";
              ownerAccount = "Loading...";
            } else if (state is StaffDetailLoaded) {
              openedBy = _formatStaffDisplay(state.openedBy);
              ownerAccount = _formatStaffDisplay(state.ownerAccount);
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Opened By",
                        style: TextStyle(
                          fontSize: smallSize,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Allow editing only when in edit mode and the field is empty (openedId == 0)
                      if (isEditing && widget.customer.openedId == 0)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _openedByController,
                              keyboardType: TextInputType.text,
                              style: TextStyle(fontSize: baseSize),
                              decoration: _minimalInputDecoration(),
                              onChanged: _onOpenedByStaffBarcodeChanged,
                              onEditingComplete: () {
                                final trimmedValue = _openedByController.text
                                    .trim();
                                if (_openedByController.text != trimmedValue) {
                                  _openedByController.value =
                                      _openedByController.value.copyWith(
                                        text: trimmedValue,
                                        selection: TextSelection.collapsed(
                                          offset: trimmedValue.length,
                                        ),
                                      );
                                }
                              },
                            ),
                            if (_openedByStaffLookupLoading ||
                                _openedByStaffLookupMessage != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _openedByStaffLookupLoading
                                    ? "Checking staff..."
                                    : (_openedByStaffLookupMessage ?? ""),
                                style: TextStyle(
                                  fontSize: smallSize,
                                  color: _openedByStaffLookupLoading
                                      ? Colors.grey[600]
                                      : (_openedByStaffLookupValid
                                            ? Colors.green[700]
                                            : Colors.red[700]),
                                ),
                              ),
                            ],
                          ],
                        )
                      else
                        Text(
                          openedBy,
                          style: TextStyle(
                            fontSize: baseSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Owner Account",
                        style: TextStyle(
                          fontSize: smallSize,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (isEditing)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _ownerAccountController,
                              keyboardType: TextInputType.text,
                              style: TextStyle(fontSize: baseSize),
                              decoration: _minimalInputDecoration(),
                              onChanged: _onOwnerStaffBarcodeChanged,
                              onEditingComplete: () {
                                final trimmedValue = _ownerAccountController
                                    .text
                                    .trim();
                                if (_ownerAccountController.text !=
                                    trimmedValue) {
                                  _ownerAccountController.value =
                                      _ownerAccountController.value.copyWith(
                                        text: trimmedValue,
                                        selection: TextSelection.collapsed(
                                          offset: trimmedValue.length,
                                        ),
                                      );
                                }
                              },
                            ),
                            if (_ownerStaffLookupLoading ||
                                _ownerStaffLookupMessage != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _ownerStaffLookupLoading
                                    ? "Checking staff..."
                                    : (_ownerStaffLookupMessage ?? ""),
                                style: TextStyle(
                                  fontSize: smallSize,
                                  color: _ownerStaffLookupLoading
                                      ? Colors.grey[600]
                                      : (_ownerStaffLookupValid
                                            ? Colors.green[700]
                                            : Colors.red[700]),
                                ),
                              ),
                            ],
                          ],
                        )
                      else
                        Text(
                          ownerAccount,
                          style: TextStyle(
                            fontSize: baseSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        // _buildLongActionButton(
        //   label: "Print/Email Statement",
        //   onTap: () {
        //     //wire statement action
        //   },
        // ),
      ],
    );
  }

  Widget _buildPersonalCard() {
    final bool isEditing = _editingSection == CustomerEditSection.personal;
    return _buildSectionCard(
      title: "Personal Details",
      isEditing: isEditing,
      isSaving: _savingSection == CustomerEditSection.personal,
      onEditTap: () => _toggleEditSection(CustomerEditSection.personal),
      children: isEditing
          ? [
              _buildEditRow("Salutation", _salutationController),
              _buildEditRow("Given Names", _givenNamesController),
              _buildEditRow("Surname", _surnameController),
              _buildEditRow("Position", _positionController),
            ]
          : [
              _buildDataRow("Salutation", _salutationController.text),
              _buildDataRow("Given Names", _givenNamesController.text),
              _buildDataRow("Surname", _surnameController.text),
              _buildDataRow("Position", _positionController.text),
            ],
    );
  }

  String _defaultDeliveryAddressLabel() {
    final int defaultId = _normalizedDefaultDeliveryAddress();
    if (defaultId == 1) return 'Addr1';
    if (defaultId == 2) return 'Addr2';
    if (defaultId == 3) return 'Addr3';
    return '-';
  }

  String _documentDeliveryLabel() {
    final int docType = _parseInt(
      _documentDeliveryTypeController.text,
      widget.customer.documentDeliveryType,
    );
    switch (docType) {
      case 0:
        return 'Print';
      case 1:
        return 'Email';
      case 2:
        return 'Print & Email';
      default:
        return '-';
    }
  }

  Widget _buildAdditionalInfoCard() {
    final bool isEditing = _editingSection == CustomerEditSection.additional;
    final String custom1Label = _customerCustom1Label;
    final String custom2Label = _customerCustom2Label;
    return _buildSectionCard(
      title: "Additional Info",
      isEditing: isEditing,
      isSaving: _savingSection == CustomerEditSection.additional,
      onEditTap: () => _toggleEditSection(CustomerEditSection.additional),
      children: isEditing
          ? [
              if (!_overseasValue)
                _buildEditRow(
                  "ABN",
                  _abnController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_AbnInputFormatter()],
                ),
              _buildDropdownRow<int>(
                label: "Default Delivery",
                value: _normalizedDefaultDeliveryAddress(),
                items: const [
                  DropdownMenuItem(value: 1, child: Text("Addr1")),
                  DropdownMenuItem(value: 2, child: Text("Addr2")),
                  DropdownMenuItem(value: 3, child: Text("Addr3")),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _defaultDeliveryAddressController.text = value.toString();
                  });
                },
              ),
              _buildDropdownRow<int>(
                label: "Documents",
                value: _parseInt(
                  _documentDeliveryTypeController.text,
                  widget.customer.documentDeliveryType,
                ),
                items: const [
                  DropdownMenuItem(value: 0, child: Text("Print")),
                  DropdownMenuItem(value: 1, child: Text("Email")),
                  DropdownMenuItem(value: 2, child: Text("Print & Email")),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _documentDeliveryTypeController.text = value.toString();
                  });
                },
              ),
              _buildEditRow(custom1Label, _custom1Controller),
              _buildEditRow(custom2Label, _custom2Controller),
              Text(
                "Internal Notes:",
                style: TextStyle(
                  fontSize: _font(context, 12),
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _notesController,
                maxLines: 3,
                style: TextStyle(fontSize: _font(context, 14)),
                decoration: _minimalInputDecoration(),
                onEditingComplete: () {
                  final trimmedValue = _notesController.text.trim();
                  if (_notesController.text != trimmedValue) {
                    _notesController.value = _notesController.value.copyWith(
                      text: trimmedValue,
                      selection: TextSelection.collapsed(
                        offset: trimmedValue.length,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              Text(
                "Comments:",
                style: TextStyle(
                  fontSize: _font(context, 12),
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _commentsController,
                maxLines: 3,
                style: TextStyle(fontSize: _font(context, 14)),
                decoration: _minimalInputDecoration(),
                onEditingComplete: () {
                  final trimmedValue = _commentsController.text.trim();
                  if (_commentsController.text != trimmedValue) {
                    _commentsController.value = _commentsController.value
                        .copyWith(
                          text: trimmedValue,
                          selection: TextSelection.collapsed(
                            offset: trimmedValue.length,
                          ),
                        );
                  }
                },
              ),
            ]
          : [
              if (!_overseasValue)
                _buildDataRow(
                  "ABN",
                  _abnController.text.isEmpty
                      ? "-"
                      : _formatAbnForDisplay(_abnController.text),
                ),
              _buildDataRow("Default Delivery", _defaultDeliveryAddressLabel()),
              _buildDataRow("Documents", _documentDeliveryLabel()),
              _buildDataRow(custom1Label, _custom1Controller.text),
              _buildDataRow(custom2Label, _custom2Controller.text),
            ],
    );
  }

  Widget _buildNotesCard() {
    final double baseSize = _font(context, 14);
    final double smallSize = _font(context, 12);
    return _buildSectionCard(
      title: "Notes & Comments",
      children: [
        if (_notesController.text.isNotEmpty) ...[
          Text(
            "Internal Notes:",
            style: TextStyle(
              fontSize: smallSize,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _notesController.text,
            style: TextStyle(fontSize: baseSize, color: Colors.black87),
          ),
          const SizedBox(height: 12),
        ],
        if (_commentsController.text.isNotEmpty) ...[
          Text(
            "Comments:",
            style: TextStyle(
              fontSize: smallSize,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _commentsController.text,
            style: TextStyle(fontSize: baseSize, color: Colors.black87),
          ),
        ],
      ],
    );
  }

  Widget _buildMetadataCard() {
    final double baseSize = _font(context, 14);
    final double smallSize = _font(context, 12);
    return _buildBaseCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Metadata",
                style: TextStyle(
                  fontSize: baseSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Created: ${_formatDate(widget.customer.dateCreated)}",
                style: TextStyle(fontSize: smallSize, color: Colors.grey[600]),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(height: 22),
              Text(
                "Modified: ${_formatDate(widget.customer.dateModified)}",
                style: TextStyle(fontSize: smallSize, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Sub-components ---

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
    VoidCallback? onEditTap,
    bool isEditing = false,
    bool isSaving = false,
  }) {
    final double baseSize = _font(context, 14);
    return _buildBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: baseSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (onEditTap != null)
                InkWell(
                  onTap: onEditTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CupertinoActivityIndicator(),
                          )
                        : Icon(
                            isEditing ? Icons.save_rounded : Icons.edit,
                            size: 18,
                            color: isEditing ? Colors.green : kPrimaryColor,
                          ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildBaseCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF7F0),
        borderRadius: BorderRadius.circular(12),
        // Adding a subtle stroke to give that "solid card" look from modern UI
        border: Border.all(color: const Color(0xFFC9B9A6), width: 0.57),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B2012).withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildIconDataRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    final double baseSize = _font(context, 14);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: baseSize,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value,
              style: TextStyle(fontSize: baseSize, color: Colors.blue),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    final double baseSize = _font(context, 14);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: baseSize, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value,
              style: TextStyle(fontSize: baseSize, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
