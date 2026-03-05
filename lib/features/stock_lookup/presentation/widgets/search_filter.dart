import 'package:flutter/material.dart';
import '../../../../constants/colors.dart';

class SearchFilterBar extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onScannerTap;

  const SearchFilterBar({
    super.key,
    this.onChanged,
    this.onFilterTap,
    this.onScannerTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;

    return Row(
      children: [
        SizedBox(width: (isTablet ? 18 : 16) * uiScale),
        Expanded(
          child: TextField(
            onChanged: onChanged,
            decoration: const InputDecoration(
              hintText: 'Search by barcode, description, category...',
              hintStyle: TextStyle(color: kThirdColor, fontSize: 14),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.qr_code_scanner,
            color: kPrimaryColor,
            size: (isTablet ? 27 : 24) * uiScale,
          ),
          onPressed: onScannerTap,
        ),
        Container(
          height: (isTablet ? 30 : 26) * uiScale,
          width: 1,
          color: Colors.grey.withOpacity(0.3),
        ),
        IconButton(
          icon: Icon(
            Icons.tune_rounded,
            color: Colors.blueGrey.shade700,
            size: (isTablet ? 25 : 22) * uiScale,
          ),
          onPressed: onFilterTap,
        ),
        SizedBox(width: (isTablet ? 10 : 8) * uiScale),
      ],
    );
  }
}
