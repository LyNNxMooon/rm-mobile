import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alert_info/alert_info.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../entities/vos/customer_vo.dart';
import '../../../../utils/responsive_utils.dart';
import '../BLoC/sales_bloc.dart';
import '../../../../entities/vos/delivery_info_vo.dart';
import 'customer_selection_screen.dart';

/// Delivery Details Screen for adding delivery information to a sale
class DeliveryDetailsScreen extends StatefulWidget {
  final CustomerVO? initialCustomer;
  final DeliveryInfoVO? existingDelivery;

  const DeliveryDetailsScreen({
    super.key,
    this.initialCustomer,
    this.existingDelivery,
  });

  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  // Controllers
  final TextEditingController _customerSearchController =
      TextEditingController();
  final TextEditingController _attentionController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _address3Controller = TextEditingController();
  final TextEditingController _suburbController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // State
  CustomerVO? _selectedCustomer;
  String _deliverTo =
      "Customer Address"; // "Customer Address" or "Other Address"
  String _location = "Address 1"; // "Address 1", "Address 2", "Address 3"
  DateTime? _deliveryDate;
  TimeOfDay? _deliveryTime;
  bool _isSearchingCustomer = false;
  bool _isLoadingCustomer = false;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.initialCustomer;

    // If we have existing delivery info, restore it
    if (widget.existingDelivery != null) {
      _restoreDeliveryInfo(widget.existingDelivery!);
    } else if (_selectedCustomer != null) {
      // Auto-populate from customer's primary address
      _populateFromCustomer(_selectedCustomer!, "Address 1");
    }
  }

  @override
  void dispose() {
    _customerSearchController.dispose();
    _attentionController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _address3Controller.dispose();
    _suburbController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _restoreDeliveryInfo(DeliveryInfoVO info) {
    _attentionController.text = info.recipientName;
    _phoneController.text = info.phone.isNotEmpty ? info.phone : info.mobile;
    _address1Controller.text = info.addr1;
    _address2Controller.text = info.addr2;
    _address3Controller.text = info.addr3;
    _suburbController.text = info.suburb;
    _stateController.text = info.state;
    _postcodeController.text = info.postcode;
    _countryController.text = info.country;
    _notesController.text = info.notes;
    _deliveryDate = info.deliveryDate;
    _deliveryTime = info.deliveryDate != null
      ? TimeOfDay.fromDateTime(info.deliveryDate!)
      : null;

    // Restore address source
    if (info.addressSource == "other") {
      _deliverTo = "Other Address";
    } else {
      _deliverTo = "Customer Address";
      if (info.addressSource == "address_2") {
        _location = "Address 2";
      } else if (info.addressSource == "address_3") {
        _location = "Address 3";
      } else {
        _location = "Address 1";
      }
    }
  }

  void _populateFromCustomer(CustomerVO customer, String location) {
    setState(() {
      _location = location;
    });

    // Set attention/recipient name
    final nameParts = <String>[];
    if (customer.givenNames.isNotEmpty) nameParts.add(customer.givenNames);
    if (customer.surname.isNotEmpty) nameParts.add(customer.surname);
    _attentionController.text = nameParts.isEmpty
        ? customer.company
        : nameParts.join(' ');

    if (location == "Address 1") {
      _phoneController.text = customer.phone.isNotEmpty
          ? customer.phone
          : customer.mobile;
      _address1Controller.text = customer.addr1;
      _address2Controller.text = customer.addr2;
      _address3Controller.text = customer.addr3;
      _suburbController.text = customer.suburb;
      _stateController.text = customer.state;
      _postcodeController.text = customer.postcode;
      _countryController.text = customer.country;
    } else {
      // Find the address from addresses list
      final addressNum = location == "Address 2" ? 2 : 3;
      final address = customer.addresses
          .where((a) => a.addressNumber == addressNum)
          .firstOrNull;

      if (address != null) {
        _phoneController.text = address.phone.isNotEmpty
            ? address.phone
            : address.mobile;
        _address1Controller.text = address.addr1;
        _address2Controller.text = address.addr2;
        _address3Controller.text = address.addr3;
        _suburbController.text = address.suburb;
        _stateController.text = address.state;
        _postcodeController.text = address.postcode;
        _countryController.text = address.country;
      } else {
        // Address not found, clear fields
        _clearAddressFields();
      }
    }
  }

  void _clearAddressFields() {
    _phoneController.clear();
    _address1Controller.clear();
    _address2Controller.clear();
    _address3Controller.clear();
    _suburbController.clear();
    _stateController.clear();
    _postcodeController.clear();
    _countryController.clear();
  }

  void _clearAllFields() {
    _attentionController.clear();
    _clearAddressFields();
  }

  String _getAddressSource() {
    if (_deliverTo == "Other Address") return "other";
    if (_location == "Address 2") return "address_2";
    if (_location == "Address 3") return "address_3";
    return "primary";
  }

  DeliveryInfoVO _buildDeliveryInfo() {
    // Combine date and time into a single DateTime
    DateTime? combinedDateTime;
    if (_deliveryDate != null) {
      if (_deliveryTime != null) {
        combinedDateTime = DateTime(
          _deliveryDate!.year,
          _deliveryDate!.month,
          _deliveryDate!.day,
          _deliveryTime!.hour,
          _deliveryTime!.minute,
        );
      } else {
        combinedDateTime = _deliveryDate;
      }
    }
    
    return DeliveryInfoVO(
      customerId: _selectedCustomer?.customerId,
      recipientName: _attentionController.text.trim(),
      phone: _phoneController.text.trim(),
      mobile: '',
      email: '',
      addr1: _address1Controller.text.trim(),
      addr2: _address2Controller.text.trim(),
      addr3: _address3Controller.text.trim(),
      suburb: _suburbController.text.trim(),
      state: _stateController.text.trim(),
      postcode: _postcodeController.text.trim(),
      country: _countryController.text.trim(),
      deliveryMethod: 'Standard',
      deliveryDate: combinedDateTime,
      notes: _notesController.text.trim(),
      addressSource: _getAddressSource(),
    );
  }

  String _getCustomerDisplayText(CustomerVO customer) {
    final nameParts = <String>[];
    if (customer.givenNames.isNotEmpty) nameParts.add(customer.givenNames);
    if (customer.surname.isNotEmpty) nameParts.add(customer.surname);
    final name = nameParts.isEmpty ? customer.company : nameParts.join(' ');
    return "${customer.barcode}    $name";
  }

  void _onCustomerSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => _isLoadingCustomer = true);

    try {
        final result = await context
          .read<SalesBloc>()
          .searchCustomer(query.trim());

      if (!mounted) return;
      setState(() => _isLoadingCustomer = false);

      if (result.notFound) {
        AlertInfo.show(
          context: context,
          text: "No customer found matching '$query'",
          typeInfo: TypeInfo.error,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? context.appColors.surface
              : kSecondaryColor,
          iconColor: kErrorColor,
          textColor: kErrorColor,
          position: MessagePosition.top,
          padding: 70,
        );
      } else if (result.duplicates.isNotEmpty) {
        // Navigate to customer selection screen
        final selected = await Navigator.push<CustomerVO>(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerSelectionScreen(matches: result.duplicates),
          ),
        );
        if (selected != null && mounted) {
          setState(() {
            _selectedCustomer = selected;
            _isSearchingCustomer = false;
            _customerSearchController.clear();
          });
          _populateFromCustomer(selected, _location);
        }
      } else if (result.customer != null) {
        // Single match found
        setState(() {
          _selectedCustomer = result.customer;
          _isSearchingCustomer = false;
          _customerSearchController.clear();
        });
        _populateFromCustomer(result.customer!, _location);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCustomer = false);
      AlertInfo.show(
        context: context,
        text: "Error searching customer: $e",
        typeInfo: TypeInfo.error,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? context.appColors.surface
            : kSecondaryColor,
        iconColor: kErrorColor,
        textColor: kErrorColor,
        position: MessagePosition.top,
        padding: 70,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.appColors;
    final isTablet = context.isTablet;

    return Scaffold(
      backgroundColor: isDark ? colors.bg : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Delivery Details",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: isDark ? colors.surfaceAlt : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- TOP ROUTING SECTION ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? colors.surfaceAlt : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Deliver To dropdown
                        _buildDropdownRow(
                          label: "Deliver to",
                          value: _deliverTo,
                          items: const ["Customer Address", "Other Address"],
                          onChanged: (val) {
                            setState(() {
                              _deliverTo = val!;
                              if (val == "Other Address") {
                                _clearAllFields();
                              } else if (_selectedCustomer != null) {
                                _populateFromCustomer(
                                  _selectedCustomer!,
                                  _location,
                                );
                              }
                            });
                          },
                          isDark: isDark,
                          colors: colors,
                          isTablet: isTablet,
                        ),
                        const SizedBox(height: 12),

                        // Customer field (disabled when "Other Address")
                        Row(
                          children: [
                            SizedBox(
                              width: isTablet ? 120 : 80,
                              child: Text(
                                "Customer",
                                style: TextStyle(
                                  color: _deliverTo == "Other Address"
                                      ? colors.onSurfaceMuted.withOpacity(0.5)
                                      : colors.onSurfaceMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              child: _isSearchingCustomer
                                  ? _buildCustomerSearchField(isDark, colors)
                                  : _buildCustomerDisplayField(isDark, colors),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Location dropdown (disabled when "Other Address")
                        _buildDropdownRow(
                          label: "Location",
                          value: _location,
                          items: const ["Address 1", "Address 2", "Address 3"],
                          onChanged: _deliverTo == "Other Address"
                              ? null
                              : (val) {
                                  if (_selectedCustomer != null) {
                                    _populateFromCustomer(
                                      _selectedCustomer!,
                                      val!,
                                    );
                                  } else {
                                    setState(() => _location = val!);
                                  }
                                },
                          isDark: isDark,
                          colors: colors,
                          enabled: _deliverTo != "Other Address",
                          isTablet: isTablet,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- DETAILS SECTION ---
                  Text(
                    "Details",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? colors.surfaceAlt : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildFieldRow(
                          "Attention",
                          _attentionController,
                          isDark,
                          colors,
                          isTablet: isTablet,
                        ),
                        const SizedBox(height: 12),
                        _buildFieldRow(
                          "Address",
                          _address1Controller,
                          isDark,
                          colors,
                          isTablet: isTablet,
                        ),
                        const SizedBox(height: 6),
                        _buildFieldRow(
                          "",
                          _address2Controller,
                          isDark,
                          colors,
                          isTablet: isTablet,
                        ),
                        const SizedBox(height: 6),
                        _buildFieldRow(
                          "",
                          _address3Controller,
                          isDark,
                          colors,
                          isTablet: isTablet,
                        ),

                        const SizedBox(height: 16),

                        // Suburb
                        _buildFieldRow(
                          "Suburb",
                          _suburbController,
                          isDark,
                          colors,
                          isTablet: isTablet,
                        ),
                        const SizedBox(height: 12),

                        // State & Post Code Row
                        Row(
                          children: [
                            Expanded(
                              flex: 11,
                              child: _buildFieldRow(
                                "State",
                                _stateController,
                                isDark,
                                colors,
                                isTablet: isTablet,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 7,
                              child: _buildFieldRow(
                                "Post\nCode",
                                _postcodeController,
                                isDark,
                                colors,
                                labelWidth: isTablet ? 45.0 : 35.0,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Phone & Country Row
                        Row(
                          children: [
                            Expanded(
                              flex: 11,
                              child: _buildFieldRow(
                                "Phone",
                                _phoneController,
                                isDark,
                                colors,
                                isTablet: isTablet,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 7,
                              child: _buildFieldRow(
                                "Country",
                                _countryController,
                                isDark,
                                colors,
                                labelWidth: isTablet ? 45.0 : 35.0,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Divider(
                          color: isDark ? Colors.white12 : Colors.grey.shade200,
                        ),
                        const SizedBox(height: 8),

                        // Date & Time Row
                        Row(
                          children: [
                            Expanded(
                              flex: 11,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: isTablet ? 120.0 : 80.0,
                                    child: Text(
                                      "Delivery Date",
                                      style: TextStyle(
                                        color: colors.onSurfaceMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildDateTimePicker(
                                      isDate: true,
                                      isDark: isDark,
                                      colors: colors,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 7,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: isTablet ? 45.0 : 35.0,
                                    child: Text(
                                      "Time",
                                      style: TextStyle(
                                        color: colors.onSurfaceMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildDateTimePicker(
                                      isDate: false,
                                      isDark: isDark,
                                      colors: colors,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        _buildFieldRow(
                          "Notes",
                          _notesController,
                          isDark,
                          colors,
                          isTablet: isTablet,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // --- BOTTOM ACTION BAR ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? colors.surfaceAlt : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        // Build delivery info and return to sales screen
                        final deliveryInfo = _buildDeliveryInfo();
                        Navigator.pop(context, deliveryInfo);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Commit",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER BUILDERS ---

  Widget _buildCustomerSearchField(bool isDark, AppThemeColors colors) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _customerSearchController,
        autofocus: true,
        scrollPhysics: const ClampingScrollPhysics(),
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: "Search customer...",
          hintStyle: TextStyle(color: colors.onSurfaceMuted, fontSize: 13),
          filled: true,
          fillColor: isDark ? const Color(0xFF1E2733) : Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 0,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => _onCustomerSearch(_customerSearchController.text),
                child: Container(
                  width: 36,
                  alignment: Alignment.center,
                  child: Icon(Icons.search, size: 18, color: kPrimaryColor),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _isSearchingCustomer = false;
                    _customerSearchController.clear();
                  });
                },
                child: Container(
                  width: 36,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: colors.onSurfaceMuted,
                  ),
                ),
              ),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: kPrimaryColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: kPrimaryColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: kPrimaryColor, width: 2),
          ),
        ),
        onSubmitted: _onCustomerSearch,
      ),
    );
  }

  Widget _buildCustomerDisplayField(bool isDark, AppThemeColors colors) {
    final isDisabled = _deliverTo == "Other Address";
    final displayText = _selectedCustomer != null
        ? _getCustomerDisplayText(_selectedCustomer!)
        : "";

    return InkWell(
      onTap: isDisabled
          ? null
          : () {
              setState(() => _isSearchingCustomer = true);
            },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDisabled
              ? (isDark ? Colors.white10 : Colors.grey.shade200)
              : (isDark ? const Color(0xFF1E2733) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  color: isDisabled
                      ? colors.onSurfaceMuted.withOpacity(0.5)
                      : (isDark ? Colors.white : Colors.black87),
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isDisabled)
              Icon(Icons.search, size: 16, color: colors.onSurfaceMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownRow({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?)? onChanged,
    required bool isDark,
    required AppThemeColors colors,
    bool enabled = true,
    bool isTablet = false,
  }) {
    final labelWidth = isTablet ? 120.0 : 80.0;
    return Row(
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: TextStyle(
              color: enabled
                  ? colors.onSurfaceMuted
                  : colors.onSurfaceMuted.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: enabled
                  ? (isDark ? const Color(0xFF1E2733) : Colors.grey.shade50)
                  : (isDark ? Colors.white10 : Colors.grey.shade200),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: isDark ? colors.surfaceAlt : Colors.white,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: enabled
                      ? colors.onSurfaceMuted
                      : colors.onSurfaceMuted.withOpacity(0.5),
                ),
                style: TextStyle(
                  color: enabled
                      ? (isDark ? Colors.white : Colors.black87)
                      : colors.onSurfaceMuted.withOpacity(0.5),
                  fontSize: 14,
                ),
                onChanged: enabled ? onChanged : null,
                items: items
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldRow(
    String label,
    TextEditingController controller,
    bool isDark,
    AppThemeColors colors, {
    bool isTablet = false,
    double? labelWidth,
  }) {
    final effectiveLabelWidth = labelWidth ?? (isTablet ? 120.0 : 80.0);
    return Row(
      children: [
        if (label.isNotEmpty)
          SizedBox(
            width: effectiveLabelWidth,
            child: Text(
              label,
              style: TextStyle(color: colors.onSurfaceMuted, fontSize: 13),
            ),
          )
        else
          SizedBox(width: effectiveLabelWidth),
        Expanded(
          child: _buildTextField(
            controller: controller,
            hint: "",
            isDark: isDark,
            colors: colors,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    required AppThemeColors colors,
    bool readOnly = false,
  }) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        scrollPhysics: const ClampingScrollPhysics(),
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: readOnly
              ? (isDark ? Colors.white10 : Colors.grey.shade200)
              : (isDark ? const Color(0xFF1E2733) : Colors.grey.shade50),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: kPrimaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker({
    required bool isDate,
    required bool isDark,
    required AppThemeColors colors,
  }) {
    final displayFormat = isDate
        ? (_deliveryDate != null
              ? "${_deliveryDate!.day}/${_deliveryDate!.month}/${_deliveryDate!.year}"
              : "")
        : (_deliveryTime != null ? _deliveryTime!.format(context) : "");

    return InkWell(
      onTap: () async {
        if (isDate) {
          final date = await showDatePicker(
            context: context,
            initialDate: _deliveryDate ?? DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (date != null) setState(() => _deliveryDate = date);
        } else {
          final time = await showTimePicker(
            context: context,
            initialTime: _deliveryTime ?? TimeOfDay.now(),
          );
          if (time != null) setState(() => _deliveryTime = time);
        }
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2733) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Text(
                  displayFormat,
                  softWrap: false,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: colors.onSurfaceMuted,
            ),
          ],
        ),
      ),
    );
  }
}
