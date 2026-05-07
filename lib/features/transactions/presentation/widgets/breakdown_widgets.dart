import 'package:flutter/material.dart';

import '../../../../constants/colors.dart';
import '../../../../constants/theme_colors.dart';
import '../../../../utils/formatting_utils.dart';
import '../../../../utils/responsive_utils.dart';

/// Tax breakdown widget showing Ex Tax, Tax Amount, Inc Tax
class TaxBreakdownWidget extends StatelessWidget {
  final double? total; // Legacy: used with taxRate
  final double? exTotal; // Pre-calculated Ex total
  final double? incTotal; // Pre-calculated Inc total
  final double? taxAmount; // Pre-calculated tax amount
  final AppThemeColors colors;
  final bool isDark;
  final double taxRate;

  const TaxBreakdownWidget({
    super.key,
    this.total,
    this.exTotal,
    this.incTotal,
    this.taxAmount,
    required this.colors,
    required this.isDark,
    this.taxRate = 0.10, // Default 10% GST (legacy fallback)
  });

  @override
  Widget build(BuildContext context) {
    // Use pre-calculated values if provided, otherwise fall back to legacy calculation
    final double displayIncTotal = incTotal ?? total ?? 0.0;
    final double displayExTotal = exTotal ?? (total != null ? total! / (1 + taxRate) : 0.0);
    final double displayTaxAmount = taxAmount ?? (displayIncTotal - displayExTotal);
    final bool isTablet = context.isTablet;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 20,
        vertical: isTablet ? 20 : 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2733) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTaxRow("Ex Tax:", displayExTotal, highlight: false, isTablet: isTablet),
          SizedBox(height: isTablet ? 14 : 12),
          _buildTaxRow("Tax Amount:", displayTaxAmount, highlight: true, isTablet: isTablet),
          SizedBox(height: isTablet ? 14 : 12),
          _buildTaxRow(
            "Inc Tax:",
            displayIncTotal,
            highlight: false,
            isTablet: isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildTaxRow(
    String label,
    double amount, {
    bool highlight = false,
    bool isTablet = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: highlight
                ? kPrimaryColor
                : (isDark ? Colors.white70 : Colors.blueGrey.shade700),
            fontSize: isTablet ? 18 : 16,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        SizedBox(width: isTablet ? 24 : 16),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(
              FormattingUtils.formatCurrencyWithDecimals(amount, 4),
              style: TextStyle(
                color: highlight
                    ? kPrimaryColor
                    : (isDark ? Colors.white : Colors.black87),
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Profit breakdown widget showing Cost, eGP, eGP%
class ProfitBreakdownWidget extends StatelessWidget {
  final double totalEx;
  final double totalCost;
  final double? totalGp; // Optional: if provided, use directly instead of calculating
  final AppThemeColors colors;
  final bool isDark;

  const ProfitBreakdownWidget({
    super.key,
    required this.totalEx,
    required this.totalCost,
    this.totalGp,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Use provided totalGp or calculate from totalEx - totalCost
    final double egp = totalGp ?? (totalEx - totalCost);
    final double egpPercent = totalEx > 0 ? (egp / totalEx) * 100 : 0;
    final bool isLoss = egp < 0;
    final bool isTablet = context.isTablet;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 20,
        vertical: isTablet ? 20 : 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2733) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProfitRow(
            "Total Cost:",
            totalCost,
            highlight: false,
            isTablet: isTablet,
          ),
          SizedBox(height: isTablet ? 14 : 12),
          _buildProfitRow("Est. Gross Profit:", egp, highlight: true, isTablet: isTablet, isLoss: isLoss),
          SizedBox(height: isTablet ? 14 : 12),
          _buildPercentRow(
            "Est. GP %:",
            egpPercent,
            highlight: true,
            isTablet: isTablet,
            isLoss: isLoss,
          ),
        ],
      ),
    );
  }

  Widget _buildProfitRow(
    String label,
    double amount, {
    bool highlight = false,
    bool isTablet = false,
    bool isLoss = false,
  }) {
    final Color highlightColor = isLoss ? Colors.red : const Color(0xFF30B24C);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: highlight
                ? highlightColor
                : (isDark ? Colors.white70 : Colors.blueGrey.shade700),
            fontSize: isTablet ? 18 : 16,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        SizedBox(width: isTablet ? 24 : 16),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(
              FormattingUtils.formatCurrencyWithDecimals(amount, 4),
              style: TextStyle(
                color: highlight
                    ? highlightColor
                    : (isDark ? Colors.white : Colors.black87),
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPercentRow(
    String label,
    double percent, {
    bool highlight = false,
    bool isTablet = false,
    bool isLoss = false,
  }) {
    final Color highlightColor = isLoss ? Colors.red : const Color(0xFF30B24C);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: highlight
                ? highlightColor
                : (isDark ? Colors.white70 : Colors.blueGrey.shade700),
            fontSize: isTablet ? 18 : 16,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        SizedBox(width: isTablet ? 24 : 16),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(
              "${percent.toStringAsFixed(2)}%",
              style: TextStyle(
                color: highlight
                    ? highlightColor
                    : (isDark ? Colors.white : Colors.black87),
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
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
        "Change: ${FormattingUtils.formatCurrencyWithDecimals(totalPaid - total, 2)}",
        style: const TextStyle(
          color: Color(0xFF30B24C),
          fontWeight: FontWeight.bold,
          fontSize: 12.5,
        ),
      );
    } else if (totalPaid > 0 && totalPaid < total) {
      return Text(
        "Remain: ${FormattingUtils.formatCurrencyWithDecimals(total - totalPaid, 2)}",
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
