import 'package:flutter/material.dart';
import '../../../../entities/vos/customer_vo.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../utils/dialog_size_utils.dart';

/// Dialog for selecting from multiple matching customers
class DuplicateCustomerDialog extends StatelessWidget {
  final List<CustomerVO> matches;

  const DuplicateCustomerDialog({super.key, required this.matches});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final double maxDialogHeight = MediaQuery.of(context).size.height * 0.6;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isDark
            ? const BorderSide(color: Colors.white30, width: 1)
            : BorderSide.none,
      ),
      backgroundColor: isDark ? colors.surfaceAlt : kBgColor,
      elevation: 10,
      insetPadding: dialogInsetPadding(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.people_outline,
                        color: kPrimaryColor,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Multiple Customers Found",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? colors.onSurface : kThirdColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Please select a customer:",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? colors.onSurfaceMuted : kGreyColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            Flexible(
              child: Container(
                constraints: BoxConstraints(maxHeight: maxDialogHeight),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  shrinkWrap: true,
                  itemCount: matches.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    return _buildCustomerItem(context, matches[i]);
                  },
                ),
              ),
            ),

            const SizedBox(height: 15),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: colors.onHero,
                    minimumSize: const Size(double.infinity, 50),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Cancel",
                      textScaler: TextScaler.noScaling,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerItem(BuildContext context, CustomerVO c) {
    final colors = context.appColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Build display name
    final String displayName = _buildDisplayName(c);
    
    return InkWell(
      onTap: () => Navigator.pop(context, c),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? colors.surfaceAlt : kSecondaryColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white24
                : kPrimaryColor.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? colors.cardShadow
                  : kThirdColor.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getInitials(c),
                  style: const TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? colors.onSurface : kThirdColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Company (if exists)
                  if (c.company.isNotEmpty)
                    Text(
                      c.company,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? colors.onSurfaceMuted : Colors.grey.shade600,
                      ),
                    ),
                  
                  const SizedBox(height: 6),
                  
                  // Details Row: Barcode, Phone, Email
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      // Barcode
                      _buildDetailChip(
                        context,
                        c.barcode,
                        isDark,
                        colors,
                        isMonospace: true,
                      ),
                      
                      // Phone or Mobile
                      if (c.phone.isNotEmpty || c.mobile.isNotEmpty)
                        _buildDetailChip(
                          context,
                          c.mobile.isNotEmpty ? c.mobile : c.phone,
                          isDark,
                          colors,
                          icon: Icons.phone_outlined,
                        ),
                      
                      // Email
                      if (c.email.isNotEmpty)
                        _buildDetailChip(
                          context,
                          c.email,
                          isDark,
                          colors,
                          icon: Icons.email_outlined,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Arrow indicator
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(
    BuildContext context,
    String text, 
    bool isDark, 
    AppThemeColors colors, {
    IconData? icon,
    bool isMonospace = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? colors.surface : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 12,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontFamily: isMonospace ? 'monospace' : null,
                fontWeight: isMonospace ? FontWeight.w600 : FontWeight.normal,
                color: isMonospace 
                    ? kPrimaryColor 
                    : (isDark ? Colors.white70 : Colors.grey.shade700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildDisplayName(CustomerVO c) {
    final parts = <String>[];
    if (c.givenNames.isNotEmpty) parts.add(c.givenNames);
    if (c.surname.isNotEmpty) parts.add(c.surname);
    
    if (parts.isEmpty && c.company.isNotEmpty) {
      return c.company;
    }
    
    return parts.isEmpty ? "Unknown Customer" : parts.join(' ');
  }

  String _getInitials(CustomerVO c) {
    String initials = '';
    
    if (c.givenNames.isNotEmpty) {
      initials += c.givenNames[0].toUpperCase();
    }
    if (c.surname.isNotEmpty) {
      initials += c.surname[0].toUpperCase();
    }
    
    if (initials.isEmpty && c.company.isNotEmpty) {
      initials = c.company[0].toUpperCase();
    }
    
    return initials.isEmpty ? '?' : initials;
  }
}
