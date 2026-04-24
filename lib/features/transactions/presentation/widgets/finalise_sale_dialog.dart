import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../utils/formatting_utils.dart';
import '../../../../entities/vos/customer_vo.dart';
import '../../../../utils/responsive_utils.dart';

/// Result from finalise sale dialog
enum FinaliseSaleResult { email, save, cancelled }

/// Data returned when email option is selected
class FinaliseSaleEmailData {
  final String email;

  FinaliseSaleEmailData({required this.email});
}

/// Data returned with payment amounts
class FinaliseSalePaymentData {
  final Map<String, double> paymentAmounts;

  FinaliseSalePaymentData({required this.paymentAmounts});
}

/// Dialog for finalising a sale - offers Payment selection, then Email or Save options
class FinaliseSaleDialog extends StatefulWidget {
  final CustomerVO? customer;
  final double total;
  final Map<String, double> initialPaymentAmounts;
  final bool promptForEmail;
  final bool showPayments;
  final String title;

  const FinaliseSaleDialog({
    super.key,
    this.customer,
    required this.total,
    this.initialPaymentAmounts = const {},
    this.promptForEmail = true,
    this.showPayments = true,
    this.title = 'Sale',
  });

  /// Shows the dialog and returns the result
  static Future<({
    FinaliseSaleResult result,
    FinaliseSaleEmailData? emailData,
    FinaliseSalePaymentData? paymentData,
  })?>
  show({
    required BuildContext context,
    CustomerVO? customer,
    required double total,
    Map<String, double> initialPaymentAmounts = const {},
    bool promptForEmail = true,
    bool showPayments = true,
    String title = 'Sale',
  }) {
    return showDialog<({
      FinaliseSaleResult result,
      FinaliseSaleEmailData? emailData,
      FinaliseSalePaymentData? paymentData,
    })>(
      context: context,
      barrierDismissible: false,
      builder: (_) => FinaliseSaleDialog(
        customer: customer,
        total: total,
        initialPaymentAmounts: initialPaymentAmounts,
        promptForEmail: promptForEmail,
        showPayments: showPayments,
        title: title,
      ),
    );
  }

  @override
  State<FinaliseSaleDialog> createState() => _FinaliseSaleDialogState();
}

class _FinaliseSaleDialogState extends State<FinaliseSaleDialog> {
  // 0 = payments, 1 = commit options, 2 = email form, 3 = receipt
  late int _currentStep;
  late TextEditingController _emailController;
  late Map<String, double> _paymentAmounts;
  FinaliseSaleResult? _finalResult;
  FinaliseSaleEmailData? _finalEmailData;
  bool _needsInitialConfirmation = false;

  final List<String> _paymentMethods = [
    "Cash",
    "EFTPOS",
    "Cheque",
    "Bank Card",
    "Master Card",
    "Visa",
    "Amex",
    "Diners",
  ];

