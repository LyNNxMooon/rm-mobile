import 'package:flutter/material.dart';


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
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    final Color baseColor = widget.bgColor;
    final Color strongColor = Color.lerp(baseColor, Colors.black, 0.15) ?? baseColor;

    return ElevatedButton.icon(
      onPressed: widget.function,
      style: ElevatedButton.styleFrom(
        backgroundColor: baseColor,
        foregroundColor: Colors.white,
        shadowColor: strongColor.withOpacity(0.15),
        minimumSize: const Size(100, 35),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 8 : 4,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      icon: Icon(widget.icon, size: isTablet ? 20 : 18, color: Colors.white),
      label: Text(
        widget.name,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: isTablet ? 15 : 13,
        ),
      ),
    );
  }
}
