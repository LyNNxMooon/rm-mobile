import 'package:flutter/material.dart';

import '../../../../../constants/colors.dart';
import '../../../../../constants/theme_colors.dart';

/// Tax breakdown widget showing Ex Tax, Tax Amount, Inc Tax
class TaxBreakdownWidget extends StatelessWidget {
  final double total;
  final AppThemeColors colors;
  final bool isDark;
  final double taxRate;

  const TaxBreakdownWidget({
    super.key,
    required this.total,
    required this.colors,
    required this.isDark,
    this.taxRate = 0.10, // Default 10% GST
  });

  @override
  Widget build(BuildContext context) {
    final double incTaxTotal = total;
    final double exTaxTotal = total / (1 + taxRate);
    final double taxAmount = incTaxTotal - exTaxTotal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2733) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTaxRow("Ex:", exTaxTotal, highlight: false),
          const SizedBox(height: 4),
          _buildTaxRow("Tax:", taxAmount, highlight: true),
          const SizedBox(height: 4),
          _buildTaxRow("Inc:", incTaxTotal, highlight: false),
        ],
      ),
    );
  }

  Widget _buildTaxRow(String label, double amount, {bool highlight = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: highlight
                ? kPrimaryColor
                : (isDark ? Colors.white70 : Colors.blueGrey.shade700),
            fontSize: 12,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          "\$${amount.toStringAsFixed(2)}",
          style: TextStyle(
            color: highlight
                ? kPrimaryColor
                : (isDark ? Colors.white : Colors.black87),
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Profit breakdown widget showing Cost, eGP, eGP%
class ProfitBreakdownWidget extends StatelessWidget {
  final double subtotal;
  final double discount;
  final AppThemeColors colors;
  final bool isDark;
  final double costRatio;

  const ProfitBreakdownWidget({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.colors,
    required this.isDark,
    this.costRatio = 0.6, // Default: cost is 60% of sell price
  });

  @override
  Widget build(BuildContext context) {
    final double totalCost = subtotal * costRatio;
    final double egp = subtotal - totalCost - discount;
    final double egpPercent = subtotal > 0 ? (egp / subtotal) * 100 : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2733) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfitRow("Cost:", totalCost, highlight: false),
          const SizedBox(height: 4),
          _buildProfitRow("eGP:", egp, highlight: true),
          const SizedBox(height: 4),
          _buildPercentRow("eGP%:", egpPercent, highlight: true),
        ],
      ),
    );
  }

  Widget _buildProfitRow(String label, double amount, {bool highlight = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: highlight
                ? const Color(0xFF30B24C)
                : (isDark ? Colors.white70 : Colors.blueGrey.shade700),
            fontSize: 12,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          "\$${amount.toStringAsFixed(2)}",
          style: TextStyle(
            color: highlight
                ? const Color(0xFF30B24C)
                : (isDark ? Colors.white : Colors.black87),
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPercentRow(String label, double percent, {bool highlight = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: highlight
                ? const Color(0xFF30B24C)
                : (isDark ? Colors.white70 : Colors.blueGrey.shade700),
            fontSize: 12,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          "${percent.toStringAsFixed(1)}%",
          style: TextStyle(
            color: highlight
                ? const Color(0xFF30B24C)
                : (isDark ? Colors.white : Colors.black87),
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Change/Remain amount display widget
class ChangeRemainWidget extends StatelessWidget {
  final double total;
  final double totalPaid;

  const ChangeRemainWidget({
    super.key,
    required this.total,
    required this.totalPaid,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPaid > total) {
      return Text(
        "Change: \$${(totalPaid - total).toStringAsFixed(2)}",
        style: const TextStyle(
          color: Color(0xFF30B24C),
          fontWeight: FontWeight.bold,
          fontSize: 12.5,
        ),
      );
    } else if (totalPaid > 0 && totalPaid < total) {
      return Text(
        "Remain: \$${(total - totalPaid).toStringAsFixed(2)}",
        style: const TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.bold,
          fontSize: 12.5,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
