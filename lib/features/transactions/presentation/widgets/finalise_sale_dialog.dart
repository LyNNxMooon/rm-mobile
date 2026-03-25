import 'package:flutter/material.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../entities/vos/customer_vo.dart';

/// Result from finalise sale dialog
enum FinaliseSaleResult { email, save, cancelled }

/// Data returned when email option is selected
class FinaliseSaleEmailData {
  final String email;

  FinaliseSaleEmailData({required this.email});
}

/// Dialog for finalising a sale - offers Email or Save options
class FinaliseSaleDialog extends StatefulWidget {
  final CustomerVO? customer;

  const FinaliseSaleDialog({super.key, this.customer});

  /// Shows the dialog and returns the result
  static Future<
    ({FinaliseSaleResult result, FinaliseSaleEmailData? emailData})?
  >
  show({required BuildContext context, CustomerVO? customer}) {
    return showDialog<
      ({FinaliseSaleResult result, FinaliseSaleEmailData? emailData})
    >(
      context: context,
      barrierDismissible: true,
      builder: (_) => FinaliseSaleDialog(customer: customer),
    );
  }

  @override
  State<FinaliseSaleDialog> createState() => _FinaliseSaleDialogState();
}

class _FinaliseSaleDialogState extends State<FinaliseSaleDialog> {
  bool _showEmailForm = false;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.customer?.email ?? '',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return Dialog(
      backgroundColor: isDark ? colors.surface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: isTablet ? 400 : MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(24),
        child: _showEmailForm
            ? _buildEmailForm(colors, isDark, isTablet)
            : _buildInitialOptions(colors, isDark, isTablet),
      ),
    );
  }

  Widget _buildInitialOptions(
    AppThemeColors colors,
    bool isDark,
    bool isTablet,
  ) {
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
              setState(() => _showEmailForm = true);
            },
            icon: const Icon(Icons.email_outlined),
            label: const Text("Email Receipt"),
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
              Navigator.pop(context, (
                result: FinaliseSaleResult.save,
                emailData: null,
              ));
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text("Save Only"),
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

        // Cancel
        TextButton(
          onPressed: () {
            Navigator.pop(context, (
              result: FinaliseSaleResult.cancelled,
              emailData: null,
            ));
          },
          child: Text("Cancel", style: TextStyle(color: colors.onSurfaceMuted)),
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
              onPressed: () => setState(() => _showEmailForm = false),
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
        const SizedBox(height: 20),

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
              Navigator.pop(context, (
                result: FinaliseSaleResult.email,
                emailData: FinaliseSaleEmailData(email: email),
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
}
