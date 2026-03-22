import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/constants/colors.dart';
import 'package:rmstock_scanner/constants/theme_colors.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_create_bloc.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_create_events.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_create_states.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_lookup_bloc.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_lookup_events.dart';
import 'package:rmstock_scanner/utils/global_var_utils.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/staff_barcode_lookup_bloc.dart';
import 'package:rmstock_scanner/entities/vos/pending_customer_creation_vo.dart';

class CustomerCreateScreen extends StatefulWidget {
  final PendingCustomerCreationVO? pendingCreation;

  const CustomerCreateScreen({super.key, this.pendingCreation});

  @override
  State<CustomerCreateScreen> createState() => _CustomerCreateScreenState();
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

class _AddressControllers {
  _AddressControllers({required this.addressNumber})
    : addr1 = TextEditingController(),
      addr2 = TextEditingController(),
      addr3 = TextEditingController(),
      suburb = TextEditingController(),
      state = TextEditingController(),
      postcode = TextEditingController(),
      country = TextEditingController(),
      phone = TextEditingController(),
      mobile = TextEditingController(),
      email = TextEditingController();

  final int addressNumber;
  final TextEditingController addr1;
  final TextEditingController addr2;
  final TextEditingController addr3;
  final TextEditingController suburb;
  final TextEditingController state;
  final TextEditingController postcode;
  final TextEditingController country;
  final TextEditingController phone;
  final TextEditingController mobile;
  final TextEditingController email;

  bool get hasAnyValue {
    return addr1.text.trim().isNotEmpty ||
        addr2.text.trim().isNotEmpty ||
        addr3.text.trim().isNotEmpty ||
        suburb.text.trim().isNotEmpty ||
        state.text.trim().isNotEmpty ||
        postcode.text.trim().isNotEmpty ||
        country.text.trim().isNotEmpty ||
        phone.text.trim().isNotEmpty ||
        mobile.text.trim().isNotEmpty ||
        email.text.trim().isNotEmpty;
  }

  Map<String, dynamic> toCreateMap({
    required int addressId,
    required int customerId,
  }) {
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
    mobile.dispose();
    email.dispose();
  }
}

class _CustomerCreateScreenState extends State<CustomerCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _barcodeController;
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
  late TextEditingController _abnController;
  late TextEditingController _notesController;
  late TextEditingController _commentsController;
  late TextEditingController _custom1Controller;
  late TextEditingController _custom2Controller;
  late TextEditingController _openedIdController;
  late TextEditingController _ownerIdController;
  late TextEditingController _defaultDeliveryAddressController;
  late TextEditingController _documentDeliveryTypeController;

  late Map<int, _AddressControllers> _secondaryAddressControllers;

  bool _fromEomValue = false;
  bool _statusValue = false;
  bool _inactiveValue = false;
  bool _accountValue = false;
  bool _overseasValue = false;

  Timer? _openedStaffLookupDebounce;
  Timer? _ownerStaffLookupDebounce;
  String? _openedStaffLookupMessage;
  String? _ownerStaffLookupMessage;
  bool _openedStaffLookupValid = false;
  bool _ownerStaffLookupValid = false;
  bool _openedStaffLookupLoading = false;
  bool _ownerStaffLookupLoading = false;
  int? _openedStaffId;
  int? _ownerStaffId;

  String? _barcodeValidationMessage;
  bool _isBarcodeValid = false;
  bool _isSubmitting = false;

