import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../constants/colors.dart';

class CustomerFilterChipRow extends StatelessWidget {
  final ValueChanged<String> onFilterChanged;
  final String selectedFilter;
  final bool isAscending;

  const CustomerFilterChipRow({
    super.key,
    required this.onFilterChanged,
    required this.selectedFilter,
    required this.isAscending,
  });

  final List<String> _filters = const [
    'Surname',
    'Company',
    'Email',
    'Phone',
    'Suburb',
    'State',
  ];

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double uiScale = isTablet
        ? (1.0 + ((textScale - 1.0) * 0.35)).clamp(1.0, 1.2)
        : 1.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final isSelected = selectedFilter == filter;
          return Padding(
            padding: EdgeInsets.only(right: isTablet ? 8.0 : 6.0),
            child: InkWell(
              onTap: () => onFilterChanged(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: (isTablet ? 10 : 7) * uiScale,
                  vertical: (isTablet ? 8 : 5) * uiScale,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? kPrimaryColor : kSecondaryColor,
                  borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
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
                      SizedBox(width: isTablet ? 6 : 4),
                      Icon(
                        isAscending
                            ? CupertinoIcons.sort_up
                            : CupertinoIcons.sort_down,
                        size: (isTablet ? 16 : 14) * uiScale,
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
