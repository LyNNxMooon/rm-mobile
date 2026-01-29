import 'package:flutter/material.dart';
import 'package:rmstock_scanner/features/stocktake/presentation/screens/stocktake_history_screen.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';

import '../../../../constants/colors.dart';

class StocktakeSearchAndFilterBar extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  const StocktakeSearchAndFilterBar({
    super.key,
    this.onChanged,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: kSecondaryColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: kThirdColor.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText:
                      "Search barcode or description...", // Shortened hint
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                  filled: true,
                  fillColor: kSecondaryColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  isDense: true, // Compact
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.blue[700]!,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),
          Material(
            color: kSecondaryColor,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                context.navigateToNext(const StocktakeHistoryScreen());
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: Icon(
                  Icons.history,
                  color: Colors.blueGrey[800],
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
