import 'package:flutter/material.dart';
import 'package:rmstock_scanner/constants/colors.dart';
import '../../../../constants/theme_colors.dart';

class CustomStocktakeBtn extends StatefulWidget {
  const CustomStocktakeBtn({
    super.key,
    required this.function,
    required this.bgColor,
    required this.name,
    required this.icon,
  });

  final void Function()? function;
  final Color bgColor;
  final String name;
  final IconData icon;

  @override
  State<CustomStocktakeBtn> createState() => _CustomStocktakeBtnState();
}

class _CustomStocktakeBtnState extends State<CustomStocktakeBtn> {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ElevatedButton.icon(
      onPressed: widget.function,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.bgColor,
        foregroundColor: isDark ? colors.onHero : kSecondaryColor,
        minimumSize: const Size(100, 35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      icon: Icon(widget.icon, size: 18),
      label: Text(widget.name, style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
