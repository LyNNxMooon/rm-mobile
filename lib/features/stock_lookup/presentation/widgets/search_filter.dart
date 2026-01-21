import 'package:flutter/material.dart';
import '../../../../constants/colors.dart';

import '../../../../utils/log_utils.dart';

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
    return Row(
      children: [
        const SizedBox(width: 16),

        Expanded(
          child: TextField(
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: "Search by barcode, description, category…",
              hintStyle: TextStyle(color: kThirdColor, fontSize: 14),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),

        IconButton(
          icon: Icon(Icons.qr_code_scanner, color: kPrimaryColor, size: 24),
          onPressed: onScannerTap,
        ),

        Container(height: 26, width: 1, color: Colors.grey.withOpacity(0.3)),

        IconButton(
          icon: Icon(
            Icons.tune_rounded,
            color: Colors.blueGrey.shade700,
            size: 22,
          ),
          onPressed: onFilterTap,
        ),

        const SizedBox(width: 8),
      ],
    );
  }
}
