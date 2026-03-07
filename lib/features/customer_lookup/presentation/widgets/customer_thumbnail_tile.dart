import 'package:flutter/material.dart';
import 'package:rmstock_scanner/entities/vos/customer_vo.dart';

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
    final String initials = _getInitials(customer.givenNames);
    final double fontSize = (size * 0.47).clamp(14.0, 32.0);
    return Container(
      alignment: Alignment.center,
      color: Colors.transparent,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Subtle vertical gradient matching the provided image reference
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[400]!, // Slightly lighter grey at the top
              Colors.grey[500]!, // Slightly darker grey at the bottom
            ],
          ),
          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white, // White text color as requested
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