  /// Shows confirmation dialog when promptForEmail is false
  Future<bool> _showCommitConfirmation(AppThemeColors colors, bool isDark) async {
    final change = _balanceOrChange >= 0 ? _balanceOrChange : 0.0;
    final isTablet = context.isTablet;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 80 : 24,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 450 : double.infinity,
          ),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2733) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      color: kPrimaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "RetailManager Question",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Commit Transaction?",
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Cash Change",
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                FormattingUtils.formatCurrencyWithDecimals(change, 2),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryColor,
                      side: const BorderSide(color: kPrimaryColor),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "No",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Yes",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.customer?.email ?? '',
    );
    _paymentAmounts = Map.from(widget.initialPaymentAmounts);
    
    // Determine starting step
    if (widget.showPayments) {
      // Sales: start at payments step
      _currentStep = 0;
    } else if (widget.promptForEmail) {
      // Non-Sales with email prompt: start at commit options
      _currentStep = 1;
    } else {
      // Non-Sales without email prompt: show confirmation first (step 4), then receipt
      _currentStep = 4; // Pending confirmation step
      _finalResult = FinaliseSaleResult.save;
      _finalEmailData = null;
      _needsInitialConfirmation = true;
    }
    
    // Show initial confirmation if needed after first frame
    if (_needsInitialConfirmation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showInitialConfirmation();
      });
    }
  }
  
  Future<void> _showInitialConfirmation() async {
    if (!mounted || !_needsInitialConfirmation) return;
    _needsInitialConfirmation = false;
    
    final colors = context.appColors;
    final isDark = colors.isDark;
    
    final confirmed = await _showCommitConfirmation(colors, isDark);
    if (!mounted) return;
    
    if (!confirmed) {
      // User cancelled - close the dialog
      Navigator.pop(context, (
        result: FinaliseSaleResult.cancelled,
        emailData: null,
        paymentData: FinaliseSalePaymentData(paymentAmounts: Map.from(_paymentAmounts)),
      ));
    } else {
      // Show receipt step after confirmation
      setState(() {
        _currentStep = 3;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  double get _totalPaid =>
      _paymentAmounts.values.fold(0.0, (sum, amount) => sum + amount);

  double get _balanceOrChange => _totalPaid - widget.total;

  String _getCustomerDisplayName() {
    if (widget.customer == null) return 'No customer selected';

    final parts = <String>[];
    if (widget.customer!.givenNames.isNotEmpty) {
      parts.add(widget.customer!.givenNames);
    }
    if (widget.customer!.surname.isNotEmpty) {
      parts.add(widget.customer!.surname);
    }

    if (parts.isEmpty && widget.customer!.company.isNotEmpty) {
      return widget.customer!.company;
    }

    return parts.isEmpty ? widget.customer!.barcode : parts.join(' ');
  }

  void _showPaymentAmountDialog(String paymentMethod, AppThemeColors colors, bool isDark) {
    final existingAmount = _paymentAmounts[paymentMethod] ?? 0.0;
    // Auto-fill with remaining balance if no existing amount and balance is owed
    final prefillAmount = existingAmount > 0 
        ? existingAmount 
        : (_balanceOrChange < 0 ? _balanceOrChange.abs() : 0.0);
    final controller = TextEditingController(
      text: prefillAmount > 0 ? prefillAmount.toStringAsFixed(2) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
          ),
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2733) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$paymentMethod Amount",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (existingAmount > 0)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _paymentAmounts.remove(paymentMethod);
                          });
                          Navigator.of(dialogContext).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "Remove",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        scrollPhysics: const ClampingScrollPhysics(),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          prefixText: "\$ ",
                          prefixStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          hintText: "0.00",
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white30 : Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: isDark ? colors.surface : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (value) {
                          _applyPayment(paymentMethod, value);
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        _applyPayment(paymentMethod, controller.text);
                        Navigator.of(dialogContext).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF30B24C), Color(0xFF60D394)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // Ensure parent dialog rebuilds when bottom sheet is dismissed
      if (mounted) setState(() {});
    });
  }

  void _applyPayment(String paymentMethod, String value) {
    final amount = double.tryParse(value) ?? 0.0;
    setState(() {
      if (amount > 0) {
        _paymentAmounts[paymentMethod] = amount;
      } else {
        _paymentAmounts.remove(paymentMethod);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = context.isTablet;

    return Dialog(
      backgroundColor: _currentStep == 4 
          ? Colors.transparent
          : (isDark ? colors.surface : Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 40 : 20,
        vertical: isTablet ? 24 : 16,
      ),
      child: _currentStep == 4
          ? const SizedBox.shrink() // Minimal widget while showing confirmation
          : AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: isTablet ? 500 : MediaQuery.of(context).size.width * 0.95,
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              child: _currentStep == 0
                  ? _buildPaymentsStep(colors, isDark, isTablet)
                  : _currentStep == 1
                      ? _buildCommitOptions(colors, isDark, isTablet)
                      : _currentStep == 2
                          ? _buildEmailForm(colors, isDark, isTablet)
                          : _buildReceiptStep(colors, isDark, isTablet),
            ),
    );
  }

  Widget _buildPaymentsStep(AppThemeColors colors, bool isDark, bool isTablet) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.payment,
              color: kPrimaryColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Payment",
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Select payment method(s)",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 14 : 13,
              color: colors.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 20),

          // Total, Balance/Change display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? colors.surfaceAlt : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
              ),
          ),
          child: Column(
            children: [
              _buildAmountRow("Total", widget.total, isDark, isLarge: true),
              const SizedBox(height: 8),
              Divider(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
                height: 1,
              ),
              const SizedBox(height: 8),
              _buildAmountRow(
                _balanceOrChange >= 0 ? "Change" : "Balance",
                _balanceOrChange.abs(),
                isDark,
                isNegative: _balanceOrChange < 0,
                isPositive: _balanceOrChange > 0,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Payment Methods Grid
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _paymentMethods.map((method) {
            final hasAmount = _paymentAmounts.containsKey(method) && _paymentAmounts[method]! > 0;
            final amount = _paymentAmounts[method] ?? 0;
            return GestureDetector(
              onTap: () => _showPaymentAmountDialog(method, colors, isDark),
              onLongPress: hasAmount
                  ? () {
                      setState(() {
                        _paymentAmounts.remove(method);
                      });
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: hasAmount
                      ? kPrimaryColor
                      : (isDark ? colors.surfaceAlt : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasAmount
                        ? kPrimaryColor
                        : (isDark ? Colors.white24 : Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      method,
                      style: TextStyle(
                        color: hasAmount
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.blueGrey.shade700),
                        fontWeight: hasAmount ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    if (hasAmount) ...[
                      const SizedBox(width: 6),
                      Text(
                        FormattingUtils.formatCurrencyWithDecimals(amount, 0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Next/Commit Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              if (widget.promptForEmail) {
                setState(() => _currentStep = 1);
              } else {
                // Show confirmation dialog before proceeding
                final confirmed = await _showCommitConfirmation(colors, isDark);
                if (confirmed) {
                  // Skip email step, go to receipt
                  setState(() {
                    _finalResult = FinaliseSaleResult.save;
                    _finalEmailData = null;
                    _currentStep = 3;
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              widget.promptForEmail ? "Next" : "Commit",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Cancel
        TextButton(
          onPressed: () {
            Navigator.pop(context, (
              result: FinaliseSaleResult.cancelled,
              emailData: null,
              paymentData: FinaliseSalePaymentData(paymentAmounts: Map.from(_paymentAmounts)),
            ));
          },
          child: Text("Cancel", style: TextStyle(color: colors.onSurfaceMuted)),
        ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, bool isDark, {
    bool isLarge = false,
    bool isNegative = false,
    bool isPositive = false,
  }) {
    Color valueColor;
    if (isNegative) {
      valueColor = Colors.redAccent;
    } else if (isPositive) {
      valueColor = kPrimaryColor;
    } else {
      valueColor = isDark ? Colors.white : Colors.black87;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 16 : 14,
            fontWeight: isLarge ? FontWeight.bold : FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        Text(
          FormattingUtils.formatCurrencyWithDecimals(amount, 2),
          style: TextStyle(
            fontSize: isLarge ? 18 : 15,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCommitOptions(AppThemeColors colors, bool isDark, bool isTablet) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: kPrimaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline,
            color: kPrimaryColor,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Finalise Sale",
          style: TextStyle(
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "How would you like to complete this sale?",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isTablet ? 14 : 13,
            color: colors.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: 24),

        // Email Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() => _currentStep = 2);
            },
            icon: const Icon(Icons.email_outlined),
            label: const Text("Email & Commit"),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Save Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _finalResult = FinaliseSaleResult.save;
                _finalEmailData = null;
                _currentStep = 3;
              });
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text("Commit"),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white : Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Back and Cancel
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.showPayments) ...[
              TextButton(
                onPressed: () => setState(() => _currentStep = 0),
                child: Text("Back", style: TextStyle(color: colors.onSurfaceMuted)),
              ),
              const SizedBox(width: 16),
            ],
            TextButton(
              onPressed: () {
                Navigator.pop(context, (
                  result: FinaliseSaleResult.cancelled,
                  emailData: null,
                  paymentData: FinaliseSalePaymentData(paymentAmounts: Map.from(_paymentAmounts)),
                ));
              },
              child: Text("Cancel", style: TextStyle(color: colors.onSurfaceMuted)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailForm(AppThemeColors colors, bool isDark, bool isTablet) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button and Header
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _currentStep = 1),
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : Colors.black87,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Email Receipt",
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Email will be batched to process in RetailManager.",
          style: TextStyle(
            fontSize: isTablet ? 13 : 12,
            color: isDark ? Colors.white60 : Colors.black54,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),

        // Customer Info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? colors.surfaceAlt : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: kPrimaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getCustomerDisplayName(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (widget.customer?.barcode.isNotEmpty == true)
                      Text(
                        widget.customer!.barcode,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: colors.onSurfaceMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Email Label
        Text(
          "Email Address",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),

        // Email Input
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          scrollPhysics: const ClampingScrollPhysics(),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: "Enter email address",
            hintStyle: TextStyle(color: colors.onSurfaceMuted),
            prefixIcon: Icon(
              Icons.email_outlined,
              color: colors.onSurfaceMuted,
              size: 20,
            ),
            filled: true,
            fillColor: isDark ? colors.surfaceAlt : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kPrimaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Done Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final email = _emailController.text.trim();
              setState(() {
                _finalResult = FinaliseSaleResult.email;
                _finalEmailData = FinaliseSaleEmailData(email: email);
                _currentStep = 3;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Done",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Cancel
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              Navigator.pop(context, (
                result: FinaliseSaleResult.cancelled,
                emailData: null,
                paymentData: FinaliseSalePaymentData(paymentAmounts: Map.from(_paymentAmounts)),
              ));
            },
            child: Text(
              "Cancel",
              style: TextStyle(color: colors.onSurfaceMuted),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptStep(AppThemeColors colors, bool isDark, bool isTablet) {
    final change = _totalPaid - widget.total;
    
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: kPrimaryColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "${widget.title} Complete",
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 24),

          // Receipt summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? colors.surfaceAlt : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
              ),
            ),
            child: Column(
              children: [
                _buildReceiptRow("Total", widget.total, isDark),
                const SizedBox(height: 8),
                _buildReceiptRow("Amount Paid", _totalPaid, isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Change - prominent display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: kPrimaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  "Change",
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  FormattingUtils.formatCurrencyWithDecimals(
                    change > 0 ? change : 0.0,
                    2,
                  ),
                  style: TextStyle(
                    fontSize: isTablet ? 36 : 32,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // OK Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, (
                  result: _finalResult!,
                  emailData: _finalEmailData,
                  paymentData: FinaliseSalePaymentData(paymentAmounts: Map.from(_paymentAmounts)),
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "OK",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, double amount, bool isDark, {
    bool isLarge = false,
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 16 : 14,
            fontWeight: isLarge ? FontWeight.bold : FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        Text(
          FormattingUtils.formatCurrencyWithDecimals(amount, 2),
          style: TextStyle(
            fontSize: isLarge ? 18 : 15,
            fontWeight: FontWeight.bold,
            color: isHighlighted ? kPrimaryColor : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }
}
