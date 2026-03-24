import 'package:flutter/material.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';

/// Delivery Details Screen for adding delivery information to a sale
class DeliveryDetailsScreen extends StatefulWidget {
  const DeliveryDetailsScreen({super.key});

  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _deliveryMethod = "Standard";
  DateTime? _deliveryDate;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppThemeColors(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Delivery Details"),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Information Section
            _buildSectionHeader("Contact Information", Icons.person_outline),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _nameController,
              label: "Recipient Name",
              hint: "Enter full name",
              icon: Icons.person_outline,
              isDark: isDark,
              colors: colors,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _phoneController,
              label: "Phone Number",
              hint: "Enter phone number",
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              isDark: isDark,
              colors: colors,
            ),

            const SizedBox(height: 24),

            // Delivery Address Section
            _buildSectionHeader("Delivery Address", Icons.location_on_outlined),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _addressController,
              label: "Street Address",
              hint: "Enter street address",
              icon: Icons.home_outlined,
              isDark: isDark,
              colors: colors,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _cityController,
                    label: "City",
                    hint: "City",
                    icon: Icons.location_city_outlined,
                    isDark: isDark,
                    colors: colors,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _postalCodeController,
                    label: "Postal Code",
                    hint: "Code",
                    icon: Icons.markunread_mailbox_outlined,
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                    colors: colors,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Delivery Method Section
            _buildSectionHeader(
                "Delivery Method", Icons.local_shipping_outlined),
            const SizedBox(height: 12),
            _buildDeliveryMethodSelector(isDark, colors),

            const SizedBox(height: 24),

            // Delivery Date Section
            _buildSectionHeader("Delivery Date", Icons.calendar_today_outlined),
            const SizedBox(height: 12),
            _buildDateSelector(isDark, colors),

            const SizedBox(height: 24),

            // Notes Section
            _buildSectionHeader("Delivery Notes", Icons.note_outlined),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _notesController,
              label: "Special Instructions",
              hint: "Any special delivery instructions...",
              icon: Icons.note_outlined,
              maxLines: 3,
              isDark: isDark,
              colors: colors,
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Save delivery details and go back
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Delivery details saved"),
                      backgroundColor: kPrimaryColor,
                    ),
                  );
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
                  "Save Delivery Details",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: kPrimaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    required AppThemeColors colors,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: colors.onSurfaceMuted),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E2733) : Colors.grey.shade100,
        labelStyle: TextStyle(color: colors.onSurfaceMuted, fontSize: 13),
        hintStyle: TextStyle(
            color: colors.onSurfaceMuted.withOpacity(0.6), fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDeliveryMethodSelector(bool isDark, AppThemeColors colors) {
    final methods = [
      {
        "name": "Standard",
        "icon": Icons.local_shipping_outlined,
        "time": "3-5 days",
        "price": "\$5.00"
      },
      {
        "name": "Express",
        "icon": Icons.rocket_launch_outlined,
        "time": "1-2 days",
        "price": "\$12.00"
      },
      {
        "name": "Pick Up",
        "icon": Icons.store_outlined,
        "time": "Same day",
        "price": "Free"
      },
    ];

    return Column(
      children: methods.map((method) {
        final isSelected = _deliveryMethod == method["name"];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () =>
                setState(() => _deliveryMethod = method["name"] as String),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2733) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? kPrimaryColor
                      : (isDark ? Colors.white24 : Colors.grey.shade300),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    method["icon"] as IconData,
                    color: isSelected ? kPrimaryColor : colors.onSurfaceMuted,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method["name"] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          method["time"] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    method["price"] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? kPrimaryColor
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isSelected ? kPrimaryColor : colors.onSurfaceMuted,
                        width: 2,
                      ),
                      color: isSelected ? kPrimaryColor : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateSelector(bool isDark, AppThemeColors colors) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate:
              _deliveryDate ?? DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 90)),
        );
        if (date != null) {
          setState(() => _deliveryDate = date);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2733) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: colors.onSurfaceMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _deliveryDate != null
                    ? "${_deliveryDate!.day}/${_deliveryDate!.month}/${_deliveryDate!.year}"
                    : "Select delivery date",
                style: TextStyle(
                  color: _deliveryDate != null
                      ? (isDark ? Colors.white : Colors.black87)
                      : colors.onSurfaceMuted,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: colors.onSurfaceMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