  String get _customerCustom1Label => AppGlobals.instance.customerCustom1Label;
  String get _customerCustom2Label => AppGlobals.instance.customerCustom2Label;
  String get _customerStatusLabel => AppGlobals.instance.customerStatusLabel;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _populateFromPendingCreation();
    context.read<CustomerCreateBloc>().add(ResetCustomerCreateEvent());
  }

  void _initControllers() {
    _barcodeController = TextEditingController();
    _surnameController = TextEditingController();
    _givenNamesController = TextEditingController();
    _companyController = TextEditingController();
    _positionController = TextEditingController();
    _salutationController = TextEditingController();
    _gradeController = TextEditingController(text: '0');

    _phoneController = TextEditingController();
    _faxController = TextEditingController();
    _mobileController = TextEditingController();
    _emailController = TextEditingController();

    _addr1Controller = TextEditingController();
    _addr2Controller = TextEditingController();
    _addr3Controller = TextEditingController();
    _suburbController = TextEditingController();
    _stateController = TextEditingController();
    _postcodeController = TextEditingController();
    _countryController = TextEditingController();

    _limitController = TextEditingController(text: '0');
    _daysController = TextEditingController(text: '0');
    _abnController = TextEditingController();
    _notesController = TextEditingController();
    _commentsController = TextEditingController();
    _custom1Controller = TextEditingController();
    _custom2Controller = TextEditingController();
    _openedIdController = TextEditingController();
    _ownerIdController = TextEditingController();
    _defaultDeliveryAddressController = TextEditingController(text: '1');
    _documentDeliveryTypeController = TextEditingController(text: '0');

    _secondaryAddressControllers = <int, _AddressControllers>{
      2: _AddressControllers(addressNumber: 2),
      3: _AddressControllers(addressNumber: 3),
    };

    _abnController.addListener(() {
      if (_abnController.text.trim().isNotEmpty && _overseasValue) {
        setState(() {
          _overseasValue = false;
        });
      }
    });
  }

  void _populateFromPendingCreation() {
    final pending = widget.pendingCreation;
    if (pending == null) return;

    final payload = pending.payload;
    final items = payload['items'];
    if (items is! List || items.isEmpty) return;

    final raw = items.first;
    final item = raw is Map<String, dynamic>
        ? raw
        : (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});

    String getString(String key, [String altKey = '']) {
      final v = item[key] ?? (altKey.isNotEmpty ? item[altKey] : null);
      return v is String ? v.trim() : '';
    }

    int getInt(String key, [String altKey = '', int fallback = 0]) {
      final v = item[key] ?? (altKey.isNotEmpty ? item[altKey] : null);
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    double getDouble(String key, [double fallback = 0.0]) {
      final v = item[key];
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? fallback;
      return fallback;
    }

    bool getBool(String key, [bool fallback = false]) {
      final v = item[key];
      if (v is bool) return v;
      if (v is int) return v != 0;
      if (v is String) return v.toLowerCase() == 'true' || v == '1';
      return fallback;
    }

    // Personal Details
    _barcodeController.text = getString('barcode');
    _surnameController.text = getString('surname');
    _givenNamesController.text = getString('givenNames', 'given_names');
    _companyController.text = getString('company');
    _positionController.text = getString('position');
    _salutationController.text = getString('salutation');
    _gradeController.text = getInt('grade').toString();

    // Contact Information
    _phoneController.text = getString('phone');
    _faxController.text = getString('fax');
    _mobileController.text = getString('mobile');
    _emailController.text = getString('email');

    // Primary Address
    _addr1Controller.text = getString('addr1');
    _addr2Controller.text = getString('addr2');
    _addr3Controller.text = getString('addr3');
    _suburbController.text = getString('suburb');
    _stateController.text = getString('state');
    _postcodeController.text = getString('postcode');
    _countryController.text = getString('country');

    // Account Details
    _accountValue = getBool('account');
    _fromEomValue = getBool('fromEOM', false) || getBool('from_eom');
    _daysController.text = getInt('days').toString();
    _limitController.text = getDouble('limit').toString();
    _abnController.text = _formatAbn(getString('abn'));
    _overseasValue = getBool('overseas');

    // Flags
    _statusValue = getBool('status');
    _inactiveValue = getBool('inactive');

    // Notes & Custom Fields
    _notesController.text = getString('notes');
    _commentsController.text = getString('comments');
    _custom1Controller.text = getString('custom1');
    _custom2Controller.text = getString('custom2');

    // Delivery
    _defaultDeliveryAddressController.text =
        getInt('defaultDeliveryAddress', 'default_delivery_address', 1).toString();
    _documentDeliveryTypeController.text =
        getInt('documentDeliveryType', 'document_delivery_type', 0).toString();

    // Secondary Addresses
    final addresses = item['addresses'];
    if (addresses is List) {
      for (final rawAddr in addresses) {
        final addr = rawAddr is Map<String, dynamic>
            ? rawAddr
            : (rawAddr is Map
                ? Map<String, dynamic>.from(rawAddr)
                : <String, dynamic>{});
        final addrNum = addr['addressNumber'] ?? addr['address_number'];
        final int addressNumber = addrNum is int
            ? addrNum
            : (addrNum is String ? (int.tryParse(addrNum) ?? 0) : 0);

        if (addressNumber > 1 &&
            _secondaryAddressControllers.containsKey(addressNumber)) {
          final c = _secondaryAddressControllers[addressNumber]!;
          c.addr1.text = addr['addr1']?.toString().trim() ?? '';
          c.addr2.text = addr['addr2']?.toString().trim() ?? '';
          c.addr3.text = addr['addr3']?.toString().trim() ?? '';
          c.suburb.text = addr['suburb']?.toString().trim() ?? '';
          c.state.text = addr['state']?.toString().trim() ?? '';
          c.postcode.text = addr['postcode']?.toString().trim() ?? '';
          c.country.text = addr['country']?.toString().trim() ?? '';
          c.phone.text = addr['phone']?.toString().trim() ?? '';
          c.mobile.text = addr['mobile']?.toString().trim() ?? '';
          c.email.text = addr['email']?.toString().trim() ?? '';
        }
      }
    }

    // If we have a barcode from pending, mark it as valid for editing
    if (_barcodeController.text.isNotEmpty) {
      _isBarcodeValid = true;
    }
  }

  String _formatAbn(String digits) {
    final digitsOnly = digits.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < digitsOnly.length && i < 11; i++) {
      if (i == 2 || i == 5 || i == 8) {
        buffer.write('-');
      }
      buffer.write(digitsOnly[i]);
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
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
    _abnController.dispose();
    _notesController.dispose();
    _commentsController.dispose();
    _custom1Controller.dispose();
    _custom2Controller.dispose();
    _openedIdController.dispose();
    _ownerIdController.dispose();
    _defaultDeliveryAddressController.dispose();
    _documentDeliveryTypeController.dispose();

    _openedStaffLookupDebounce?.cancel();
    _ownerStaffLookupDebounce?.cancel();

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

  int _parseInt(String raw, int fallback) {
    final parsed = int.tryParse(raw.trim());
    return parsed ?? fallback;
  }

  String _abnDigitsOnly() {
    return _abnController.text.replaceAll(RegExp(r'\D'), '');
  }

  void _setOverseasValue(bool value) {
    if (value && _abnController.text.trim().isNotEmpty) {
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

  void _generateBarcode() {
    context.read<CustomerCreateBloc>().add(GenerateBarcodeEvent());
  }

  void _validateBarcode(String barcode) {
    if (barcode.trim().isNotEmpty) {
      context.read<CustomerCreateBloc>().add(
        ValidateBarcodeEvent(barcode.trim()),
      );
    } else {
      setState(() {
        _barcodeValidationMessage = null;
        _isBarcodeValid = false;
      });
    }
  }

  void _onOpenedStaffBarcodeChanged(String raw) {
    _openedStaffLookupDebounce?.cancel();
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _openedStaffLookupMessage = null;
        _openedStaffLookupValid = false;
        _openedStaffLookupLoading = false;
        _openedStaffId = null;
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
      _openedStaffLookupLoading = true;
    });

    _openedStaffLookupDebounce = Timer(
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

  Future<void> _submitCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_barcodeController.text.trim().isEmpty) {
      context.read<CustomerCreateBloc>().add(GenerateBarcodeEvent());
      final state = await context.read<CustomerCreateBloc>().stream.firstWhere(
        (state) =>
            state is BarcodeGeneratedState || state is CustomerCreateError,
      );
      if (!mounted) return;
      if (state is BarcodeGeneratedState) {
        setState(() {
          _barcodeController.text = state.barcode;
          _isBarcodeValid = true;
          _barcodeValidationMessage = "Barcode generated successfully";
        });
      } else if (state is CustomerCreateError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.error)));
        return;
      }
    }

    if (_barcodeController.text.trim().isNotEmpty && !_isBarcodeValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please use a valid barcode')),
      );
      return;
    }

    final openedBarcode = _openedIdController.text.trim();
    if (openedBarcode.isNotEmpty && !_openedStaffLookupValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid opened by staff barcode'),
        ),
      );
      return;
    }

    final ownerBarcode = _ownerIdController.text.trim();
    if (ownerBarcode.isNotEmpty && !_ownerStaffLookupValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid owner staff barcode'),
        ),
      );
      return;
    }

    final List<CustomerCreateAddressInput> secondaryAddresses =
        _secondaryAddressControllers.values
            .map(
              (address) => CustomerCreateAddressInput(
                addressNumber: address.addressNumber,
                addr1: address.addr1.text.trim(),
                addr2: address.addr2.text.trim(),
                addr3: address.addr3.text.trim(),
                suburb: address.suburb.text.trim(),
                state: address.state.text.trim(),
                postcode: address.postcode.text.trim(),
                country: address.country.text.trim(),
                phone: address.phone.text.trim(),
                mobile: address.mobile.text.trim(),
                email: address.email.text.trim(),
              ),
            )
            .toList();

    final form = CustomerCreateFormInput(
      barcode: _barcodeController.text.trim(),
      surname: _surnameController.text.trim(),
      givenNames: _givenNamesController.text.trim(),
      grade: _parseInt(_gradeController.text, 0),
      company: _companyController.text.trim(),
      position: _positionController.text.trim(),
      salutation: _salutationController.text.trim(),
      status: _statusValue,
      inactive: _inactiveValue,
      account: _accountValue,
      overseas: _overseasValue,
      fromEom: _fromEomValue,
      abn: _abnDigitsOnly(),
      notes: _notesController.text.trim(),
      comments: _commentsController.text.trim(),
      custom1: _custom1Controller.text.trim(),
      custom2: _custom2Controller.text.trim(),
      addr1: _addr1Controller.text.trim(),
      addr2: _addr2Controller.text.trim(),
      addr3: _addr3Controller.text.trim(),
      suburb: _suburbController.text.trim(),
      state: _stateController.text.trim(),
      postcode: _postcodeController.text.trim(),
      country: _countryController.text.trim(),
      phone: _phoneController.text.trim(),
      fax: _faxController.text.trim(),
      mobile: _mobileController.text.trim(),
      email: _emailController.text.trim(),
      openedStaffId: _openedStaffId,
      ownerStaffId: _ownerStaffId,
      days: _parseInt(_daysController.text, 0),
      limit: double.tryParse(_limitController.text.trim()) ?? 0.0,
      defaultDeliveryAddress: _parseInt(
        _defaultDeliveryAddressController.text,
        1,
      ),
      documentDeliveryType: _parseInt(
        _documentDeliveryTypeController.text,
        0,
      ),
      secondaryAddresses: secondaryAddresses,
    );

    context.read<CustomerCreateBloc>().add(
      SubmitCustomerCreateFormEvent(form),
    );
  }

  // --- UI Styling Components matching Details Screen ---

  InputDecoration _minimalInputDecoration({String? hintText}) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final Color borderColor =
      isDark ? Colors.white38 : Colors.grey.shade400;
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kPrimaryColor, width: 1.2),
      ),
      hintText: hintText,
      hintStyle: TextStyle(
        color: isDark ? colors.onSurfaceMuted : Colors.grey[400],
      ),
    );
  }

  Widget _buildBaseCard({required Widget child}) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceAlt : const Color(0xFFFBF7F0),
        borderRadius: BorderRadius.circular(12),
        // Adding a subtle stroke to give that "solid card" look from modern UI
        border: Border.all(
          color: isDark ? Colors.white54 : const Color(0xFFC9B9A6),
          width: 0.57,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? colors.cardShadow
                : const Color(0xFF2B2012).withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final double baseSize = _font(context, 14);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildBaseCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: baseSize,
                fontWeight: FontWeight.bold,
                color: isDark ? colors.onSurface : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildEditRow(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    String? hintText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final double baseSize = _font(context, 14);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: baseSize,
                  color: isDark ? colors.onSurfaceMuted : Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              style: TextStyle(
                fontSize: baseSize,
                color: isDark ? colors.onSurface : Colors.black87,
              ),
              decoration: _minimalInputDecoration(hintText: hintText),
              validator: validator,
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
    );
  }

  Widget _buildSwitchRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged, {
    bool enabled = true,
  }) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final double baseSize = _font(context, 14);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: baseSize,
              color: isDark ? colors.onSurfaceMuted : Colors.grey[600],
            ),
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
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final double baseSize = _font(context, 14);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: baseSize,
                  color: isDark ? colors.onSurfaceMuted : Colors.grey[600],
                ),
              ),
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
              style: TextStyle(
                fontSize: baseSize,
                color: isDark ? colors.onSurface : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffLookupRow({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required String? message,
    required bool isValid,
    required bool isLoading,
  }) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final double baseSize = _font(context, 14);
    final double smallSize = _font(context, 12);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: baseSize,
                      color: isDark ? colors.onSurfaceMuted : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.text,
                  style: TextStyle(
                    fontSize: baseSize,
                    color: isDark ? colors.onSurface : Colors.black87,
                  ),
                  decoration: _minimalInputDecoration(),
                  onChanged: onChanged,
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
                    ? (isDark ? colors.onSurfaceMuted : Colors.grey[600])
                    : (isValid
                        ? Colors.green[700]
                        : Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildSecondaryAddressEditors() {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final double baseSize = _font(context, 13);
    final List<Widget> widgets = [];

    for (final entry in _secondaryAddressControllers.entries) {
      final int addressNumber = entry.key;
      final _AddressControllers address = entry.value;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            "Address $addressNumber",
            style: TextStyle(
              fontSize: baseSize,
              fontWeight: FontWeight.bold,
              color: isDark ? colors.onSurface : Colors.black87,
            ),
          ),
        ),
      );
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

  Widget _buildLongActionButton({
    required String label,
    required VoidCallback? onTap,
  }) {
    final colors = context.appColors;
    final double baseSize = _font(context, 14);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: colors.onHero,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: baseSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    return MultiBlocListener(
      listeners: [
        BlocListener<CustomerCreateBloc, CustomerCreateState>(
          listener: (context, state) async {
            if (state is CustomerCreateLoading) {
              setState(() {
                _isSubmitting = true;
              });
            } else if (state is CustomerCreateSuccess) {
              setState(() {
                _isSubmitting = false;
              });
              final pending = widget.pendingCreation;
              if (pending != null) {
                context.read<PendingCustomerUpdatesBloc>().add(
                  DeletePendingCustomerCreationEvent(id: pending.id),
                );
              }
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
              context.read<PendingCustomerUpdatesBloc>().add(
                LoadPendingCustomerUpdatesCountEvent(),
              );
              context.read<FetchCustomerBloc>().add(
                StartCustomerSyncEvent(ipAddress: ""),
              );
              Navigator.of(context).pop(true);
            } else if (state is CustomerCreateError) {
              setState(() {
                _isSubmitting = false;
              });
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.error)));
            } else if (state is BarcodeValidationState) {
              setState(() {
                _barcodeValidationMessage = state.message;
                _isBarcodeValid = state.isValid;
              });
            } else if (state is BarcodeGeneratedState) {
              setState(() {
                _barcodeController.text = state.barcode;
                _isBarcodeValid = true;
                _barcodeValidationMessage = "Barcode generated successfully";
              });
            }
          },
        ),
        BlocListener<StaffBarcodeLookupBloc, StaffBarcodeLookupState>(
          listener: (context, state) {
            if (!mounted) return;
            if (state.target == StaffBarcodeTarget.openedBy) {
              setState(() {
                _openedStaffLookupLoading = state.isLoading;
                _openedStaffLookupValid = state.isValid;
                _openedStaffLookupMessage = state.message;
                _openedStaffId = state.staffId;
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
      child: Scaffold(
        backgroundColor: isDark ? colors.bg : const Color(0xFFF3EFE8),
        body: Stack(
          children: [
            // Background Gradient Container (Top Half)
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                gradient: isDark ? colors.heroGradient : kGColor,
              ),
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
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            color: isDark ? Colors.white : Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            "Back",
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        ),
                        Text(
                          "Create Customer",
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 80),
                      ],
                    ),
                  ),

                  // Scrollable Form Content
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                        child: Column(
                          children: [
                            _buildSectionCard(
                              title: "Barcode",
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _barcodeController,
                                        style: TextStyle(
                                          fontSize: _font(context, 14),
                                          color: isDark
                                              ? colors.onSurface
                                              : Colors.black87,
                                        ),
                                        decoration: _minimalInputDecoration(
                                          hintText: 'Enter a barcode (Leave empty to auto-generate)',
                                        ).copyWith(
                                          hintStyle: TextStyle(
                                            color: isDark
                                                ? colors.onSurfaceMuted
                                                : Colors.black,
                                          ),
                                        ),
                                        onChanged: _validateBarcode,
                                        onEditingComplete: () {
                                          final trimmedValue =
                                              _barcodeController.text.trim();
                                          if (_barcodeController.text !=
                                              trimmedValue) {
                                            _barcodeController
                                                .value = _barcodeController
                                                .value
                                                .copyWith(
                                                  text: trimmedValue,
                                                  selection:
                                                      TextSelection.collapsed(
                                                        offset:
                                                            trimmedValue.length,
                                                      ),
                                                );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                if (_barcodeValidationMessage != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _barcodeValidationMessage!,
                                    style: TextStyle(
                                      color: _isBarcodeValid
                                          ? Colors.green
                                          : Colors.red,
                                      fontSize: _font(context, 12),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            _buildSectionCard(
                              title: "Personal Details",
                              children: [
                                _buildEditRow(
                                  "Salutation",
                                  _salutationController,
                                ),
                                _buildEditRow(
                                  "Given Names",
                                  _givenNamesController,
                                ),
                                _buildEditRow(
                                  "Surname *",
                                  _surnameController,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Surname is required';
                                    }
                                    return null;
                                  },
                                ),
                                _buildEditRow("Company", _companyController),
                                _buildEditRow("Position", _positionController),
                                _buildDropdownRow<int>(
                                  label: "Grade",
                                  value: _parseInt(_gradeController.text, 0),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 0,
                                      child: Text("Default"),
                                    ),
                                    DropdownMenuItem(
                                      value: 1,
                                      child: Text("A"),
                                    ),
                                    DropdownMenuItem(
                                      value: 2,
                                      child: Text("B"),
                                    ),
                                    DropdownMenuItem(
                                      value: 3,
                                      child: Text("C"),
                                    ),
                                    DropdownMenuItem(
                                      value: 4,
                                      child: Text("D"),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _gradeController.text = value.toString();
                                    });
                                  },
                                ),
                              ],
                            ),

                            _buildSectionCard(
                              title: "Contact Information",
                              children: [
                                _buildEditRow(
                                  "Phone",
                                  _phoneController,
                                  keyboardType: TextInputType.phone,
                                ),
                                _buildEditRow(
                                  "Fax",
                                  _faxController,
                                  keyboardType: TextInputType.phone,
                                ),
                                _buildEditRow(
                                  "Mobile",
                                  _mobileController,
                                  keyboardType: TextInputType.phone,
                                ),
                                _buildEditRow(
                                  "Email",
                                  _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ],
                            ),

                            _buildSectionCard(
                              title: "Address",
                              children: [
                                _buildEditRow("Address 1", _addr1Controller),
                                _buildEditRow("Address 2", _addr2Controller),
                                _buildEditRow("Address 3", _addr3Controller),
                                _buildEditRow("Suburb", _suburbController),
                                _buildEditRow("State", _stateController),
                                _buildEditRow(
                                  "Postcode",
                                  _postcodeController,
                                  keyboardType: TextInputType.number,
                                ),
                                _buildEditRow("Country", _countryController),
                                const SizedBox(height: 8),
                                Divider(
                                  height: 1,
                                  color: isDark
                                      ? colors.divider
                                      : const Color(0xFFEEEEEE),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Secondary Addresses",
                                  style: TextStyle(
                                    fontSize: _font(context, 14),
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? colors.onSurface
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._buildSecondaryAddressEditors(),
                              ],
                            ),

                            _buildSectionCard(
                              title: "Account Details",
                              children: [
                                _buildSwitchRow("Account", _accountValue, (
                                  val,
                                ) {
                                  setState(() => _accountValue = val);
                                }),
                                _buildSwitchRow("From EOM", _fromEomValue, (
                                  val,
                                ) {
                                  setState(() => _fromEomValue = val);
                                }),
                                const SizedBox(height: 8),
                                _buildEditRow(
                                  "Days",
                                  _daysController,
                                  keyboardType: TextInputType.number,
                                ),
                                _buildEditRow(
                                  "Limit",
                                  _limitController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                                _buildStaffLookupRow(
                                  label: "Opened By (Staff No)",
                                  controller: _openedIdController,
                                  onChanged: _onOpenedStaffBarcodeChanged,
                                  message: _openedStaffLookupMessage,
                                  isValid: _openedStaffLookupValid,
                                  isLoading: _openedStaffLookupLoading,
                                ),
                                _buildStaffLookupRow(
                                  label: "Owner Account (Staff No)",
                                  controller: _ownerIdController,
                                  onChanged: _onOwnerStaffBarcodeChanged,
                                  message: _ownerStaffLookupMessage,
                                  isValid: _ownerStaffLookupValid,
                                  isLoading: _ownerStaffLookupLoading,
                                ),
                                _buildEditRow(
                                  "ABN",
                                  _abnController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [_AbnInputFormatter()],
                                ),
                                _buildSwitchRow("Overseas", _overseasValue, (
                                  val,
                                ) {
                                  _setOverseasValue(val);
                                }),
                              ],
                            ),

                            _buildSectionCard(
                              title: "Additional Information",
                              children: [
                                _buildSwitchRow(
                                  _customerStatusLabel,
                                  _statusValue,
                                  (val) {
                                    setState(() => _statusValue = val);
                                  },
                                ),
                                _buildSwitchRow("Inactive", _inactiveValue, (
                                  val,
                                ) {
                                  setState(() => _inactiveValue = val);
                                }),
                                const SizedBox(height: 8),
                                _buildDropdownRow<int>(
                                  label: "Default Delivery",
                                  value: _parseInt(
                                    _defaultDeliveryAddressController.text,
                                    1,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 1,
                                      child: Text("Addr1"),
                                    ),
                                    DropdownMenuItem(
                                      value: 2,
                                      child: Text("Addr2"),
                                    ),
                                    DropdownMenuItem(
                                      value: 3,
                                      child: Text("Addr3"),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _defaultDeliveryAddressController.text =
                                          value.toString();
                                    });
                                  },
                                ),
                                _buildDropdownRow<int>(
                                  label: "Documents",
                                  value: _parseInt(
                                    _documentDeliveryTypeController.text,
                                    0,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 0,
                                      child: Text("Print"),
                                    ),
                                    DropdownMenuItem(
                                      value: 1,
                                      child: Text("Email"),
                                    ),
                                    DropdownMenuItem(
                                      value: 2,
                                      child: Text("Print & Email"),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _documentDeliveryTypeController.text =
                                          value.toString();
                                    });
                                  },
                                ),
                                _buildEditRow(
                                  "Notes",
                                  _notesController,
                                  maxLines: 3,
                                ),
                                _buildEditRow(
                                  "Comments",
                                  _commentsController,
                                  maxLines: 3,
                                ),
                                _buildEditRow(
                                  _customerCustom1Label,
                                  _custom1Controller,
                                ),
                                _buildEditRow(
                                  _customerCustom2Label,
                                  _custom2Controller,
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            _buildLongActionButton(
                              label: "Create Customer",
                              onTap: _isSubmitting ? null : _submitCustomer,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
