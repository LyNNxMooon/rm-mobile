import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../constants/colors.dart';

class FilterChipRow extends StatelessWidget {
  final ValueChanged<String> onFilterChanged;
  final String selectedFilter;
  final bool isAscending;

  const FilterChipRow({
    super.key,
    required this.onFilterChanged,
    required this.selectedFilter,
    required this.isAscending,
  });

  final List<String> _filters = const [
    "Barcode",
    "Description",
    "Qty",
    "Custom1",
    "Cat1",
    "Cat2",
    "Cat3",
    "Custom2",
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final isSelected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () => onFilterChanged(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? kPrimaryColor : kSecondaryColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? kPrimaryColor : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      filter,
                      style: TextStyle(
                        color: isSelected
                            ? kSecondaryColor
                            : Colors.blueGrey[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      // Can pass 'isAscending' from parent to flip this icon
                      Icon(
                        isAscending
                            ? CupertinoIcons.sort_up
                            : CupertinoIcons.sort_down,
                        size: 14,
                        color: kSecondaryColor,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
