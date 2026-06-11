import 'package:flutter/material.dart';
import 'package:rmmobile/entities/vos/customer_vo.dart';
//import 'package:rmmobile/constants/colors.dart';
import 'package:rmmobile/constants/theme_colors.dart';

//import '../../../../constants/colors.dart';

class CustomerThumbnailTile extends StatelessWidget {
  final CustomerVO customer;
  final double size;

  const CustomerThumbnailTile({
    super.key,
    required this.customer,
    this.size = 34,
  });

  String _getInitials(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return "";

    List<String> nameParts = trimmedName.split(RegExp(r'\s+'));

    if (nameParts.length == 1) {
      // Handle single names gracefully (e.g., "Madonna" -> "MA")
      String word = nameParts[0];
      if (word.length >= 2) {
        return word.substring(0, 2).toUpperCase();
      } else {
        // Fallback if the name is literally just 1 character long
        return word.toUpperCase();
      }
    } else {
      // Multiple words (e.g., "John Doe" -> "JD", "John H. Doe" -> "JD")
      String firstLetter = nameParts.first[0];
      String lastLetter = nameParts.last[0];
      return (firstLetter + lastLetter).toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = colors.isDark;
    final double shortestSide = MediaQuery.of(context).size.shortestSide;
    final bool isTablet = shortestSide >= 600;
    //final bool isLargeTablet = shortestSide >= 900;
    final String nameForInitials =
      "${customer.givenNames} ${customer.surname}".trim();
    final String initials =
      _getInitials(nameForInitials.isEmpty ? customer.displayName : nameForInitials);
    final double fontSize = isTablet ? 12.5 : (size * 0.4).clamp(10.5, 26.0);
    return Container(
      alignment: Alignment.center,
      color: Colors.transparent,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Faint fill that adapts to theme
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.25)
                : Colors.black.withOpacity(0.18),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: fontSize,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
