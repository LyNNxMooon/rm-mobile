import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/constants/colors.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_create_bloc.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_create_events.dart';
import 'package:rmstock_scanner/features/customer_lookup/presentation/BLoC/customer_create_states.dart';
import 'package:rmstock_scanner/local_db/local_db_dao.dart';
import 'package:rmstock_scanner/utils/global_var_utils.dart';

class CustomerCreateScreen extends StatefulWidget {
  const CustomerCreateScreen({super.key});

  @override
  State<CustomerCreateScreen> createState() => _CustomerCreateScreenState();
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
  
  bool _fromEomValue = false;
  bool _statusValue = true;
  bool _inactiveValue = false;
  bool _accountValue = false;
  bool _overseasValue = false;
  
  String? _barcodeValidationMessage;
  bool _isBarcodeValid = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
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
    
    super.dispose();
  }

  double _uiScale(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;
  }

  double _font(BuildContext context, double size) => size * _uiScale(context);

  void _generateBarcode() {
    context.read<CustomerCreateBloc>().add(GenerateBarcodeEvent());
  }

  void _validateBarcode(String barcode) {
    if (barcode.trim().isNotEmpty) {
      context.read<CustomerCreateBloc>().add(ValidateBarcodeEvent(barcode.trim()));
    } else {
      setState(() {
        _barcodeValidationMessage = null;
        _isBarcodeValid = false;
      });
    }
  }

  Future<void> _submitCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_barcodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or generate a barcode')),
      );
      return;
    }

    if (!_isBarcodeValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please use a valid barcode')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final shopfront = AppGlobals.instance.shopfront ?? "";
      final nextCustomerId = await LocalDbDAO.instance.getNextCustomerId(shopfront);

      final customerData = {
        "items": [
          {
            "customerId": nextCustomerId,
            "barcode": _barcodeController.text.trim(),
            "surname": _surnameController.text.trim(),
            "givenNames": _givenNamesController.text.trim(),
            "grade": int.tryParse(_gradeController.text.trim()) ?? 0,
            "company": _companyController.text.trim(),
            "position": _positionController.text.trim(),
            "salutation": _salutationController.text.trim(),
            "status": _statusValue,
            "abn": _abnController.text.trim(),
            "notes": _notesController.text.trim(),
            "comments": _commentsController.text.trim(),
            "custom1": _custom1Controller.text.trim(),
            "custom2": _custom2Controller.text.trim(),
            "inactive": _inactiveValue,
            "addr1": _addr1Controller.text.trim(),
            "addr2": _addr2Controller.text.trim(),
            "addr3": _addr3Controller.text.trim(),
            "suburb": _suburbController.text.trim(),
            "state": _stateController.text.trim(),
            "postcode": _postcodeController.text.trim(),
            "country": _countryController.text.trim(),
            "phone": _phoneController.text.trim(),
            "fax": _faxController.text.trim(),
            "mobile": _mobileController.text.trim(),
            "email": _emailController.text.trim(),
            "account": _accountValue,
            "openedId": 1,
            "ownerId": 1,
            "fromEOM": _fromEomValue,
            "days": int.tryParse(_daysController.text.trim()) ?? 0,
            "limit": double.tryParse(_limitController.text.trim()) ?? 0.0,
            "overseas": _overseasValue,
            "defaultDeliveryAddress": 1,
            "documentDeliveryType": 0,
            "addresses": [],
          }
        ]
      };

      context.read<CustomerCreateBloc>().add(CreateCustomerEvent(customerData));
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  InputDecoration _minimalInputDecoration({String? hintText}) {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: kPrimaryColor),
      ),
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[400]),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final double baseSize = _font(context, 14);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: baseSize,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(fontSize: baseSize),
            decoration: _minimalInputDecoration(),
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
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
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: kPrimaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    final double baseSize = _font(context, 16);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: baseSize,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Customer'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F8ABE), Color(0xFF05203C)],
            ),
          ),
        ),
      ),
      body: BlocListener<CustomerCreateBloc, CustomerCreateState>(
        listener: (context, state) {
          if (state is CustomerCreateSuccess) {
            setState(() {
              _isSubmitting = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.of(context).pop(true); // Return true to indicate success
          } else if (state is CustomerCreateError) {
            setState(() {
              _isSubmitting = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error)),
            );
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
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionCard(
                title: "Barcode",
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _barcodeController,
                          decoration: _minimalInputDecoration(
                            hintText: 'Enter barcode or generate one',
                          ),
                          onChanged: _validateBarcode,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Barcode is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _generateBarcode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Generate'),
                      ),
                    ],
                  ),
                  if (_barcodeValidationMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _barcodeValidationMessage!,
                      style: TextStyle(
                        color: _isBarcodeValid ? Colors.green : Colors.red,
                        fontSize: _font(context, 12),
                      ),
                    ),
                  ],
                ],
              ),
              _buildSectionCard(
                title: "Personal Details",
                children: [
                  _buildTextField(
                    label: "Salutation",
                    controller: _salutationController,
                  ),
                  _buildTextField(
                    label: "Given Names",
                    controller: _givenNamesController,
                  ),
                  _buildTextField(
                    label: "Surname *",
                    controller: _surnameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Surname is required';
                      }
                      return null;
                    },
                  ),
                  _buildTextField(
                    label: "Company",
                    controller: _companyController,
                  ),
                  _buildTextField(
                    label: "Position",
                    controller: _positionController,
                  ),
                  _buildTextField(
                    label: "Grade",
                    controller: _gradeController,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              _buildSectionCard(
                title: "Contact Information",
                children: [
                  _buildTextField(
                    label: "Phone",
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildTextField(
                    label: "Fax",
                    controller: _faxController,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildTextField(
                    label: "Mobile",
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildTextField(
                    label: "Email",
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              _buildSectionCard(
                title: "Address",
                children: [
                  _buildTextField(
                    label: "Address 1",
                    controller: _addr1Controller,
                  ),
                  _buildTextField(
                    label: "Address 2",
                    controller: _addr2Controller,
                  ),
                  _buildTextField(
                    label: "Address 3",
                    controller: _addr3Controller,
                  ),
                  _buildTextField(
                    label: "Suburb",
                    controller: _suburbController,
                  ),
                  _buildTextField(
                    label: "State",
                    controller: _stateController,
                  ),
                  _buildTextField(
                    label: "Postcode",
                    controller: _postcodeController,
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    label: "Country",
                    controller: _countryController,
                  ),
                ],
              ),
              _buildSectionCard(
                title: "Account Details",
                children: [
                  _buildSwitchRow("Account", _accountValue, (val) {
                    setState(() => _accountValue = val);
                  }),
                  _buildSwitchRow("From EOM", _fromEomValue, (val) {
                    setState(() => _fromEomValue = val);
                  }),
                  _buildTextField(
                    label: "Days",
                    controller: _daysController,
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    label: "Limit",
                    controller: _limitController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  _buildTextField(
                    label: "ABN",
                    controller: _abnController,
                  ),
                  _buildSwitchRow("Overseas", _overseasValue, (val) {
                    if (val && _abnController.text.trim().isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Cannot set Overseas while ABN is present."),
                        ),
                      );
                      return;
                    }
                    setState(() => _overseasValue = val);
                  }),
                ],
              ),
              _buildSectionCard(
                title: "Additional Information",
                children: [
                  _buildSwitchRow("Status", _statusValue, (val) {
                    setState(() => _statusValue = val);
                  }),
                  _buildSwitchRow("Inactive", _inactiveValue, (val) {
                    setState(() => _inactiveValue = val);
                  }),
                  _buildTextField(
                    label: "Notes",
                    controller: _notesController,
                    maxLines: 3,
                  ),
                  _buildTextField(
                    label: "Comments",
                    controller: _commentsController,
                    maxLines: 3,
                  ),
                  _buildTextField(
                    label: "Custom 1",
                    controller: _custom1Controller,
                  ),
                  _buildTextField(
                    label: "Custom 2",
                    controller: _custom2Controller,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitCustomer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
                        'Create Customer',
                        style: TextStyle(
                          fontSize: _font(context, 16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
